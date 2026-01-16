# frozen_string_literal: true

module Tetra
  # implements common options and utility methods
  class Subcommand < Clamp::Command
    include Logging

    # Options available to all tetra commands
    option "--verbose", :flag, "verbose output"
    option "--very-verbose", :flag, "very verbose output"
    option "--very-very-verbose", :flag, "very very verbose output"

    # verbosity handlers
    def very_very_verbose=(flag)
      configure_log_level(verbose?, very_verbose?, flag)
    end

    def very_verbose=(flag)
      configure_log_level(verbose?, flag, very_very_verbose?)
    end

    def verbose=(flag)
      configure_log_level(flag, very_verbose?, very_very_verbose?)
    end

    # maps verbosity options to log level
    def configure_log_level(verbose, very_verbose, very_very_verbose)
      if very_very_verbose
        log.level = ::Logger::DEBUG
      elsif very_verbose
        log.level = ::Logger::INFO
      elsif verbose
        log.level = ::Logger::WARN
      else
        log.level = ::Logger::ERROR
      end
    end

    # override default option parsing to pass options to other commands
    def bypass_parsing(args)
      log.level = ::Logger::WARN if args.delete "--verbose"
      log.level = ::Logger::INFO if args.delete "--very-verbose"
      log.level = ::Logger::DEBUG if args.delete "--very-very-verbose"

      @options = args
    end

    # prints an error message and exits unless a dry-running
    # condition is met. Conditions can be: :is_in_progress, :is_not_in_progress
    # or :has_finished
    def ensure_dry_running(state, project)
      dry_running = project.dry_running?
      has_finished = !project.version.nil?

      condition_met = case state
                      when :is_in_progress
                        dry_running
                      when :is_not_in_progress
                        !dry_running
                      when :has_finished
                        !dry_running && has_finished
                      end

      if condition_met
        yield
      else
        handle_dry_run_error(state, dry_running, has_finished)
      end
    end

    # outputs output of a file generation
    def print_generation_result(project, result_path, conflict_count = 0)
      puts "#{format_path(result_path, project)} generated"
      puts "Warning: #{conflict_count} unresolved conflicts, please review and commit" if conflict_count.positive?
    end

    # generates a version of path relative to the current directory
    def format_path(path, project)
      path_obj = Pathname.new(path)
      full_path = if path_obj.relative?
                    File.join(project.full_path, path)
                  else
                    path
                  end
      Pathname.new(full_path).relative_path_from(Pathname.new(Dir.pwd))
    end

    # handles most fatal exceptions
    def checking_exceptions
      yield
    rescue Errno::EACCES, Errno::ENOENT, Errno::EEXIST => e
      $stderr.puts e
    rescue Tetra::NoProjectDirectoryError => e
      $stderr.puts "#{e.directory} is not a tetra project directory, see \"tetra init\""
    rescue Tetra::GitAlreadyInitedError
      $stderr.puts "This directory is already a tetra project"
    rescue Tetra::ExecutionFailed => e
      $stderr.puts "Failed to run `#{e.commandline}` (exit status #{e.status})"
    rescue Interrupt
      $stderr.puts "Execution interrupted by the user"
    end

    private

    def handle_dry_run_error(state, dry_running, has_finished)
      if (state == :is_in_progress) || (state == :has_finished && !dry_running && !has_finished)
        puts "Please start a dry-run first, use \"tetra dry-run\""
      elsif (state == :is_not_in_progress) || (state == :has_finished && dry_running)
        puts "There is a dry-run in progress, please finish it (^D) or abort it (^C^D)"
      end
    end
  end
end
