# frozen_string_literal: true
module Tetra
  # runs Bash with tetra-specific options
  class Bash
    include Logging
    include ProcessRunner

    def initialize(project)
      @project = project
    end

    # runs bash in a subshell, returns list of
    # commands that were run in the session
    def bash(command = nil)
      Tempfile.open("tetra-history") do |history_file|
        Tempfile.open("tetra-bashrc") do |bashrc_file|
          kit = Tetra::Kit.new(@project)

          ant_path = kit.find_executable("ant")
          ant_commandline = Tetra::Ant.commandline(@project.full_path, ant_path)

          mvn_path = kit.find_executable("mvn")
          mvn_commandline = Tetra::Mvn.commandline(@project.full_path, mvn_path)

          gradle_commandline = Tetra::Gradle.commandline(@project.full_path)

          bashrc_content = Bashrc.new(
            history_file: history_file.path,
            ant_in_kit: !ant_path.nil?,
            ant_commandline: ant_commandline,
            mvn_in_kit: !mvn_path.nil?,
            mvn_commandline: mvn_commandline,
            gradle_commandline: gradle_commandline
          ).to_s

          log.debug("writing bashrc file: #{bashrc_file.path}")
          log.debug(bashrc_content)

          bashrc_file.write(bashrc_content)
          bashrc_file.flush

          if command
            # SECURITY: Use array execution to prevent shell injection via 'command'
            # The 'bash -c' flag normally takes a single string, so we must be careful.
            # Ideally, passing it as a single array element ["bash", ..., "-c", command]
            # is handled safely by ProcessRunner if it uses exec/system/spawn.
            run(["bash", "--rcfile", bashrc_file.path, "-i", "-c", command])
            [command]
          else
            # Interactive mode
            run_interactive(["bash", "--rcfile", bashrc_file.path, "-i"])

            history = File.read(history_file)
            log.debug("history contents:")
            log.debug(history)

            history.split("\n").map(&:strip)
          end
        end
      end
    end
  end

  # encapsulates variables in bashrc template
  class Bashrc
    include Tetra::Generatable

    # Expose attributes for the ERB binding
    attr_reader :history_file, :ant_in_kit, :ant_commandline,
                :mvn_in_kit, :mvn_commandline, :gradle_commandline

    def initialize(history_file:, ant_in_kit:, ant_commandline:,
                   mvn_in_kit:, mvn_commandline:, gradle_commandline:)
      @history_file = history_file
      @ant_in_kit = ant_in_kit
      @ant_commandline = ant_commandline
      @mvn_in_kit = mvn_in_kit
      @mvn_commandline = mvn_commandline
      @gradle_commandline = gradle_commandline
    end

    def to_s
      generate("bashrc", binding)
    end
  end
end
