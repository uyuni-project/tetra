# encoding: UTF-8

require 'clamp'

class MainCommand < Clamp::Command
  subcommand "get-pom", "Retrieves a pom file for an archive or project directory" do
    parameter "[PATH]", "project directory or jar file path", :default => "."

    def execute
      begin
        puts PomGetter.get_pom(path)
      rescue Zip::ZipError
        $stderr.puts "#{path} does not seem to be a valid jar archive, skipping"
      rescue TypeError
        $stderr.puts "#{path} seems to be a valid jar archive but is corrupt, skipping"
      rescue RestClient::ResourceNotFound
        $stderr.puts "Got an error while looking for #{path} in search.maven.org" 
      end
    end
  end
end
