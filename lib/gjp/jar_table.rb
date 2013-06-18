# encoding: UTF-8

require "text"

module Gjp
  # encapsulates information of a project's jar files
  # assumes the project is in a directory with jar files
  # in its (possibly nested) subdirectories
  class JarTable
    def log
      Gjp.logger
    end

    attr_reader :rows, :runtime_required_packages, :source_defined_packages

    # builds a JarTable from a directory (paths relative to the current directory)
    def initialize(dir)

      jars = get_jars(dir)
      sources = get_sources(dir)
      statements = get_statements(sources)
      @runtime_required_packages = get_runtime_required_packages(statements)
      @source_defined_packages = get_source_defined_packages(statements)
      log.debug "Source defined packages are:\n#{@source_defined_packages.join("\n")}"

      @rows = Hash[
        jars.map do |jar|
          [jar, get_type(jar)]
        end
      ]
    end

    def to_s
      "# Legend: "
      "#b - jar is required for building the project"
      "#r - jar is required runtime by the project"
      "#p - jar is produced by the project"
      @rows.map do |key, value|
        "#{value.to_s[0]} #{key}"
      end.sort
    end

    # jar files in the project's directory
    def get_jars(dir)
      Dir["#{dir}/**/*.jar"]
    end

    # java source files in the project's directory
    def get_sources(dir)
      Dir["#{dir}/**/*.java"]
    end

    # java statements in java source files
    def get_statements(sources)
      sources.map do |source|
        File.readlines(source)
          .map { |line| line.split(";")  }
          .flatten
          .map { |statement| statement.strip }
      end.flatten
    end

    # heuristically determined package names that the sources require
    def get_runtime_required_packages(statements)
      get_statement_fragments_from(statements, /^import[ \t]+(?:static[ \t]+)?(.+)\..+?$/)
    end

    # heuristically determined package names that the sources define
    def get_source_defined_packages(statements)
      get_statement_fragments_from(statements, /^package[ \t]+(.+)$/)
    end

    # matches a regex against all source statements
    def get_statement_fragments_from(statements, regex)
      statements.map do |statement|
        if statement =~ regex
          $1
        end
      end.select {|package| package != nil}.flatten.sort.uniq
    end


    # returns :produced if the jar was produced from the project's sources, and
    # :required or :build_required if it is needed at runtime or build time
    # (heuristically)
    def get_type(jar)
      jar_defined_packages = get_jar_defined_packages(jar)

      if source_defined?(jar, jar_defined_packages)
        :produced
      elsif runtime_required?(jar, jar_defined_packages)
        :required
      else
        :build_required        
      end
    end

    # returns true if a jar is produced from source code in the project's directory
    def source_defined?(jar, jar_defined_packages)
      jar_defined_packages.all? { |package| @source_defined_packages.include?(package)  }
    end

    # returns true if a jar is required runtime, false if it is only needed
    # at compile time. Current implementation is heuristic (looks for "import" statements
    # in java code)
    def runtime_required?(jar, jar_defined_packages)
      jar_defined_packages.any? { |package| @runtime_required_packages.include?(package)  }
    end

    # returns packages defined in a jar file
    def get_jar_defined_packages(jar)
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
  end
end
