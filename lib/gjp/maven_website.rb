# encoding: UTF-8

require "text"

module Gjp
  # Facade to search.maven.org
  class MavenWebsite 
    include Logger

    # returns a search result object from search.maven.com
    # searching by a jar sha1 hash
    # see output format at http://search.maven.org/#api
    def search_by_sha1(sha1)
      return search(:q => "1:\"#{sha1}\"")
    end

    # returns a search result object from search.maven.com
    # searching by keyword (name)
    # see output format at http://search.maven.org/#api
    def search_by_name(name)
      return search(:q => name)
    end

    # returns a search result object from search.maven.com
    # searching by Maven's group id and artifact id
    # see output format at http://search.maven.org/#api
    def search_by_group_id_and_artifact_id(group_id, artifact_id)
      return search(:q => "g:\"#{group_id}\" AND a:\"#{artifact_id}\"", :core => "gav")
    end

    # returns a search result object from search.maven.com
    # searching by Maven's id (group id, artifact id and version)
    # see output format at http://search.maven.org/#api
    def search_by_maven_id(group_id, artifact_id, version)
      return search(:q => "g:\"#{group_id}\" AND a:\"#{artifact_id}\" AND v:\"#{version}\"")
    end

    # returns a search result object from search.maven.com
    # see input and output format at http://search.maven.org/#api
    def search(params)
        response = RestClient.get("http://search.maven.org/solrsearch/select",
                                  :params => params.merge("rows" => "100", "wt" => "json")
        )
        json = JSON.parse(response.to_s)
        return json["response"]["docs"]
    end

    # returns a Maven's triple (artifactId, groupId, version)
    # from a result object
    def get_maven_id_from(result)
      return result["g"], result["a"], result["v"]
    end
    
    # downloads a POM from a search.maven.com search result
    def download_pom(group_id, artifact_id, version)
      path = "#{group_id.gsub(".", "/")}/#{artifact_id}/#{version}/#{artifact_id}-#{version}.pom"
      log.debug("downloading #{path}...")
      return (RestClient.get "http://search.maven.org/remotecontent", :params => {:filepath => path}).to_s
    end
  end
end
