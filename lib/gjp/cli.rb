# encoding: UTF-8
require "gjp/logger"
require "clamp"

module Gjp
  class MainCommand < Clamp::Command
    include Logger

    # Common logging options
    option ["-v", "--verbose"], :flag, "verbose output"
    option ["--very-verbose"], :flag, "very verbose output"
    option ["--very-very-verbose"], :flag, "very very verbose output"

    def very_very_verbose=(flag)
      configure_log_level(verbose?, very_verbose?, flag)
    end
    
    def very_verbose=(flag)
      configure_log_level(verbose?, flag, very_very_verbose?)
    end
    
    def verbose=(flag)
      configure_log_level(flag, very_verbose?, very_very_verbose?)
    end

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

    # Subcommands
    subcommand "init", "Inits a gjp project in the current directory" do
      def execute
        checking_exceptions do
          Gjp::Project.init(".")
          puts "Project inited."
          puts "Add sources to src/<package name>, binary dependencies to kit/."
          puts "When you are ready to test a build, use \"gjp dry-run\"."
        end
      end
    end

    subcommand "dry-run", "Starts a dry-run build" do
      def execute
        checking_exceptions do
          if Gjp::Project.new(".").dry_run
            puts "Now dry-running, please start your build."
            puts "To run a Maven installation from the kit, use \"gjp mvn\"."
            puts "If the build succeedes end this dry run with \"gjp finish\"."
            puts "If the build does not succeed use \"gjp finish --abort\" to restore files."
          end
        end
      end
    end

    subcommand "mvn", "Locates and runs Maven from any directory in kit/" do
      parameter "[MAVEN OPTIONS] ...", "mvn options", :attribute_name => "dummy"

      # override parsing in order to pipe everything to mvn
      def parse(args)
        @options = args
      end

      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          Gjp::KitRunner.new(project).mvn(@options)
        end
      end
    end

    subcommand "ant", "Locates and runs Ant from any directory in kit/" do
      parameter "[ANT OPTIONS] ...", "ant options", :attribute_name => "dummy"

      # override parsing in order to pipe everything to mvn
      def parse(args)
        @options = args
      end

      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          Gjp::KitRunner.new(project).ant(@options)
        end
      end
    end

    subcommand "finish", "Ends the current dry-run" do
      option ["-f", "--abort"], :flag, "build abort, restore files as before dry-run"
      def execute
        checking_exceptions do
          if Gjp::Project.new(".").finish(abort?)
            if abort?
              puts "Project reverted as before dry-run."
            else
              puts "Dry-run finished."
            end
          else
            puts "No dry-run is in progress."
          end
        end
      end
    end

    subcommand "generate-kit-archive", "Create or refresh the kit tarball" do
      option ["-i", "--incremental"], :flag, "create an archive with only the difference from the previous one", :default => true
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          result_path = Gjp::Archiver.new(project).archive_kit(incremental?)
          print_generation_result(project, result_path)
        end
      end
    end

    subcommand "generate-kit-spec", "Create or refresh a spec file for the kit" do
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end

    subcommand "generate-package-script", "Create or refresh a build.sh file for a package" do
      parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          package_name = project.get_package_name(directory)
          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Gjp::ScriptGenerator.new(project, history_file).generate_build_script(package_name)
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end

    subcommand "generate-package-archive", "Create or refresh a package tarball" do
      parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          package_name = project.get_package_name(directory)
          result_path = Gjp::Archiver.new(project).archive_package package_name
          print_generation_result(project, result_path)
        end
      end
    end

    subcommand "generate-package-spec", "Create or refresh a spec file for a package" do
      option ["-f", "--filter"], "FILTER", "filter files to be installed by this spec", :default => "*.jar"
      parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."
      parameter "[POM]", "a pom file path", :default => "pom.xml"
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          package_name = project.get_package_name(directory)
          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_package_spec package_name, pom, filter
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end

    subcommand "generate-all", "Create or refresh specs, archives, scripts for a package and the kit" do
      option ["-f", "--filter"], "FILTER", "filter files to be installed by this package spec", :default => "*.jar"
      option ["-i", "--incremental"], :flag, "create a kit archive with only the difference from the previous one", :default => true
      parameter "[DIRECTORY]", "path to a package directory (src/<package name>)", :default => "."
      parameter "[POM]", "a package pom file path", :default => "pom.xml"
      def execute
        checking_exceptions do
          project = Gjp::Project.new(".")
          package_name = project.get_package_name(directory)

          result_path = Gjp::Archiver.new(project).archive_kit(incremental?)
          print_generation_result(project, result_path)

          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_kit_spec
          print_generation_result(project, result_path, conflict_count)

          history_file = File.join(Dir.home, ".bash_history")
          result_path, conflict_count = Gjp::ScriptGenerator.new(project, history_file).generate_build_script(package_name)
          print_generation_result(project, result_path, conflict_count)

          result_path = Gjp::Archiver.new(project).archive_package package_name
          print_generation_result(project, result_path)

          result_path, conflict_count = Gjp::SpecGenerator.new(project).generate_package_spec package_name, pom, filter
          print_generation_result(project, result_path, conflict_count)
        end
      end
    end

    subcommand "purge-jars", "Locates jars in src/ and moves them to kit/" do
      def execute
        Gjp::Project.new(".").purge_jars.each do |original, final|
          puts "Replaced #{original} with symlink pointing to to #{final}"
        end
      end
    end

    subcommand "set-up-nonet-user", "Sets up a \"nonet\" user that cannot access the network" do
      def execute
        checking_exceptions do
          user = Gjp::LimitedNetworkUser.new("nonet")
          user.set_up

          "sudo #{user.get_path("useradd")} nonet\n" +
          "sudo #{user.get_path("iptables")} -A OUTPUT -m owner --uid-owner nonet -j DROP\n" +
          "User \"nonet\" set up, you can use \"sudo nonet\" to dry-run your build with no network access.\n" +
          "Note that the above iptables rule will be cleared at next reboot, you can use your distribution " +
          "tools to make it persistent or run \"gjp set-up-limited-nertwork-user\" again next time."
        end
      end
    end

    subcommand "tear-down-nonet-user", "Deletes a user previously created by gjp" do
      def execute
        checking_exceptions do
          user = Gjp::LimitedNetworkUser.new("nonet")

          user.tear_down

          "sudo #{user.get_path("iptables")} -D OUTPUT -m owner --uid-owner nonet -j DROP\n" +
          "sudo #{user.get_path("userdel")} nonet\n"
        end
      end
    end

    subcommand "get-pom", "Retrieves a pom corresponding to a filename" do
      parameter "NAME", "a jar file path, a project directory path or a non-existing filename in the `project-version` form"
      def execute
          checking_exceptions do
          puts Gjp::PomGetter.new.get_pom(name)
        end
      end
    end

    subcommand "get-parent-pom", "Retrieves a pom that is the parent of an existing pom" do
      parameter "POM", "a pom file path or URI"
      def execute
          checking_exceptions do
          puts Gjp::ParentPomGetter.new.get_parent_pom(pom)
        end
      end
    end
      
    subcommand "get-source-address", "Retrieves a project's SCM Internet address" do
      parameter "POM", "a pom file path or URI"

      def execute
        checking_exceptions do
          puts Gjp::SourceAddressGetter.new.get_source_address(pom)
        end
      end
    end
    
    subcommand "get-source", "Retrieves a project's source code directory" do
      parameter "ADDRESS", "project's SCM Internet address"
      parameter "POM", "project's pom file path or URI"
      parameter "[DIRECTORY]", "directory in which to save the source code", :default => "."

      def execute
        checking_exceptions do
          puts Gjp::SourceGetter.new.get_source(address, pom, directory)
        end    
      end    
    end

    private

    # outputs output of a file generation
    def print_generation_result(project, result_path, conflict_count = 0)
      puts "#{format_path(result_path, project)} generated"
      if conflict_count > 0
        puts "Warning: #{conflict_count} unresolved conflicts"
      end
    end

    # generates a version of path relative to the current directory
    def format_path(path, project)
      full_path = if Pathname.new(path).relative?
        File.join(project.full_path, path)
      else
        path
      end
      Pathname.new(full_path).relative_path_from(Pathname.new(Dir.pwd))
    end

    # handles most fatal exceptions
    def checking_exceptions
      begin
        yield
      rescue Errno::EACCES => e
        $stderr.puts e
      rescue Errno::ENOENT => e
        $stderr.puts e
      rescue Errno::EEXIST => e
        $stderr.puts e
      rescue NoProjectDirectoryError => e
        $stderr.puts "#{e.directory} not a gjp project directory, see gjp init"
      rescue NoPackageDirectoryException => e
        $stderr.puts "#{e.directory} is not a gjp package directory, see README"
      rescue GitAlreadyInitedError => e
        $stderr.puts "This directory is already a gjp project"
      rescue ExecutableNotFoundError => e
        $stderr.puts "Executable #{e.executable} not found in kit/ or any of its subdirectories"
      end
    end
  end
end
