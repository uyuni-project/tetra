# encoding: UTF-8

module Tetra
  # runs Ant with tetra-specific options
  class Ant
    include Logging
    include ProcessRunner

    # project_path is relative to the current dir
    # ant_path is relative to project_path
    def initialize(project_path, ant_path)
      @project_path = project_path
      @ant_path = ant_path
    end

    # runs ant in a subprocess
    def ant(options)
      run(get_ant_commandline(options), true)
    end

    # returns a command line for running Ant
    def get_ant_commandline(options)
      full_path = File.join(@project_path, @ant_path)
      "#{full_path} #{options.join(' ')}"
    end
  end
end
