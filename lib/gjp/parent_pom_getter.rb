# encoding: UTF-8

require "pathname"

module Gjp
  # attempts to get a pom's parent pom
  class ParentPomGetter
    include Logger

    # returns the pom's parent, if any
    def get_parent_pom(filename)
      begin
        pom = Pom.new(filename)
        site = MavenWebsite.new

        site.download_pom(pom.parent_group_id, pom.parent_artifact_id, pom.parent_version)
      rescue RestClient::ResourceNotFound
        $stderr.puts "Could not find a parent for this pom!" 
      end
    end
  end
end
