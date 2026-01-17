# frozen_string_literal: true

module Tetra
  # encapsulates a pom.xml file
  class Pom
    def initialize(filename)
      # ROBUSTNESS: Handle missing file gracefully by initializing empty content
      content = if filename && File.file?(filename)
                  File.read(filename)
                else
                  "<project></project>"
                end
      @doc = REXML::Document.new(content)
    end

    def group_id
      xpath_text("project/groupId")
    end

    def artifact_id
      xpath_text("project/artifactId")
    end

    def name
      xpath_text("project/name")
    end

    def version
      xpath_text("project/version")
    end

    def description
      xpath_text("project/description")
    end

    def url
      xpath_text("project/url")
    end

    def license_name
      xpath_text("project/licenses/license/name")
    end

    def runtime_dependency_ids
      # CLEANUP: Use standard multi-line string for complex XPath
      xpath = "project/dependencies/dependency[" \
              "not(optional='true') and " \
              "not(scope='provided') and " \
              "not(scope='test') and " \
              "not(scope='system')]"

      REXML::XPath.match(@doc, xpath).map do |element|
        [
          element.elements["groupId"]&.text,
          element.elements["artifactId"]&.text,
          element.elements["version"]&.text
        ]
      end
    end

    def modules
      REXML::XPath.match(@doc, "project/modules/module").map(&:text)
    end

    def scm_connection
      xpath_text("project/scm/connection")
    end

    def scm_url
      xpath_text("project/scm/url")
    end

    private

    # HELPER: REXML does not support doc.text("xpath"), so we wrap the logic here.
    def xpath_text(path)
      # Safe navigation (&.) returns nil if node not found; || "" ensures String return
      REXML::XPath.first(@doc, path)&.text&.strip || ""
    end
  end
end
