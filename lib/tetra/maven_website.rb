# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Tetra
  # Facade to search.maven.org (and central.sonatype.com)
  class MavenWebsite
    include Logging

    # API Constants
    SEARCH_API = "https://search.maven.org/solrsearch/select".freeze
    DOWNLOAD_API = "https://repo1.maven.org/maven2".freeze

    def search_by_sha1(sha1)
      search(q: "1:\"#{sha1}\"")
    end

    def search_by_name(name)
      search(q: name)
    end

    def search_by_group_id_and_artifact_id(group_id, artifact_id)
      search(q: "g:\"#{group_id}\" AND a:\"#{artifact_id}\"", core: "gav")
    end

    def search_by_maven_id(group_id, artifact_id, version)
      search(q: "g:\"#{group_id}\" AND a:\"#{artifact_id}\" AND v:\"#{version}\"")
    end

    def search(params)
      # Merge default API parameters
      full_params = params.merge("rows" => "100", "wt" => "json")
      response_body = fetch(SEARCH_API, full_params)

      json = JSON.parse(response_body)
      json["response"]["docs"]
    end

    def get_maven_id_from(result)
      [result["g"], result["a"], result["v"]]
    end

    def download_pom(group_id, artifact_id, version)
      # Use tr instead of gsub for performance (standard Ruby optimization)
      group_path = group_id.tr(".", "/")
      path = "#{group_path}/#{artifact_id}/#{version}/#{artifact_id}-#{version}.pom"

      log.debug("downloading #{path}...")

      # We pass empty params because the path contains everything
      url = "#{DOWNLOAD_API}/#{path}"
      fetch(url)
    end

    private

    # A robust HTTP fetcher with Retries, Timeouts, and Redirect handling
    def fetch(url_str, params = {}, limit = 5)
      raise ArgumentError, "HTTP redirect too deep" if limit.zero?

      uri = URI(url_str)
      uri.query = URI.encode_www_form(params) unless params.empty?

      retries = 0
      begin
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.open_timeout = 10 # Wait 10s for connection
          http.read_timeout = 30 # Wait 30s for data

          request = Net::HTTP::Get.new(uri)
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          response.body
        when Net::HTTPRedirection
          location = response["location"]
          log.info("Redirected to #{location}")
          # Recursive call to follow redirect (params are usually part of the new URL)
          fetch(location, {}, limit - 1)
        when Net::HTTPNotFound
          fail NotFoundOnMavenWebsiteError
        else
          fail "Remote error: #{response.code} #{response.message}"
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET => e
        if (retries += 1) <= 3
          log.warn("Network error: #{e.class} - #{e.message}. Retrying (#{retries}/3)...")
          sleep(1) # Backoff before retry
          retry
        else
          log.error("Failed to fetch #{url_str} after 3 retries")
          raise e
        end
      end
    end
  end

  class NotFoundOnMavenWebsiteError < StandardError
  end
end
