# encoding: UTF-8

module Tetra
  # runs Maven with tetra-specific options
  class Mvn
    include Logging
    include ProcessRunner

    # project_path is relative to the current dir
    # mvn_path is relative to project_path
    def initialize(project_path, mvn_path)
      @project_path = project_path
      @mvn_path = mvn_path
    end

    # runs Maven in a subprocess
    def mvn(options)
      run(get_mvn_commandline(options), true)
    end

    # runs Maven to get the effective POM from an existing POM
    # returns effective pom path or nil if not found
    def get_effective_pom(pom_path)
      effective_pom_path = "#{pom_path}.effective"
      success = mvn(["help:effective-pom", "-f#{pom_path}", "-Doutput=#{File.split(effective_pom_path)[1]}"])
      effective_pom_path if success
    end

    # returns a command line for running Maven
    def get_mvn_commandline(options)
      full_path = File.join(@project_path, @mvn_path)
      repo_path = File.join(@project_path, "kit", "m2")
      config_path = File.join(@project_path, "kit", "m2", "settings.xml")

      "#{full_path} -Dmaven.repo.local=#{repo_path} -s#{config_path} #{options.join(' ')}"
    end
  end
end
