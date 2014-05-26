# encoding: UTF-8

require "digest/sha1"
require "zip"
require "rest_client"
require "json"
require "pathname"

require "gjp/version_matcher"

module Gjp
  # attempts to get java projects' pom file
  class PomGetter
    include Logging

    # saves a jar poms in <jar_filename>.pom
    # returns filename and status if found, else nil
    def get_pom(filename)
      content, status = (get_pom_from_jar(filename) || get_pom_from_sha1(filename) || get_pom_from_heuristic(filename))
      if content
        pom_filename = filename.sub(/(\.jar)?$/, ".pom")
        File.open(pom_filename, "w") { |io| io.write(content) }
        [pom_filename, status]
      end
    end

    # returns a pom embedded in a jar file
    def get_pom_from_jar(file)
      log.debug("Attempting unpack of #{file} to find a POM")
      begin
        Zip::File.foreach(file) do |entry|
          if entry.name =~ /\/pom.xml$/
            log.info("pom.xml found in #{file}##{entry.name}")
            return entry.get_input_stream.read, :found_in_jar
          end
        end
      rescue Zip::Error
        log.warn("#{file} does not seem to be a valid jar archive, skipping")
      rescue TypeError
        log.warn("#{file} seems to be a valid jar archive but is corrupt, skipping")
      end
      return nil
    end
    
    # returns a pom from search.maven.org with a jar sha1 search
    def get_pom_from_sha1(file)
      log.debug("Attempting SHA1 POM lookup for #{file}")
      begin
        if File.file?(file)
          site = MavenWebsite.new
          sha1 = Digest::SHA1.hexdigest File.read(file)
          results = site.search_by_sha1(sha1).select {|result| result["ec"].include?(".pom")}
          result = results.first    
          if result != nil
            log.info("pom.xml for #{file} found on search.maven.org for sha1 #{sha1}\
              (#{result["g"]}:#{result["a"]}:#{result["v"]})"
            )
            group_id, artifact_id, version = site.get_maven_id_from result
            return site.download_pom(group_id, artifact_id, version), :found_via_sha1
          end
        end
      rescue RestClient::ResourceNotFound
        log.warn("Got a 404 error while looking for #{file}'s SHA1 in search.maven.org")
      end
      nil
    end

    # returns a pom from search.maven.org with a heuristic name search
    def get_pom_from_heuristic(filename)
      begin
        log.debug("Attempting heuristic POM search for #{filename}")
        site = MavenWebsite.new
        filename = cleanup_name(filename)
        version_matcher = VersionMatcher.new
        my_artifact_id, my_version = version_matcher.split_version(filename)
        log.debug("Guessed artifact id: #{my_artifact_id}, version: #{my_version}")

        result = site.search_by_name(my_artifact_id).first
        log.debug("Artifact id search result: #{result}")
        if result != nil
          group_id, artifact_id, version = site.get_maven_id_from result
          results = site.search_by_group_id_and_artifact_id(group_id, artifact_id)
          log.debug("All versions: #{results}")
          their_versions = results.map {|doc| doc["v"]}
          best_matched_version = if my_version != nil
            version_matcher.best_match(my_version, their_versions)
          else
            their_versions.max
          end
          best_matched_result = (results.select{|result| result["v"] == best_matched_version}).first
            
          group_id, artifact_id, version = site.get_maven_id_from(best_matched_result)
          log.warn("pom.xml for #{filename} found on search.maven.org with heuristic search\
            (#{group_id}:#{artifact_id}:#{version})"
          )
            
          return site.download_pom(group_id, artifact_id, version), :found_via_heuristic
        end
      rescue RestClient::ResourceNotFound
        log.warn("Got a 404 error while looking for #{filename} heuristically in search.maven.org")
      end
      nil
    end

    # get a heuristic name from a path
    def cleanup_name(path)
      Pathname.new(path).basename.to_s.sub(/.jar$/, "")
    end
  end
end
