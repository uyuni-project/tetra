# encoding: UTF-8

require "rest_client"

# implements the get-source subcommand
class SourceGetter

  # downloads a project's source into a specified directory
  def self.get_source(address, pomfile, directory)
    $log.info("downloading: #{address} in #{directory}, pomfile: #{pomfile}")
    
    dummy, prefix, scm_address = address.split(/^([^:]+):(.*)$/)
    $log.info("prefix: #{prefix}, scm_address: #{scm_address}")
	
		get_source_from_scm(prefix, scm_address, pomfile, directory)
  end

  # checks out code from git, svn...
  def self.get_source_from_scm(prefix, scm_address, pomfile, directory)
    pom = Pom.new(pomfile)
    dir = File.join(directory, "#{pom.group_id}:#{pom.artifact_id}:#{pom.version}")
    Dir::mkdir(dir)
    
		if prefix == "git"
			`git clone #{scm_address} #{dir}`
    elsif prefix == "svn"
			`svn checkout #{scm_address} #{dir}`
		end
  end
end
