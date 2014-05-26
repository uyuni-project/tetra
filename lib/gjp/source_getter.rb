# encoding: UTF-8

require "rest_client"

module Gjp
  # attempts to get java projects' sources
  class SourceGetter
    include Logging

    # attempts to download a project's sources
    def get_maven_source_jar(project, pom_path)
      maven_runner = Gjp::MavenRunner.new(project)
      pom = Pom.new(pom_path)
      maven_runner.get_source_jar(pom.group_id, pom.artifact_id, pom.version)
    end

    # looks for jars in maven's local repo and downloads corresponding
    # source jars
    def get_maven_source_jars(project)
      maven_runner = Gjp::MavenRunner.new(project)

      project.from_directory do
        paths = Find.find(".").reject { |path| artifact_from_path(path).nil? }.sort

        succeded_paths = paths.select.with_index do |path, i|
          group_id, artifact_id, version = artifact_from_path(path)
          log.info("attempting source download for #{path} (#{group_id}:#{artifact_id}:#{version})")
          maven_runner.get_source_jar(group_id, artifact_id, version)
        end

        [succeded_paths, (paths - succeded_paths)]
      end
    end

    private

    # if possible, turn path into a Maven artifact name, otherwise return nil
    def artifact_from_path(path)
      match = path.match(/\.\/kit\/m2\/(.+)\/(.+)\/(.+)\/\2-\3.*\.jar$/)
      if match != nil
        [match[1].gsub("/", "."), match[2], match[3]]
      end
    end
  end
end
