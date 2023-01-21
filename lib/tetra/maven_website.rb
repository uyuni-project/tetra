# frozen_string_literal: true

module Tetra
  # Facade to search.maven.org
  class MavenWebsite
    include Logging

    # returns a search result object from search.maven.com
    # searching by a jar sha1 hash
    # see output format at https://search.maven.org/#api
    def search_by_sha1(sha1)
      search(q: "1:\"#{sha1}\"")
    end

    # returns a search result object from search.maven.com
    # searching by keyword (name)
    # see output format at https://search.maven.org/#api
    def search_by_name(name)
      search(q: name)
    end

    # returns a search result object from search.maven.com
    # searching by Maven's group id and artifact id
    # see output format at https://search.maven.org/#api
    def search_by_group_id_and_artifact_id(group_id, artifact_id)
      search(q: "g:\"#{group_id}\" AND a:\"#{artifact_id}\"", core: "gav")
    end

    # returns a search result object from search.maven.com
    # searching by Maven's id (group id, artifact id and version)
    # see output format at https://search.maven.org/#api
    def search_by_maven_id(group_id, artifact_id, version)
      search(q: "g:\"#{group_id}\" AND a:\"#{artifact_id}\" AND v:\"#{version}\"")
    end

    # returns a search result object from search.maven.com
    # see input and output format at https://search.maven.org/#api
    def search(params)
      response = get("https://search.maven.org/solrsearch/select?", params.merge("rows" => "100", "wt" => "json"))
      json = JSON.parse(response.to_s)
      json["response"]["docs"]
    end

    # returns a Maven's triple (artifactId, groupId, version)
    # from a result object
    def get_maven_id_from(result)
      [result["g"], result["a"], result["v"]]
    end

    # downloads a POM from a search.maven.com search result
    def download_pom(group_id, artifact_id, version)
      path = "#{group_id.gsub('.', '/')}/#{artifact_id}/#{version}/#{artifact_id}-#{version}.pom"
      log.debug("downloading #{path}...")
      get("https://repo1.maven.org/maven2/#{path}", {}).to_s
    end

    def get(url, params)
      response = Net::HTTP.get_response(URI.parse(url + URI.encode_www_form(params)))
      raise NotFoundOnMavenWebsiteError if response.code == "404"

      response.body
    end
  end

  class NotFoundOnMavenWebsiteError < StandardError
  end
end
