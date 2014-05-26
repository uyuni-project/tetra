# encoding: UTF-8

require "nokogiri"
require "open-uri"

module Gjp
  # encapsulates a pom.xml file
  class Pom
    def initialize(filename)
      @doc = Nokogiri::XML(open(filename).read)
      @doc.remove_namespaces!
    end

    def group_id
      @doc.xpath("project/groupId").text || ""
    end

    def artifact_id
      @doc.xpath("project/artifactId").text || ""
    end

    def name
      @doc.xpath("project/name").text || ""
    end

    def version
      @doc.xpath("project/version").text || ""
    end

    def description
      @doc.xpath("project/description").text || ""
    end

    def url
      @doc.xpath("project/url").text || ""
    end

    def license_name
      @doc.xpath("project/licenses/license/name").text || ""
    end

    def runtime_dependency_ids
      result = @doc.xpath("project/dependencies/dependency[\
        not(optional='true') and not(scope='provided') and not(scope='test') and not(scope='system')\
      ]").map do |element|
        [element.xpath("groupId").text, element.xpath("artifactId").text, element.xpath("version").text]
      end
    end

    def scm_connection
      @doc.xpath("project/scm/connection").text || ""
    end

    def scm_url
      @doc.xpath("project/scm/url").text || ""
    end
  end
end
