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

    # returns a command line for running Maven
    def get_mvn_commandline(options)
      full_path = File.join(@project_path, @mvn_path)
      repo_path = File.join(@project_path, "kit", "m2")
      config_path = File.join(@project_path, "kit", "m2", "settings.xml")

      full_options = [
        "-Dmaven.repo.local=#{repo_path}",
        "--settings #{config_path}",
        "--strict-checksums"
      ] + options

      "#{full_path} #{full_options.join(' ')}"
    end
  end
end
