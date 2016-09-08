# encoding: UTF-8

module Tetra
  # encapsulates a Tetra kit directory
  class Kit
    include Logging

    def initialize(project)
      @project = project
    end

    # finds an executable in a bin/ subdirectory of kit
    # returns nil if executable cannot be found
    def find_executable(name)
      @project.from_directory do
        Find.find("kit") do |path|
          next unless path =~ %r{(.*bin)/#{name}$} && File.executable?(path)
          result = Regexp.last_match[1]

          log.debug("found #{name} executable in #{result}")
          return result
        end
      end

      nil
    end
  end
end
