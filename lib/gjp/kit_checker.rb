# encoding: UTF-8

require "find"

module Gjp
  # checks kits for errors
  class KitChecker
    include Logger

    def initialize(project)      
      @project = project
    end

    # yields a block for each file in kit, including those in archives
    # block parameters are archive path or nil and entry path
    def each_path
      @project.from_directory("kit") do
        Dir[File.join("**", "*")].select do |path|
          File.file?(path)
        end.map do |path|
          yield [nil, path]
          if path =~ /\.(zip)|([jwe]ar)$/
            Zip::ZipFile.foreach(path) do |entry|
              if entry.file?
                yield [path, entry.to_s]
              end
            end
          end
        end
      end
    end

    # returns:
    #   a hash that associates jars with compiled classes in them
    #   a hash that associates jars with source classes in them
    def get_classes
      jars_to_classes = {}
      jars_to_sources = {}
      each_path do |archive, path|
        if path =~ /\.class$/
          add_class(archive, path, jars_to_classes)
        elsif path =~ /\.java$/
          add_class(archive, path, jars_to_sources)
        end
      end

      [jars_to_classes, jars_to_sources]
    end

    def get_unsourced
      jars_to_classes, jars_to_sources = get_classes
      sources = jars_to_sources.values.flatten

      jars_to_classes.select do |archive, class_names|
        class_names.any? do |class_name|
          not sources.any? { |source| source.end_with?(class_name) }
        end
      end.map { |archive, class_names| archive }
    end

    private
    # attempts to turn a .java/.class file name into a class name
    def path_to_class(path)
      path.gsub(/$.+?\.$/, "").gsub(/\..+?$/, "").gsub("/", ".")
    end

    # adds path to hash as per get_classes signature
    def add_class(archive, path, hash)
      class_name = path_to_class(path)
      existing_paths = hash[archive]
      if !existing_paths
        hash[archive] = [class_name]
      else
        existing_paths << class_name
      end
    end
  end
end
