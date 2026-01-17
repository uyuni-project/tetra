# frozen_string_literal: true

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
        # The pattern `**/*bin/#{name}` matches:
        #   - kit/bin/mvn
        #   - kit/usr/local/bin/ant
        #   - kit/sbin/service (matches your original regex .*bin)
        Dir.glob(File.join("kit", "**", "*bin", name)).each do |path|
          next unless File.executable?(path)

          # Your original regex captured the directory part (.*bin)
          dir = File.dirname(path)

          log.debug("found #{name} executable in #{dir}")
          return dir
        end
      end

      nil
    end
  end
end
