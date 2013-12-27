# encoding: UTF-8

require "rest_client"
require "json"
require "open-uri"

module Gjp
  # attempts to get java projects' scm addresses
  class SourceAddressGetter
    include Logger

    # returns the SCM address for a project described in file
    def get_source_address(file)
      log.info("looking for source address for: #{file}")
      (get_source_address_from_pom(file) or get_source_address_from_github(file))
    end

    # returns an scm address in a pom file
    def get_source_address_from_pom(file)
      pom = Pom.new(file)
      result = pom.connection_address

      if result != nil
        log.info("address found in pom")
        result
      end
    end
    
    # returns an scm address looking for it on github
    def get_source_address_from_github(file)
      pom = Pom.new(file)

      result = (github_search(pom.artifact_id) or github_search(pom.artifact_id.split("-").first) or github_search(pom.group_id))
      
      if result != nil
        log.info("address found on Github: #{result}")
        result
      end
    end
    
    # returns a Giuthub repo address based on the keyword
    def github_search(keyword)
      if keyword != "" and keyword != nil
        response = RestClient.get "https://api.github.com/legacy/repos/search/" + CGI::escape(keyword), :user_agent => "gjp/" + Gjp::VERSION, :language => "java", :sort => "forks"
        json = JSON.parse(response.to_s)
      
        (json["repositories"].map {|repository| "git:" + repository["url"]}).first
      end
    end
  end
end
