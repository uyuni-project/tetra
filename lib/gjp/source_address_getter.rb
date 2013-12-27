# encoding: UTF-8

require "rest_client"
require "json"
require "open-uri"

module Gjp
  # attempts to get java projects' scm addresses
  class SourceAddressGetter
    include Logger

    # returns the SCM address for a project described in pom_path
    def get_source_address(pom_path)
      log.info("looking for source address for: #{pom_path}")
      (get_source_address_from_pom(pom_path) or get_source_address_from_github(pom_path))
    end

    # returns an scm address in a pom pom_path
    def get_source_address_from_pom(pom_path)
      pom = Pom.new(pom_path)
      result = pom.connection_address

      if result != nil
        log.info("address found in pom")
        result
      end
    end
    
    # returns an scm address looking for it on github
    def get_source_address_from_github(pom_path)
      pom = Pom.new(pom_path)

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
