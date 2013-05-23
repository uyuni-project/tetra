# encoding: UTF-8

require 'clamp'
require 'logger'

class MainCommand < Clamp::Command
  subcommand "get-pom", "Retrieves a pom file for an archive or project directory" do
    parameter "PATH", "project directory or jar file path"
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def execute
      begin
        init_logger       
        puts PomGetter.get_pom(path)
      rescue Zip::ZipError
        $stderr.puts "#{path} does not seem to be a valid jar archive, skipping"
      rescue TypeError
        $stderr.puts "#{path} seems to be a valid jar archive but is corrupt, skipping"
      rescue RestClient::ResourceNotFound
        $stderr.puts "Got an error while looking for #{path} in search.maven.org" 
      end
    end
    
    def init_logger
      $log = Logger.new(STDERR)
      $log.level = if very_very_verbose?
        Logger::DEBUG
      elsif very_verbose?
        Logger::INFO
      elsif verbose?
        Logger::WARN
      else
        Logger::ERROR
      end
      
      $log.formatter = proc do |severity, datetime, progname, msg|
        "#{severity.chars.first}: #{msg}\n"
      end
    end
  end
end
