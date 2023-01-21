# encoding: UTF-8

module Tetra
  # encapsulates a pom.xml file
  class Pom
    def initialize(filename)
      content = File.open(filename).read if filename && File.file?(filename)
      @doc = REXML::Document.new(content)
    end

    def group_id
      @doc.text("project/groupId") || ""
    end

    def artifact_id
      @doc.text("project/artifactId") || ""
    end

    def name
      @doc.text("project/name") || ""
    end

    def version
      @doc.text("project/version") || ""
    end

    def description
      @doc.text("project/description") || ""
    end

    def url
      @doc.text("project/url") || ""
    end

    def license_name
      @doc.text("project/licenses/license/name") || ""
    end

    def runtime_dependency_ids
      @doc.get_elements("project/dependencies/dependency[\
        not(optional='true') and not(scope='provided') and not(scope='test') and not(scope='system')\
      ]").map do |element|
        [element.text("groupId"), element.text("artifactId"), element.text("version")]
      end
    end

    def modules
      @doc.get_elements("project/modules/module").map(&:text)
    end

    def scm_connection
      @doc.text("project/scm/connection") || ""
    end

    def scm_url
      @doc.text("project/scm/url") || ""
    end
  end
end
