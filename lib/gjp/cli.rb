# encoding: UTF-8
require "gjp/logger"
require "clamp"

# Initialize global logger for CLI
Gjp.logger = ::Logger.new(STDERR)
Gjp.logger.datetime_format = "%Y-%m-%d %H:%M "
Gjp.logger.level = ::Logger::ERROR
Gjp.logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity.chars.first}: #{msg}\n"
end

module Gjp
  class MainCommand < Clamp::Command

    # Common logging options
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def very_very_verbose=(flag)
      configure_log_level(verbose?, very_verbose?, flag)
    end
    
    def very_verbose=(flag)
      configure_log_level(verbose?, flag, very_very_verbose?)
    end
    
    def verbose=(flag)
      configure_log_level(flag, very_verbose?, very_very_verbose?)
    end

    def configure_log_level(v, vv, vvv)
      if vvv
        Gjp.logger.level = Logger::DEBUG
      elsif vv
        Gjp.logger.level = Logger::INFO
      elsif v
        Gjp.logger.level = Logger::WARN
      else
        Gjp.logger.level = Logger::ERROR
      end
    end

    # Subcommands
    subcommand "init", "Inits a gjp project in the current directory" do
      def execute
        Gjp::Project.new(".").init
        puts "Project inited."
        puts "Use \"gjp gather\" before adding files to have gjp track them."
      end
    end

    subcommand "get-pom", "Retrieves a pom corresponding to a filename" do
      parameter "NAME", "a jar file path, a project directory path or a non-existing filename in the `project-version` form"
      def execute
        puts Gjp::PomGetter.get_pom(name)
      end
    end

    subcommand "get-parent-pom", "Retrieves a pom that is the parent of an existing pom" do
      parameter "POM", "a pom file path or URI"
      def execute
        puts Gjp::ParentPomGetter.get_parent_pom(pom)
      end
    end
      
    subcommand "get-source-address", "Retrieves a project's SCM Internet address" do
      parameter "POM", "a pom file path or URI"

      def execute
        puts Gjp::SourceAddressGetter.get_source_address(pom)
      end    
    end
    
    subcommand "get-source", "Retrieves a project's source code directory" do
      parameter "ADDRESS", "project's SCM Internet address"
      parameter "POM", "project's pom file path or URI"
      parameter "[DIRECTORY]", "directory in which to save the source code", :default => "."

      def execute
        puts Gjp::SourceGetter.get_source(address, pom, directory)
      end    
    end

    subcommand "scaffold-jar-table", "Creates a heuristic version of a project's jar table" do
      parameter "[DIRECTORY]", "project directory", :default => "."
      option ["--include-all"], :flag, "include tests and samples in produced jars", :default => false

      def execute
        puts Gjp::JarTable.new(directory, include_all?).to_s
      end    
    end
  end
end
