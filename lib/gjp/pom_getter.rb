# encoding: UTF-8

require "digest/sha1"
require "zip/zip"
require "rest_client"
require "json"
require "pathname"

require "gjp/version_matcher"

module Gjp
  # attempts to get java projects' pom file
  class PomGetter
    include Logger

    # saves a jar poms in <jar_filename>.pom
    # returns filename and status if found, else nil
    def get_pom(filename)
      content, status = (get_pom_from_jar(filename) or get_pom_from_sha1(filename) or get_pom_from_heuristic(filename))
      if content
        pom_filename = filename.sub(/(\.jar)?$/, ".pom")
        File.open(pom_filename, "w") { |io| io.write(content) }
        [pom_filename, status]
      end
    end

    # returns a pom embedded in a jar file
    def get_pom_from_jar(file)
      begin
        Zip::ZipFile.foreach(file) do |entry|
          if entry.name =~ /\/pom.xml$/
            log.info("pom.xml found in #{file}##{entry.name}")
            return entry.get_input_stream.read, :found_in_jar
          end
        end
      rescue Zip::ZipError
        log.warn("#{file} does not seem to be a valid jar archive, skipping")
      rescue TypeError
        log.warn("#{file} seems to be a valid jar archive but is corrupt, skipping")
      end
      return nil
    end
    
    # returns a pom from search.maven.org with a jar sha1 search
    def get_pom_from_sha1(file)
      begin
        if File.file?(file)
          site = MavenWebsite.new
          sha1 = Digest::SHA1.hexdigest File.read(file)
          results = site.search_by_sha1(sha1).select {|result| result["ec"].include?(".pom")}
          result = results.first    
          if result != nil
            log.info("pom.xml for #{file} found on search.maven.org for sha1 #{sha1} (#{result["g"]}:#{result["a"]}:#{result["v"]})")
            group_id, artifact_id, version = site.get_maven_id_from result
            return site.download_pom(group_id, artifact_id, version), :found_via_sha1
          end
        end
        return nil
      rescue RestClient::ResourceNotFound
        log.error("Got an error while looking for #{file}'s SHA1 in search.maven.org")
      end
    end

    # returns a pom from search.maven.org with a heuristic name search
    def get_pom_from_heuristic(filename)
      begin
        site = MavenWebsite.new
        filename = cleanup_name(filename)
        version_matcher = VersionMatcher.new
        my_artifact_id, my_version = version_matcher.split_version(filename)

        result = site.search_by_name(my_artifact_id).first
        if result != nil
          group_id, artifact_id, version = site.get_maven_id_from result
          results = site.search_by_group_id_and_artifact_id(group_id, artifact_id)
          their_versions = results.map {|doc| doc["v"]}
          best_matched_version = if my_version != nil then version_matcher.best_match(my_version, their_versions) else their_versions.max end
          best_matched_result = (results.select{|result| result["v"] == best_matched_version}).first
            
          group_id, artifact_id, version = site.get_maven_id_from(best_matched_result)
          log.warn("pom.xml for #{filename} found on search.maven.org with heuristic search (#{group_id}:#{artifact_id}:#{version})")
            
          return site.download_pom(group_id, artifact_id, version), :found_via_heuristic
        end
      rescue RestClient::ResourceNotFound
        log.error("Got an error while looking for #{filename}'s SHA1 in search.maven.org")
      end
    end

    # get a heuristic name from a path
    def cleanup_name(path)
      Pathname.new(path).basename.to_s.sub(/.jar$/, "")
    end
  end
end
