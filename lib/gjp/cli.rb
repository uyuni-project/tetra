# encoding: UTF-8

require "clamp"

class MainCommand < Clamp::Command
  subcommand "get-pom", "Retrieves a pom corresponding to a jar" do
    parameter "JAR", "jar file path"
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def execute
      begin
        init_logger    
        puts PomGetter.get_pom(jar)
      rescue Zip::ZipError
        $stderr.puts "#{jar} does not seem to be a valid jar archive, skipping"
      rescue TypeError
        $stderr.puts "#{jar} seems to be a valid jar archive but is corrupt, skipping"
      rescue RestClient::ResourceNotFound
        $stderr.puts "Got an error while looking for #{jar} in search.maven.org" 
      end
    end
  end
    
  subcommand "get-source-address", "Retrieves a project's SCM Internet address" do
    parameter "POM", "project's pom file path"
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def execute
      init_logger
      puts SourceAddressGetter.get_source_address(pom)
    end    
  end
  
  subcommand "get-source", "Retrieves a project's source code directory" do
    parameter "ADDRESS", "project's SCM Internet address"
    parameter "POM", "project's pom file path"
    parameter "[DIRECTORY]", "directory in which to save the source code", :default => "."
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def execute
      init_logger
      puts SourceGetter.get_source(address, pom, directory)
    end    
  end
end
