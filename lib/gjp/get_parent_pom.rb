# encoding: UTF-8

require "pathname"

module Gjp
  # implements the get-parent-pom subcommand
  class ParentPomGetter

    def self.log
      Gjp.logger
    end

    # returns the pom's parent, if any
    def self.get_parent_pom(filename)
      pom = Pom.new(filename)
      site = MavenWebsite.new

      site.download_pom(pom.parent_group_id, pom.parent_artifact_id, pom.parent_version)
    end
  end
end
