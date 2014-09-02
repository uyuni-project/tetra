# encoding: UTF-8

module Tetra
  # represents a prebuilt package dependency from a jar file
  # in a kit
  class JarKitItem
    def initialize(path)
      _, @name = Pathname.new(path).split
      @checksum = Digest::SHA1.file(path).hexdigest
    end

    def provides_symbol
      "jar(#{@name})"
    end

    def provides_version
      @checksum
    end

    def eql?(maven_kit_item)
      self.class.equal?(maven_kit_item.class) &&
        pom == maven_kit_item.pom &&
        files == maven_kit_item.files
    end
  end
end
