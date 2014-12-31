# encoding: UTF-8

module Tetra
  # runs Maven with tetra-specific options
  class MavenRunner < KitRunner
    include Logging

    # runs Maven in a subprocess
    def mvn(options)
      run_executable(get_maven_commandline(@project.full_path, options))
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
      effective_pom_path if success
    end

    # returns a command line for running Maven from the specified
    # prefix
    def get_maven_commandline(prefix, options)
      executable = find_executable("mvn")

      if !executable.nil?
        mvn_path = File.join(prefix, executable)
        repo_path = File.join(prefix, "kit", "m2")
        config_path = File.join(prefix, "kit", "m2", "settings.xml")

        "#{mvn_path} -Dmaven.repo.local=#{repo_path} -s#{config_path} #{options.join(' ')}"
      else
        fail ExecutableNotFoundError, "mvn"
      end
    end
  end
end
