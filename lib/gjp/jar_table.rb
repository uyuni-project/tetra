# encoding: UTF-8

require "text"

module Gjp
  # encapsulates information of a project's jar files
  # assumes the project is in a directory with jar files
  # in its (possibly nested) subdirectories
  class JarTable
    def self.log
      Gjp.logger
    end

    attr_reader :dir, :rows

    # builds a JarTable from a directory (paths relative to the current directory)
    def initialize(dir)
      @dir = dir

      @rows = Hash[
        jars.map do |jar|
          pathname = Pathname.new(jar)
          [pathname.basename.to_s, {:type => get_type(jar), :directory => pathname.dirname.to_s}]
        end
      ]
    end

    # jar files in the project's directory
    def jars
      Dir["#{@dir}/**/*.jar"]
    end

    # returns packages defined in a jar file
    def jar_defined_packages(jar)
      result = []
      begin
        Zip::ZipFile.foreach(jar) do |entry|
          if entry.name =~ /^(.+)\/.+?\.class$/
            result << $1.gsub("/", ".")
          end
        end
      rescue Zip::ZipError
        log.info "#{file} does not seem to be a valid jar archive, skipping"
      rescue TypeError
        log.info "#{file} seems to be a valid jar archive but is corrupt, skipping"
      end

      return result.sort.uniq
    end

    # returns :produced if the jar was produced from the project's sources, and
    # :required or :build_required if it is needed at runtime or build time
    # (heuristically)
    def get_type(jar)
      if source_defined?(jar)
        :produced
      elsif runtime_required?(jar)
        :required
      else
        :build_required        
      end
    end

    # returns true if a jar is produced from source code in the project's directory
    def source_defined?(jar)
      jar_defined_packages(jar).all? { |package| source_defined_packages.include?(package)  }
    end

    # returns true if a jar is required runtime, false if it is only needed
    # at compile time. Current implementation is heuristic (looks for "import" statements
    # in java code)
    def runtime_required?(jar)
      jar_defined_packages(jar).any? { |package| source_required_packages.include?(package)  }
    end

    # java source files in the project's directory
    def sources
      Dir["#{@dir}/**/*.java"]
    end

    # java statements in java source files
    def statements
      sources.map do |source|
        File.readlines(source)
          .map { |line| line.split(";")  }
          .flatten
          .map { |statement| statement.strip }
      end.flatten
    end

    # heuristically determined package names that the sources require
    def source_required_packages
      statement_fragments_from(/^import[ \t]+(?:static[ \t]+)?(.+)\..+?$/)
    end

    # heuristically determined package names that the sources define
    def source_defined_packages
      statement_fragments_from(/^package[ \t]+(.+)$/)
    end

    # matches a regex against all source statements
    def statement_fragments_from(regex)
      statements.map do |statement|
        if statement =~ regex
          $1
        end
      end.select {|package| package != nil}.flatten.sort.uniq
    end
  end
end
