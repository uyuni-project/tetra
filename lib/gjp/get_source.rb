# encoding: UTF-8

require "rest_client"

# implements the get-source subcommand
class SourceGetter

  # downloads a project's source into a specified directory
  def self.get_source(address, pomfile, directory)
    $log.info("downloading: #{address} in #{directory}, pomfile: #{pomfile}")
    
    dummy, prefix, scm_address = address.split(/^([^:]+):(.*)$/)
    
    $log.info("prefix: #{prefix}, scm_address: #{scm_address}")
        
    if prefix == "git"
      get_source_from_git(scm_address, pomfile, directory)
    end
  end

  # checks out from git
  def self.get_source_from_git(scm_address, pomfile, directory)
    pom = Pom.new(pomfile)
    dir = File.join(directory, "#{pom.group_id}:#{pom.artifact_id}:#{pom.version}")
    
    Dir::mkdir(dir)
    `git clone #{scm_address} #{dir}`
  end
end
