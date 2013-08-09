# encoding: UTF-8

require 'find'

module Gjp
  # runs Maven from a gjp kit with gjp-specific options
  class MavenRunner
    def log
      Gjp.logger
    end

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
    def get_maven_commandline
      maven_executable = find_maven_executable
      "#{maven_executable} -Dmaven.repo.local=kit/m2 -skit/m2/settings.xml"
    end

    # runs mvn in a subprocess
    def mvn(options)
      @project.from_directory do
        Process.wait(Process.spawn("#{get_maven_commandline} #{options.join(' ')}"))
     end
    end
  end
end
