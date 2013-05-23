# encoding: UTF-8

require "digest/sha1"
require "zip/zip"
require "rest_client"
require "json"
require "text"
require "pathname"

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
    matches = filename.match(/([^\/]*?)(?:[\.\-\_ ~,]([0-9].*))?\.jar$/)
    if matches != nil and matches.length > 1
      my_artifact_id = matches[1]
      my_version = matches[2]
      result = repository_search({:q => my_artifact_id}).first
      if result != nil
          results = repository_search({:q => "g:\"#{result["g"]}\" AND a:\"#{result["a"]}\"", :core => "gav"})
          their_versions = results.map {|doc| doc["v"]}
          best_matched_version = if my_version != nil then best_match(my_version, their_versions) else their_versions.max end
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
  
  # returns the "best match" between a version number and a set of available version numbers
  # using a heuristic criterion. Idea:
  #  - split the version number in chunks divided by ., - etc.
  #  - every chunk with same index is "compared", differences make up a score
  #  - "comparison" is a subtraction if the chunk is an integer, a string distance measure otherwise
  #  - score weighs differently on chunk index (first chunks are most important)
  #  - lowest score wins
  def self.best_match(my_version, their_versions)
    $log.debug("version comparison: #{my_version} vs #{their_versions.join(', ')}")
  
    my_chunks = my_version.split /[\.\-\_ ~,]/
    their_chunks_hash = Hash[
      their_versions.map do |their_version|
        their_chunks_for_version = their_version.split /[\.\-\_ ~,]/
        their_chunks_for_version += [nil]*[my_chunks.length - their_chunks_for_version.length, 0].max
        [their_version, their_chunks_for_version]
      end
    ]
    
    max_chunks_length = ([my_chunks.length] + their_chunks_hash.values.map {|chunk| chunk.length}).max
    
    scoreboard = []
    their_versions.each do |their_version|
      their_chunks = their_chunks_hash[their_version]
      score = 0
      their_chunks.each_with_index do |their_chunk, i|
        score_multiplier = 100**(max_chunks_length -i -1)
        my_chunk = my_chunks[i]
        score += chunk_distance(my_chunk, their_chunk) * score_multiplier
      end
      scoreboard << {:version => their_version, :score => score}
    end
    
    scoreboard = scoreboard.sort_by {|element| element[:score]}

    $log.debug("scoreboard: ")
    scoreboard.each_with_index do |element, i|
      $log.debug("  #{i+1}. #{element[:version]} (score: #{element[:score]})")
    end
    
    winner = scoreboard.first
    
    if winner != nil
      return winner[:version]
    end
  end
  
  # returns a score representing the distance between two version chunks
  # for integers, the score is the difference between their values
  # for strings, the score is the Levenshtein distance
  # in any case score is normalized between 0 (identical) and 99 (very different/uncomparable)
  def self.chunk_distance(my_chunk, their_chunk)
    if my_chunk == nil
      my_chunk = "0"
    end
    if their_chunk == nil
      their_chunk = "0"
    end
    if my_chunk.is_i? and their_chunk.is_i?
      return [(my_chunk.to_i - their_chunk.to_i).abs, 99].min
    else
      return [Text::Levenshtein.distance(my_chunk.upcase, their_chunk.upcase), 99].min
    end
  end
end

class String
  def is_i?
    !!(self =~ /^[0-9]+$/)
  end
end

