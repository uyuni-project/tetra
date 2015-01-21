# encoding: UTF-8

module Tetra
  # attempts to get java projects' sources
  class SourceGetter
    include Logging

    # attempts to download a project's sources
    def get_maven_source_jar(project, pom_path)
      mvn_path = Tetra::Kit.new(project).find_executable("mvn")
      mvn = Tetra::Mvn.new(project.full_path, mvn_path)
      pom = Pom.new(pom_path)
      mvn.get_source_jar(pom.group_id, pom.artifact_id, pom.version)
    end

    # looks for jars in maven's local repo and downloads corresponding
    # source jars
    def get_maven_source_jars(project)
      mvn_path = Tetra::Kit.new(project).find_executable("mvn")
      mvn = Tetra::Mvn.new(project.full_path, mvn_path)

      project.from_directory do
        paths = Find.find(".").reject { |path| artifact_from_path(path).nil? }.sort

        succeded_paths = paths.select do |path|
          group_id, artifact_id, version = artifact_from_path(path)
          log.info("attempting source download for #{path} (#{group_id}:#{artifact_id}:#{version})")
          begin
            mvn.get_source_jar(group_id, artifact_id, version)
            true
          rescue Tetra::ExecutionFailed
            false
          end
        end

        [succeded_paths, (paths - succeded_paths)]
      end
    end

    private

    # if possible, turn path into a Maven artifact name, otherwise return nil
    def artifact_from_path(path)
      match = path.match(%r{\./kit/m2/(.+)/(.+)/(.+)/\2-\3.*\.jar$})
      [match[1].gsub("/", "."), match[2], match[3]] unless match.nil?
    end
  end
end
