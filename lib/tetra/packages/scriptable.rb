# encoding: UTF-8

module Tetra
  # generates a package build script from bash_history
  module Scriptable
    # returns a build script for this package
    def _to_script(project, history_path)
      project.from_directory do
        history_lines = File.readlines(history_path).map(&:strip)
        relevant_lines =
          history_lines
          .reverse
          .take_while { |e| e.match(/tetra +dry-run +start/).nil? }
          .reverse
          .take_while { |e| e.match(/tetra +dry-run +finish/).nil? }
          .select { |e| e.match(/^#/).nil? }

        script_lines = [
          "#!/bin/bash",
          "set -xe",
          "PROJECT_PREFIX=`readlink -e .`",
          "cd #{project.latest_dry_run_directory}"
        ] + script_body(project, relevant_lines)

        new_content = script_lines.join("\n") + "\n"

        result_dir = File.join(project.packages_dir, project.name)
        FileUtils.mkdir_p(result_dir)
        result_path = File.join(result_dir, "build.sh")
        conflict_count = project.merge_new_content(new_content, result_path, "Build script generated",
                                                   "generate_build_script")

        [result_path, conflict_count]
      end
    end

    # returns the script body
    def script_body(project, relevant_lines)
      ant = if relevant_lines.any? { |e| e.match(/tetra +ant/) }
              path = Tetra::Kit.new(project).find_executable("ant")
              Tetra::Ant.new(project.full_path, path).ant(@options)
            end

      mvn = if relevant_lines.any? { |e| e.match(/tetra +mvn/) }
              mvn_path = Tetra::Kit.new(project).find_executable("mvn")
              mvn = Tetra::Mvn.new("$PROJECT_PREFIX", mvn_path)
            end

      relevant_lines.map do |line|
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
