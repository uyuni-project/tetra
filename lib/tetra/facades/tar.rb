# encoding: UTF-8

module Tetra
  # encapsulates tar
  class Tar
    include ProcessRunner

    # decompresses a file in a target directory
    def decompress(tarfile, directory)
      result = run("tar xvf #{tarfile} --directory #{directory}")
      result.strip if result != ""
    end
  end
end
