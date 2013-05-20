# encoding: UTF-8

require "digest/sha1"
require "zip/zip"
require "rest_client"
require "json"

class PomGetter
  def self.get_pom(file)
    if File.directory?(file)
      get_pom_from_dir(file)
    elsif File.file?(file)
      get_pom_from_jar(file) or get_pom_from_site(file)
    end
  end

  def self.get_pom_from_dir(dir)
    pom_path = File.join(dir, "pom.xml")
    if File.file?(pom_path)
      return File.read(pom_path)
    end
  end
  
  def self.get_pom_from_jar(file)
    Zip::ZipFile.foreach(file) do |entry|
      if entry.name =~ /\/pom.xml$/
        return entry.get_input_stream.read
      end
    end
    nil
  end
  
  def self.get_pom_from_site(file)
    sha1 = Digest::SHA1.hexdigest File.read(file)
    response = RestClient.get "http://search.maven.org/solrsearch/select", {:params => {:q => "1:\"#{sha1}\"", "rows" => "100", "wt" => "json"}}
    if response.code == 200
      json = JSON.parse(response.to_s)
      results = json["response"]["docs"].select {|result| result["ec"].include?(".pom")}
      if results.length > 0
        result = results.first
        path = "#{result["g"].gsub(".", "/")}/#{result["a"]}/#{result["v"]}/#{result["a"]}-#{result["v"]}.pom"
        response = RestClient.get "http://search.maven.org/remotecontent", {:params => {:filepath => path}}
        if response.code == 200
          return response.to_s
        end
      end
    end
  end
end
