# encoding: UTF-8

module Tetra
  # encapsulates tetra-specific Maven commandline options
  class Mvn
    # returns a command line for running Maven
    def self.commandline(project_path, mvn_path)
      full_path = if mvn_path
                    File.join(project_path, mvn_path, "mvn")
                  else
                    "mvn"  # use system-provided executable
                  end
      repo_path = File.join(project_path, "kit", "m2")
      config_path = File.join(project_path, "kit", "m2", "settings.xml")

      options = [
        "-Dmaven.repo.local=#{repo_path}",
        "--settings #{config_path}",
        "--strict-checksums"
      ]

      "#{full_path} #{options.join(' ')}"
    end
  end
end
