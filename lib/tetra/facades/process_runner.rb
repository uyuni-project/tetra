# frozen_string_literal: true

module Tetra
  # runs programs in subprocesses
  module ProcessRunner
    include Logging

    # runs a noninteractive executable and returns its output as a string
    # raises ExecutionFailed if the exit status is not 0
    # optionally echoes the executable's output/error to standard output/error
    def run(commandline, echo = false, stdin_data = nil)
      log.debug "running `#{commandline}`"

      # Prepare buffers to capture output
      out_buffer = StringIO.new
      err_buffer = StringIO.new
      exit_status = nil
      # Flatten handles nested arrays, Compact removes nils
      cmd_args = Array(commandline).flatten.compact.map(&:to_s)

      Open3.popen3(*cmd_args) do |stdin, stdout, stderr, wait_thr|
        # 1. Handle Input (if any)
        stdin.write(stdin_data) if stdin_data
        stdin.close # Close stdin so the process knows input is finished

        # Use threads to read stdout and stderr simultaneously.
        readers = []

        readers << Thread.new do
          stdout.each_line do |line|
            print line if echo       # Echo to real STDOUT if requested
            out_buffer << line       # Capture to memory
          end
        end

        readers << Thread.new do
          stderr.each_line do |line|
            $stderr.print line if echo # Echo to real STDERR if requested
            err_buffer << line         # Capture to memory
          end
        end

        # Wait for reading to finish
        readers.each(&:join)

        # Get the exit code
        exit_status = wait_thr.value
      end

      # Check for failure
      unless exit_status.success?
        # Extract strings from buffers
        out = out_buffer.string
        err = err_buffer.string

        log.warn("`#{commandline}` failed with status #{exit_status.exitstatus}")

        if !out.empty? || !err.empty?
          log.warn("Output follows:")
          log.warn(out) unless out.empty?
          log.warn(err) unless err.empty?
        end

        fail ExecutionFailed.new(commandline, exit_status.exitstatus, out, err)
      end

      # Return the standard output
      out_buffer.string
    end

    # runs an interactive executable in a subshell
    def run_interactive(command)
      log.debug "running interactive `#{command}`"

      # system() passes control to the subprocess
      cmd_args = Array(command).flatten.compact.map(&:to_s)
      success = system(*cmd_args)

      log.debug "`#{command}` exited with success #{success}"

      fail ExecutionFailed.new(command, $CHILD_STATUS.exitstatus, nil, nil) unless success
    end
  end

  # raised when a command returns a non-zero status
  class ExecutionFailed < StandardError
    attr_reader :commandline
    attr_reader :status
    attr_reader :out
    attr_reader :err

    def initialize(commandline, status, out, err)
      @commandline = commandline
      @status = status
      @out = out
      @err = err
      super("Command failed: #{commandline} (status: #{status})")
    end

    def to_s
      "\"#{@commandline}\" failed with status #{@status}\n#{out}\n#{err}"
    end
  end
end
