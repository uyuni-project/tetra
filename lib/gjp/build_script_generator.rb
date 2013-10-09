# encoding: UTF-8

module Gjp
  # generates build scripts from bash_history
  class BuildScriptGenerator
    include Logger

    def initialize(project, history_path)
      @project = project
      @maven_runner = Gjp::MavenRunner.new(project)
      @history_path = history_path
    end
    
    def generate_build_script(name)
      @project.from_directory do
        history_lines = File.readlines(@history_path).map { |e| e.strip }
        relevant_lines =
          history_lines
            .reverse
            .take_while { |e| e.match(/gjp +dry-run/) == nil }
            .reverse
            .take_while { |e| e.match(/gjp +finish/) == nil }
            .select { |e| e.match(/^#/) == nil }

        script_lines = [
          "#!/bin/bash",
          "PROJECT_PREFIX=`readlink -e .`",
          "cd #{@project.latest_dry_run_directory}"
        ] +
        relevant_lines.map do |line|
          if line =~ /gjp +mvn/
            line.gsub(/gjp +mvn/, "#{@maven_runner.get_maven_commandline("$PROJECT_PREFIX")}")
          else
            line
          end
        end

        new_content = script_lines.join("\n") + "\n"

        result_path = File.join("src", name, "build.sh")
        conflict_count = @project.merge_new_content(new_content, result_path, "Build script generated", "generate_#{name}_build_script")
        [result_path, conflict_count]
      end
    end
  end
end
