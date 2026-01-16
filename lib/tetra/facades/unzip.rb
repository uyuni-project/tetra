# frozen_string_literal: true
module Tetra
  # encapsulates unzip
  class Unzip
    include ProcessRunner

    # decompresses a file in a target directory
    def decompress(zipfile, directory)
      # Use Array execution to prevent shell injection
      result = run(["unzip", zipfile, "-d", directory])

      result&.strip
    end
  end
end
