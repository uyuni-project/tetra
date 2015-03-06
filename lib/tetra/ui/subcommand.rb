# encoding: UTF-8

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
    def configure_log_level(v, vv, vvv)
      if vvv
        log.level = ::Logger::DEBUG
      elsif vv
        log.level = ::Logger::INFO
      elsif v
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

      if (state == :is_in_progress && dry_running) ||
         (state == :is_not_in_progress && !dry_running) ||
         (state == :has_finished && !dry_running && has_finished)
        yield
      else
        if (state == :is_in_progress) ||
           (state == :has_finished && !dry_running && !has_finished)
          puts "Please start a dry-run first, use \"tetra dry-run\""
        elsif (state == :is_not_in_progress) ||
              (state == :has_finished && dry_running)
          puts "There is a dry-run in progress, please finish it (^D) or abort it (^C^D)"
        end
      end
    end

    # outputs output of a file generation
    def print_generation_result(project, result_path, conflict_count = 0)
      puts "#{format_path(result_path, project)} generated"
      puts "Warning: #{conflict_count} unresolved conflicts, please review and commit" if conflict_count > 0
    end

    # generates a version of path relative to the current directory
    def format_path(path, project)
      full_path = (
        if Pathname.new(path).relative?
          File.join(project.full_path, path)
        else
          path
        end
      )
      Pathname.new(full_path).relative_path_from(Pathname.new(Dir.pwd))
    end

    # handles most fatal exceptions
    def checking_exceptions
      yield
    rescue Errno::EACCES => e
      $stderr.puts e
    rescue Errno::ENOENT => e
      $stderr.puts e
    rescue Errno::EEXIST => e
      $stderr.puts e
    rescue NoProjectDirectoryError => e
      $stderr.puts "#{e.directory} is not a tetra project directory, see tetra init"
    rescue GitAlreadyInitedError
      $stderr.puts "This directory is already a tetra project"
    rescue ExecutableNotFoundError => e
      $stderr.puts "Executable #{e.executable} not found in kit/ or any of its subdirectories"
    rescue ExecutionFailed => e
      $stderr.puts "Failed to run `#{e.commandline}` (exit status #{e.status})"
    rescue Interrupt
      $stderr.puts "Execution interrupted by the user"
    end
  end
end
