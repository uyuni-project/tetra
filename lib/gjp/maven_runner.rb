# encoding: UTF-8

module Gjp
  # runs Maven with gjp-specific options
  class MavenRunner < KitRunner
    include Logger

    # runs Maven in a subprocess
    def mvn(options)
      run_executable("#{get_maven_commandline(@project.full_path)} #{options.join(' ')}")
    end

    # runs Maven to attempt getting a source jar
    # returns true if successful
    def get_source_jar(group_id, artifact_id, version)
      mvn(["dependency:get", "-Dartifact=#{group_id}:#{artifact_id}:#{version}:jar:sources", "-Dtransitive=false"])
    end
    end

    # returns a command line for running Maven from the specified
    # prefix
    def get_maven_commandline(prefix)
      executable = find_executable("mvn")

      if executable != nil
        mvn_path = File.join(prefix, executable)
        repo_path = File.join(prefix, "kit", "m2")
        config_path = File.join(prefix, "kit", "m2", "settings.xml")

        "#{mvn_path} -Dmaven.repo.local=#{repo_path} -s#{config_path}"
      else
        raise ExecutableNotFoundError.new("mvn")
      end
    end
  end
end
