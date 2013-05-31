# encoding: UTF-8

require "digest/sha1"
require "zip/zip"
require "rest_client"
require "json"
require "pathname"

require "gjp/version_matcher"

# implements the get-pom subcommand
class PomGetter

  # returns the pom corresponding to a file or directory, if it can be found
  def self.get_pom(file)
    (get_pom_from_dir(file) or get_pom_from_jar(file) or get_pom_from_sha1(file) or get_pom_from_heuristic(file))
  end

  # returns the pom in a project directory
  def self.get_pom_from_dir(dir)
    if File.directory?(dir)
      pom_path = File.join(dir, "pom.xml")
      if File.file?(pom_path)
          $log.info("pom.xml found in #{dir}/pom.xml")
          return File.read(pom_path)
      end
    end
  end
  
  # returns a pom embedded in a jar file
  def self.get_pom_from_jar(file)
    Zip::ZipFile.foreach(file) do |entry|
      if entry.name =~ /\/pom.xml$/
        $log.info("pom.xml found in #{file}##{entry.name}")
        return entry.get_input_stream.read
      end
    end
    return nil
  end
  
  # returns a pom from search.maven.org with a jar sha1 search
  def self.get_pom_from_sha1(file)
    sha1 = Digest::SHA1.hexdigest File.read(file)
    results = repository_search({:q => "1:\"#{sha1}\""}).select {|result| result["ec"].include?(".pom")}
    result = results.first    
    if result != nil
      $log.info("pom.xml for #{file} found on search.maven.org for sha1 #{sha1} (#{result["g"]}:#{result["a"]}:#{result["v"]})")
      return repository_download(result)
    end
  end

  # returns a pom from search.maven.org with a heuristic name search
  def self.get_pom_from_heuristic(file)
    filename = Pathname.new(file).basename.to_s
    if filename =~ /([^\/]*)\.jar$/
			my_artifact_id, my_version = VersionMatcher.split_version($1)

      result = repository_search({:q => my_artifact_id}).first
      if result != nil
          results = repository_search({:q => "g:\"#{result["g"]}\" AND a:\"#{result["a"]}\"", :core => "gav"})
          their_versions = results.map {|doc| doc["v"]}
          best_matched_version = if my_version != nil then VersionMatcher.best_match(my_version, their_versions) else their_versions.max end
          best_matched_result = (results.select{|result| result["v"] == best_matched_version}).first
          
          $log.warn("pom.xml for #{file} found on search.maven.org with heuristic search (#{best_matched_result["g"]}:#{best_matched_result["a"]}:#{best_matched_result["v"]})")
          
          return repository_download(best_matched_result)
      end
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

