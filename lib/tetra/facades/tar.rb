# encoding: UTF-8

module Tetra
  # facade to tar
  class Tar
    include Logging

    def archive(name, source_dir, destination_dir)
      log.debug("creating #{destination_dir}")
      FileUtils.mkdir_p(destination_dir)

      destination_path = File.join(destination_dir, "#{name}.tar.xz")
      log.debug("tarring to #{destination_path}")

      `tar -cJf #{destination_path} -C #{source_dir} .`

      destination_path
    end
  end
end
