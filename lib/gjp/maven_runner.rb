# encoding: UTF-8

require 'find'
require 'pathname'

module Gjp
  # runs Maven from a gjp kit with gjp-specific options
  class MavenRunner
    include Logger

    def initialize(project)      
      @project = project
    end

    # finds mvn in kit
    def find_maven_executable
      @project.from_directory do
        Find.find("kit") do |path|
          if path =~ /bin\/mvn$/
            log.debug("found Maven executable: #{path}")
            return path
          end
        end
      end

      nil
    end

    # returns a command line for running Maven
    def get_maven_commandline(kit_full_path, running_full_path)
      prefix = path_from running_full_path, kit_full_path
      maven_executable = find_maven_executable

      mvn_path = File.join(prefix, maven_executable)
      repo_path = File.join(prefix, "kit", "m2")
      config_path = File.join(prefix, "kit", "m2", "settings.xml")

      "#{mvn_path} -Dmaven.repo.local=`readlink -e #{repo_path}` -s`readlink -e #{config_path}`"
    end

    # returns a path from origin to destination, provided they are both absolute
    def path_from(origin, destination)
      (Pathname.new(destination).relative_path_from Pathname.new(origin)).split.first
    end

    # runs mvn in a subprocess
    def mvn(options)
      kit_full_path = File.join(@project.full_path, "kit")
      running_full_path = File.expand_path(".")
      Process.wait(Process.spawn("#{get_maven_commandline(kit_full_path, running_full_path)} #{options.join(' ')}"))
    end
  end
end
