# frozen_string_literal: true

module Tetra
  # attempts to get java projects' pom file
  class PomGetter
    include Logging

    # saves a jar poms in <jar_filename>.pom
    # returns filename and status if found, else nil
    def get_pom(filename)
      content, status = get_pom_from_jar(filename) ||
                        get_pom_from_sha1(filename) ||
                        get_pom_from_heuristic(filename)
      return unless content

      pom_filename = filename.sub(/(\.jar)?$/, ".pom")
      File.binwrite(pom_filename, content)
      [pom_filename, status]
    end

    # returns a pom embedded in a jar file
    def get_pom_from_jar(file)
      log.debug("Attempting unpack of #{file} to find a POM")
      begin
        Zip::File.foreach(file) do |entry|
          # Security check (Zip Slip)
          next if entry.name.include?("..") || entry.name.start_with?("/")

          # PERFORMANCE: end_with? is much faster than Regexp for simple suffixes
          if entry.name.end_with?("/pom.xml") || entry.name == "pom.xml"
            log.info("pom.xml found in #{file}##{entry.name}")
            return entry.get_input_stream.read, :found_in_jar
          end
        end
      rescue Zip::Error
        log.warn("#{file} does not seem to be a valid jar archive, skipping")
      rescue TypeError
        log.warn("#{file} seems to be a valid jar archive but is corrupt, skipping")
      end
      nil
    end

    # returns a pom from search.maven.org with a jar sha1 search
    def get_pom_from_sha1(file)
      log.debug("Attempting SHA1 POM lookup for #{file}")
      return unless File.file?(file)

      begin
        site = MavenWebsite.new
        # PERFORMANCE: Streams the file calculation instead of loading entire file into RAM
        sha1 = Digest::SHA1.file(file).hexdigest

        results = site.search_by_sha1(sha1)
        found_doc = results.find { |doc| doc["ec"].include?(".pom") }

        if found_doc
          log.info("pom.xml for #{file} found on search.maven.org for sha1 #{sha1} " \
                   "(#{found_doc['g']}:#{found_doc['a']}:#{found_doc['v']})")

          group_id, artifact_id, version = site.get_maven_id_from(found_doc)
          return site.download_pom(group_id, artifact_id, version), :found_via_sha1
        end
      rescue NotFoundOnMavenWebsiteError
        log.warn("Got a 404 error while looking for #{file}'s SHA1 in search.maven.org")
      end
      nil
    end

    # returns a pom from search.maven.org with a heuristic name search
    def get_pom_from_heuristic(filename)
      log.debug("Attempting heuristic POM search for #{filename}")
      begin
        site = MavenWebsite.new
        clean_name = cleanup_name(filename)

        version_matcher = VersionMatcher.new
        my_artifact_id, my_version = version_matcher.split_version(clean_name)
        log.debug("Guessed artifact id: #{my_artifact_id}, version: #{my_version}")

        first_result = site.search_by_name(my_artifact_id).first
        log.debug("Artifact id search result: #{first_result}")

        return unless first_result

        group_id, artifact_id, = site.get_maven_id_from(first_result)
        results = site.search_by_group_id_and_artifact_id(group_id, artifact_id)
        log.debug("All versions: #{results}")

        their_versions = results.map { |doc| doc["v"] }

        best_matched_version = if my_version
                                 version_matcher.best_match(my_version, their_versions)
                               else
                                 their_versions.max
                               end

        best_matched_doc = results.find { |r| r["v"] == best_matched_version }
        return unless best_matched_doc

        group_id, artifact_id, version = site.get_maven_id_from(best_matched_doc)
        log.warn("pom.xml for #{filename} found on search.maven.org with heuristic search " \
                 "(#{group_id}:#{artifact_id}:#{version})")

        return site.download_pom(group_id, artifact_id, version), :found_via_heuristic
      rescue NotFoundOnMavenWebsiteError
        log.warn("Got a 404 error while looking for #{filename} heuristically in search.maven.org")
      end
      nil
    end

    # get a heuristic name from a path
    def cleanup_name(path)
      Pathname.new(path).basename.to_s.sub(/\.jar$/, "")
    end
  end
end
