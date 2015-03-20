# encoding: UTF-8

module Tetra
  # encapsulates tetra-specific Ant commandline options
  class Ant
    # returns a command line for running Ant
    def self.commandline(project_path, ant_path)
      if ant_path
        File.join(project_path, ant_path, "ant")
      else
        "ant" # use system-provided executable
      end
    end
  end
end
