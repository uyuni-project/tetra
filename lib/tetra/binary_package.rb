# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency
  class BinaryPackage
    attr_reader :pom
    attr_reader :files

    attr_reader :group_id
    attr_reader :artifact_id
    attr_reader :version

    def initialize(pom, files)
      @pom = pom
      @files = files

      path, _ = Pathname.new(pom).split
      rest, @version = path.split
      group_directory, @artifact_id = rest.split
      @group_id = path_to_group(group_directory)
    end

    def path_to_group(path)
      splits = path.split
      if splits[0].to_s == "."
        return splits[1]
      else
        return "#{path_to_group(splits[0])}.#{splits[1]}"
      end
    end

    def eql?(binary_package)
      self.class.equal?(binary_package.class) &&
        pom == binary_package.pom &&
        files == binary_package.files
    end
  end
end
