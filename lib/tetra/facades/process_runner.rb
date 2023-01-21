# frozen_string_literal: true

module Tetra
  # runs programs in subprocesses
  module ProcessRunner
    include Logging

    # runs a noninteractive executable and returns its output as a string
    # raises ExecutionFailed if the exit status is not 0
    # optionally echoes the executable's output/error to standard output/error
    def run(commandline, echo = false, stdin = nil)
      log.debug "running `#{commandline}`"

      out_recorder = echo ? RecordingIO.new($stdout) : RecordingIO.new
      err_recorder = echo ? RecordingIO.new($stderr) : RecordingIO.new

      status = Open4.spawn(commandline, stdin:, stdout: out_recorder,
                                        stderr: err_recorder, quiet: true).exitstatus

      log.debug "`#{commandline}` exited with status #{status}"

      if status != 0
        log.warn("`#{commandline}` failed with status #{status}")
        out = out_recorder.record
        err = err_recorder.record
        if out != "" || err != ""
          log.warn("Output follows:")
          log.warn(out) unless out == ""
          log.warn(err) unless err == ""
        end
        raise ExecutionFailed.new(commandline, status, out, err)
      end

      out_recorder.record
    end

    # runs an interactive executable in a subshell
    def run_interactive(command)
      log.debug "running `#{command}`"
      success = system({}, command)
      log.debug "`#{command}` exited with success #{success}"
      raise ExecutionFailed.new(command, $CHILD_STATUS, nil, nil) unless success
    end

    # records bytes sent via "<<" for later use
    # optionally echoes to another IO object
    class RecordingIO
      attr_reader :record

      def initialize(io = nil)
        @io = io
        @record = ""
      end

      def <<(*args)
        if @io
          @io.<<(*args)
          @io.flush
        end
        @record.<<(*args)
      end
    end
  end

  # raised when a command returns a non-zero status
  class ExecutionFailed < StandardError
    attr_reader :commandline, :status, :out, :err

    def initialize(commandline, status, out, err)
      @commandline = commandline
      @status = status
      @out = out
      @err = err
    end

    def to_s
      "\"#{@commandline}\" failed with status #{@status}\n#{out}\n#{err}"
    end
  end
end
