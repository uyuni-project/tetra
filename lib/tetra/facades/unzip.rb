# encoding: UTF-8

module Tetra
  # encapsulates unzip
  class Unzip
    include ProcessRunner

    # decompresses a file in a target directory
    def decompress(zipfile, directory)
      result = run("unzip #{zipfile} -d #{directory}")
      result.strip if result != ""
    end
  end
end
