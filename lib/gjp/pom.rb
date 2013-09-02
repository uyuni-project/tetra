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
    
    def connection_address
      connection_nodes = @doc.xpath("//scm/connection/text()")    
      if connection_nodes.any?
        connection_nodes.first.to_s.sub(/^scm:/, "")
      end
    end
    
    def group_id
      @doc.xpath("project/groupId/text()").to_s
    end
    
    def artifact_id
      @doc.xpath("project/artifactId/text()").to_s
    end
    
    def version
      @doc.xpath("project/version/text()").to_s
    end

    def description
      @doc.xpath("project/description/text()").to_s
    end

    def url
      @doc.xpath("project/url/text()").to_s
    end

    def license_name
      @doc.xpath("project/licenses/license/name/text()").to_s
    end

    def runtime_dependency_ids
      result = @doc.xpath("project/dependencies/dependency[not(optional='true') and not(scope='provided') and not(scope='test') and not(scope='system')]").map do |element|
        [element.xpath("groupId/text()").to_s, element.xpath("artifactId/text()").to_s, element.xpath("version/text()").to_s]
      end
    end

    def parent_group_id
      @doc.xpath("project/parent/groupId/text()").to_s
    end
    
    def parent_artifact_id
      @doc.xpath("project/parent/artifactId/text()").to_s
    end
    
    def parent_version
      @doc.xpath("project/parent/version/text()").to_s
    end
  end
end

