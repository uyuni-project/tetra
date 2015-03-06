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
        ] + script_body(project)

        new_content = script_lines.join("\n") + "\n"

        result_dir = File.join(project.packages_dir, project.name)
        FileUtils.mkdir_p(result_dir)
        result_path = File.join(result_dir, "build.sh")
        conflict_count = project.merge_new_content(new_content, result_path, "Build script generated",
                                                   "script")

        [result_path, conflict_count]
      end
    end

    # returns the script body by taking the last dry-run's
    # build script lines and adjusting mvn and ant's paths
    def script_body(project)
      lines = project.build_script_lines
      ant = if lines.any? { |e| e.match(/tetra +ant/) }
              path = Tetra::Kit.new(project).find_executable("ant")
              Tetra::Ant.new(project.full_path, path).ant(@options)
            end

      mvn = if lines.any? { |e| e.match(/tetra +mvn/) }
              mvn_path = Tetra::Kit.new(project).find_executable("mvn")
              mvn = Tetra::Mvn.new("$PROJECT_PREFIX", mvn_path)
            end

      lines.map do |line|
        if line =~ /tetra +mvn/
          line.gsub(/tetra +mvn/, "#{mvn.get_mvn_commandline(['-o'])}")
        elsif line =~ /tetra +ant/
          line.gsub(/tetra +ant/, "#{ant.get_ant_commandline([])}")
        else
          line
        end
      end
    end
  end
end
