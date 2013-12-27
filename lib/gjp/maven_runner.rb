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

    # runs Maven to get the effective POM from an existing POM
    # returns effective pom path or nil if not found
    def get_effective_pom(pom_path)
      effective_pom_path = "#{pom_path}.effective"
      success = mvn(["help:effective-pom", "-f#{pom_path}", "-Doutput=#{File.split(effective_pom_path)[1]}"])
      if success
        effective_pom_path
      else
        nil
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
