# frozen_string_literal: true
module Tetra
  # encapsulates tetra-specific Ant commandline options
  class Ant
    # returns a command line for running Ant
    def self.commandline(project_path, ant_path)
      return "ant" unless ant_path

      File.join(project_path, ant_path, "ant")
    end
  end
end
