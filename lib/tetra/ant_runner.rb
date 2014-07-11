# encoding: UTF-8

module Tetra
  # runs Ant with tetra-specific options
  class AntRunner < KitRunner
    include Logging

    # runs ant in a subprocess
    def ant(options)
      run_executable("#{get_ant_commandline(@project.full_path)} #{options.join(" ")}")
    end

    # returns a command line for running Ant from the specified
    # prefix
    def get_ant_commandline(prefix)
      executable = find_executable("ant")

      if !executable.nil?
        ant_path = File.join(prefix, executable)

        "#{ant_path}"
      else
        fail ExecutableNotFoundError, "ant"
      end
    end
  end
end
