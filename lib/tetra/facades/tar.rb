# encoding: UTF-8

module Tetra
  # facade to tar
  class Tar
    include Logging
    include ProcessRunner

    def archive(name, source_dir, destination_dir)
      log.debug("creating #{destination_dir}")
      FileUtils.mkdir_p(destination_dir)

      destination_path = File.join(destination_dir, "#{name}.tar.xz")

      run("tar -cJf #{destination_path} -C #{source_dir} .")

      destination_path
    end
  end
end
