# encoding: UTF-8

require 'find'
require 'pathname'

module Gjp
  # runs programs from a gjp kit with gjp-specific options
  class KitRunner
    include Logger

    def initialize(project)      
      @project = project
    end

    # finds an executable in a bin/ subdirectory of kit
    def find_executable(name)
      @project.from_directory do
        Find.find("kit") do |path|
          if path =~ /bin\/#{name}$/
            log.debug("found #{name} executable: #{path}")
            return path
          end
        end
      end

      log.debug("#{name} executable not found")
      nil
    end

    # runs an external executable
    def run_executable(full_commandline)
      log.debug "running #{full_commandline}"
      Process.wait(Process.spawn(full_commandline))
    end

    # runs mvn in a subprocess
    def mvn(options)
      run_executable "#{get_maven_commandline(@project.full_path)} #{options.join(' ')}"
    end

    # returns a command line for running Maven from the specified
    # prefix
    def get_maven_commandline(prefix)
      executable = find_executable("mvn")

      if executable != nil
        mvn_path = File.join(prefix, executable)
        repo_path = File.join(prefix, "kit", "m2")
        config_path = File.join(prefix, "kit", "m2", "settings.xml")

        "#{mvn_path} -Dmaven.repo.local=#{repo_path} -s#{config_path}"
      else
        raise ExecutableNotFoundError.new("mvn")
      end
    end

    # runs mvn in a subprocess
    def ant(options)
      run_executable "#{get_ant_commandline(@project.full_path)} #{options.join(' ')}"
    end

    # returns a command line for running Ant from the specified
    # prefix
    def get_ant_commandline(prefix)
      executable = find_executable("ant")

      if executable != nil
        ant_path = File.join(prefix, executable)

        "#{ant_path}"
      else
        raise ExecutableNotFoundError.new("ant")
      end
    end
  end

  class ExecutableNotFoundError < Exception
    attr_reader :executable

    def initialize(executable)
      @executable = executable
    end
  end
end
