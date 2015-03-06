# encoding: UTF-8

module Tetra
  # runs Bash with tetra-specific options
  class Bash
    include ProcessRunner

    # runs bash in a subshell, returns list of
    # commands that were run in the session
    def bash
      Tempfile.open("tetra-history") do |temp_file|
        temp_path = temp_file.path

        env = {
          "HISTFILE" => temp_path,   # use temporary file for history
          "HISTFILESIZE" => "-1", # don't limit file size
          "HISTSIZE" => "-1", # don't limit history size
          "HISTTIMEFORMAT" => nil, # don't keep timestamps
          "HISTCONTROL" => "", # don't skip any command
          "PS1" => "\e[1;33mdry-running\e[m:\\\w\$ " # change prompt
        }

        run_interactive("bash --norc", env)
        File.read(temp_path).split("\n").map(&:strip)
      end
    end
  end
end
