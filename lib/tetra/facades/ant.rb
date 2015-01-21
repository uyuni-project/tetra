# encoding: UTF-8

module Tetra
  # runs Ant with tetra-specific options
  class Ant < KitRunner
    include Logging
    include ProcessRunner

    # runs ant in a subprocess
    def ant(options)
      run("#{get_ant_commandline(@project.full_path)} #{options.join(' ')}", true)
    end

    # returns a command line for running Ant from the specified
    # prefix
    def get_ant_commandline(prefix)
      File.join(prefix, find_executable("ant"))
    end
  end
end
