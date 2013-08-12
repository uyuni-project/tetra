# encoding: UTF-8

require "rest_client"

module Gjp
  # attempts to get java projects' sources from scm
  class SourceGetter
    include Logger

    # downloads a project's source into a specified directory
    def get_source(address, pomfile, directory)
      log.info("downloading: #{address} in #{directory}, pomfile: #{pomfile}")
      
      dummy, prefix, scm_address = address.split(/^([^:]+):(.*)$/)
      log.info("prefix: #{prefix}, scm_address: #{scm_address}")
  	
  		get_source_from_scm(prefix, scm_address, pomfile, directory)
    end

    # checks code out from an scm
    def get_source_from_scm(prefix, scm_address, pomfile, directory)
      pom = Pom.new(pomfile)
      dir = File.join(directory, "#{pom.group_id}:#{pom.artifact_id}:#{pom.version}")
  		begin
  	    Dir::mkdir(dir)
  		rescue Errno::EEXIST
  			log.warn("Source directory exists, leaving...")
  		end
      
  		if prefix == "git"
  			get_source_from_git(scm_address, dir, pom.version)
      elsif prefix == "svn"
  			get_source_from_svn(scm_address, dir, pom.version)
  		end
    end

    # checks code out of git
  	def get_source_from_git(scm_address, dir, version)
  		`git clone #{scm_address} #{dir}`
  		
  		Dir.chdir(dir) do
  			tags = `git tag`.split("\n")
  		  
  			if tags.any?
  				best_tag = get_best_tag(tags, version)		 	
  				log.info("checking out tag: #{best_tag}")

  				`git checkout #{best_tag}`
  			end	
  		end
  	end

    # checks code out of svn
  	def get_source_from_svn(scm_address, dir, version)
  		`svn checkout #{scm_address} #{dir}`
  		
  		Dir.chdir(dir) do
  			tags = `svn ls "^/tags"`.split("\n")
  			
  			if tags.any?
  				best_tag = get_best_tag(tags, version)		 	
  				log.info("checking out tag: #{best_tag}")

  				`svn checkout ^/tags/#{best_tag}`
  			end
  		end
  	end

  	# return the (heuristically) most similar tag to the specified version
  	def get_best_tag(tags, version)
      version_matcher = VersionMatcher.new

  		versions_to_tags = Hash[
  			*tags.map do |tag|
  				[version_matcher.split_version(tag)[1], tag]
  			end.flatten
  		]
  			
  	  log.info("found the following versions and tags: #{versions_to_tags}")

  		best_version = version_matcher.best_match(version, versions_to_tags.keys)
  		versions_to_tags[best_version]
  	end
  end
end
