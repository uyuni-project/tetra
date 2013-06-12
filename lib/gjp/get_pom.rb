# encoding: UTF-8

require "digest/sha1"
require "zip/zip"
require "rest_client"
require "json"
require "pathname"

require "gjp/version_matcher"

module Gjp
  # implements the get-pom subcommand
  class PomGetter

    def self.log
      Gjp.logger
    end

    # returns the pom corresponding to a filename
    def self.get_pom(filename)
      (get_pom_from_dir(filename) or get_pom_from_jar(filename) or get_pom_from_sha1(filename) or get_pom_from_heuristic(filename))
    end

    # returns the pom in a project directory
    def self.get_pom_from_dir(dir)
      if File.directory?(dir)
        pom_path = File.join(dir, "pom.xml")
        if File.file?(pom_path)
          log.info("pom.xml found in #{dir}/pom.xml")
          return File.read(pom_path)
        end
      end
    end
    
    # returns a pom embedded in a jar file
    def self.get_pom_from_jar(file)
      begin
        Zip::ZipFile.foreach(file) do |entry|
          if entry.name =~ /\/pom.xml$/
            log.info("pom.xml found in #{file}##{entry.name}")
            return entry.get_input_stream.read
          end
        end
      rescue Zip::ZipError
        log.info "#{file} does not seem to be a valid jar archive, skipping"
      rescue TypeError
        log.info "#{file} seems to be a valid jar archive but is corrupt, skipping"
      end
      return nil
    end
    
    # returns a pom from search.maven.org with a jar sha1 search
    def self.get_pom_from_sha1(file)
      begin
        if File.file?(file)
          sha1 = Digest::SHA1.hexdigest File.read(file)
          results = repository_search({:q => "1:\"#{sha1}\""}).select {|result| result["ec"].include?(".pom")}
          result = results.first    
          if result != nil
            log.info("pom.xml for #{file} found on search.maven.org for sha1 #{sha1} (#{result["g"]}:#{result["a"]}:#{result["v"]})")
            return repository_download(result)
          end
        end
        return nil
      rescue RestClient::ResourceNotFound
        $stderr.puts "Got an error while looking for #{file}'s SHA1 in search.maven.org" 
      end
    end

    # returns a pom from search.maven.org with a heuristic name search
    def self.get_pom_from_heuristic(filename)
      begin
        filename = Pathname.new(filename).basename.to_s.sub(/.jar$/, "")
        my_artifact_id, my_version = VersionMatcher.split_version(filename)

        result = repository_search({:q => my_artifact_id}).first
        if result != nil
          results = repository_search({:q => "g:\"#{result["g"]}\" AND a:\"#{result["a"]}\"", :core => "gav"})
          their_versions = results.map {|doc| doc["v"]}
          best_matched_version = if my_version != nil then VersionMatcher.best_match(my_version, their_versions) else their_versions.max end
          best_matched_result = (results.select{|result| result["v"] == best_matched_version}).first
            
          log.warn("pom.xml for #{filename} found on search.maven.org with heuristic search (#{best_matched_result["g"]}:#{best_matched_result["a"]}:#{best_matched_result["v"]})")
            
          return repository_download(best_matched_result)
        end
      rescue RestClient::ResourceNotFound
        $stderr.puts "Got an error while looking for #{filename} in search.maven.org" 
      end
    end
    
    # returns a JSON result from search.maven.com
    def self.repository_search(params)
        response = RestClient.get "http://search.maven.org/solrsearch/select", {:params => params.merge({"rows" => "100", "wt" => "json"})}
        json = JSON.parse(response.to_s)
        return json["response"]["docs"]
    end
    
    # downloads a POM from a search.maven.com search result
    def self.repository_download(result)
      if result != nil
        path = "#{result["g"].gsub(".", "/")}/#{result["a"]}/#{result["v"]}/#{result["a"]}-#{result["v"]}.pom"
        return (RestClient.get "http://search.maven.org/remotecontent", {:params => {:filepath => path}}).to_s
      end
    end
  end
end
