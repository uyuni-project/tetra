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

      log.debug("Maven executable not found")
      nil
    end

    # returns a command line for running Maven from the specified
    # prefix
    def get_maven_commandline(prefix)
      maven_executable = find_maven_executable

      if maven_executable != nil
        mvn_path = File.join(prefix, maven_executable)
        repo_path = File.join(prefix, "kit", "m2")
        config_path = File.join(prefix, "kit", "m2", "settings.xml")

        "#{mvn_path} -Dmaven.repo.local=#{repo_path} -s#{config_path}"
      else
        raise MavenNotFoundException
      end
    end

    # runs mvn in a subprocess
    def mvn(options)
      full_commandline = "#{get_maven_commandline(@project.full_path)} #{options.join(' ')}"
      log.debug full_commandline

      Process.wait(Process.spawn(full_commandline))
      full_commandline
    end
  end

  class MavenNotFoundException < Exception
  end
end
