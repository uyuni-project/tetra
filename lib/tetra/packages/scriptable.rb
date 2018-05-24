# encoding: UTF-8

module Tetra
  # generates a package build script from bash_history
  module Scriptable
    # returns a build script for this package
    def _to_script(project)
      project.from_directory do
        script_lines = [
          "#!/bin/bash",
          "set -xe",
          "PROJECT_PREFIX=`readlink -e .`",
          "cd #{project.latest_dry_run_directory}"
        ] + aliases(project) + project.build_script_lines

        new_content = script_lines.join("\n") + "\n"

        result_dir = File.join(project.packages_dir, project.name)
        FileUtils.mkdir_p(result_dir)
        result_path = File.join(result_dir, "build.sh")
        conflict_count = project.merge_new_content(new_content, result_path, "Build script generated",
                                                   "script")

        [result_path, conflict_count]
      end
    end

    # setup aliases for adjusted versions of the packaging tools
    def aliases(project)
      kit = Tetra::Kit.new(project)

      aliases = []
      ant_path = kit.find_executable("ant")
      ant_commandline = Tetra::Ant.commandline("$PROJECT_PREFIX", ant_path)
      aliases << "alias ant='#{ant_commandline}'"

      mvn_path = kit.find_executable("mvn")
      mvn_commandline = Tetra::Mvn.commandline("$PROJECT_PREFIX", mvn_path)
      aliases << "alias mvn='#{mvn_commandline} -o'"

      aliases
    end
  end
end
