# encoding: UTF-8

module Tetra
  # generates a package build script from bash_history
  module Scriptable
    def _to_script(project, history_path)
      ant_runner = Tetra::AntRunner.new(project)
      maven_runner = Tetra::MavenRunner.new(project)

      project.from_directory do
        history_lines = File.readlines(history_path).map(&:strip)
        relevant_lines =
          history_lines
          .reverse
          .take_while { |e| e.match(/tetra +dry-run/).nil? }
          .reverse
          .take_while { |e| e.match(/tetra +finish/).nil? }
          .select { |e| e.match(/^#/).nil? }

        script_lines = [
          "#!/bin/bash",
          "set -xe",
          "PROJECT_PREFIX=`readlink -e .`",
          "cd #{project.latest_dry_run_directory}"
        ] +
                       relevant_lines.map do |line|
                         if line =~ /tetra +mvn/
                           line.gsub(/tetra +mvn/, "#{maven_runner.get_maven_commandline('$PROJECT_PREFIX', ['-o'])}")
                         elsif line =~ /tetra +ant/
                           line.gsub(/tetra +ant/, "#{ant_runner.get_ant_commandline('$PROJECT_PREFIX')}")
                         else
                           line
                         end
                       end

        new_content = script_lines.join("\n") + "\n"

        result_dir = File.join(project.packages_dir, project.name)
        FileUtils.mkdir_p(result_dir)
        result_path = File.join(result_dir, "build.sh")
        conflict_count = project.merge_new_content(new_content, result_path, "Build script generated",
                                                   "generate_build_script")

        [result_path, conflict_count]
      end
    end
  end
end
