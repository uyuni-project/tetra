# encoding: UTF-8

module Gjp
  # checks kits for errors
  class KitChecker
    include Logging

    def initialize(project)
      @project = project
    end

    # returns an array of [path, archive] couples found in kit/
    # archive is not nil if path is inside a zip file
    def kit_file_paths
      @project.from_directory("kit") do
        plain_file_paths = Dir[File.join("**", "*")].select do |path|
          File.file?(path)
        end.map do |path|
          [path, nil]
        end

        archived_file_paths = plain_file_paths.select do |path, _archive|
          path. =~ (/\.(zip)|([jwe]ar)$/)
        end.map do |path, _archive|
          result = []
          Zip::File.foreach(path) do |entry|
            if entry.file?
              result << [entry.to_s, path]
            end
          end
          result
        end.flatten(1)

        plain_file_paths + archived_file_paths
      end
    end

    # returns a list of class names for which
    # we have source files in kit/
    def source_class_names(paths)
      source_paths = paths.select do |path, _archive|
        path =~ /\.java$/
      end

      # heuristically add all possible package names, walking
      # back the directory tree all the way back to root.
      # This could add non-existent names, but allows not looking
      # in the file at all
      class_names = source_paths.map do |path, _archive|
        class_name = path_to_class(path)
        parts = class_name.split(".")
        last_index = parts.length - 1
        (0..last_index).map do |i|
          parts[i..last_index].join(".")
        end
      end.flatten

      Set.new(class_names)
    end

    # returns a list of class names for which
    # we have binary files in kit/
    def compiled_classes(paths)
      result = {}
      compiled_paths = paths.select do |path, _archive|
        path =~ /\.class$/
      end.each do |path, archive|
        class_name = path_to_class(path)
        if result[archive].nil?
          result[archive] = [class_name]
        else
          result[archive] << class_name
        end
      end

      result
    end

    # returns a hash that associates archive names and
    # the unsourced classes within them
    def unsourced_archives
      paths = kit_file_paths
      source_class_names = source_class_names(paths)
      archive_paths_to_class_names = compiled_classes(paths)

      result = archive_paths_to_class_names.map do |archive, class_names|
        unsourced_class_names = class_names.select do |class_name|
          source_class_names.include?(class_name) == false
        end
        { archive: archive, class_names: class_names, unsourced_class_names: unsourced_class_names }
      end.select do |archive|
        archive[:unsourced_class_names].any?
      end
    end

    private

    # attempts to turn a .java/.class file name into a class name
    def path_to_class(path)
      path
        .gsub(/\$.+?\./, ".") # remove $InnerClasses
        .gsub(/\..+?$/, "") # remove .extension
        .gsub("/", ".") # convert paths in package names
    end
  end
end
