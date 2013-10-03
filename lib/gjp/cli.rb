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
        Gjp::Project.init(".")
        puts "Project inited, now gathering."
        explain_gathering
      end
    end

    subcommand "gather", "Starts a gathering phase, to add source and kit files" do
      def execute
        if Gjp::Project.new(".").gather
          puts "Now gathering."
          explain_gathering
        end
      end
    end

    def explain_gathering
      puts "Any file added to kit/ will be added to the kit package."
      puts "Any file added to src/<name> will be added to the corresponding package."
      puts "When you are ready to test a build, use \"gjp dry-run\"."
    end

    subcommand "dry-run", "Starts a dry-run phase, to attempt a build" do
      def execute
        if Gjp::Project.new(".").dry_run
          puts "Now dry-running, please start your build."
          puts "Any file added to kit/, presumably downloaded dependencies, will be added to the kit."
          puts "The src/ directory and all files in it will be brought back to the current state when finished."
          puts "Note that .gitignore files are honored!"
          puts "To run a Maven from the kit, use \"gjp mvn\"."
          puts "To add or remove files, use \"gjp gather\"."
          puts "To finalize this dry run, use \"gjp finish\"."
        end
      end
    end

    subcommand "mvn", "Locates and runs Maven from any directory in kit/" do
      parameter "[MAVEN OPTIONS] ...", "mvn options", :attribute_name => "dummy"

      # override parsing in order to pipe everything to mvn
      def parse(args)
        @maven_options = args
      end

      def execute
        begin
          project = Gjp::Project.new(".")
          result = Gjp::MavenRunner.new(project).mvn(@maven_options)
          puts "Real commandline was:"
          puts "#{result}"
        rescue Gjp::MavenNotFoundException
          puts "mvn executable not found in kit/ or any of its subdirectories, gather it"
        end
      end
    end

    subcommand "status", "Prints the current phase" do
      def execute
        puts "Now #{Gjp::Project.new(".").get_status.to_s}"
      end
    end

    subcommand "finish", "Ends the current phase" do
      def execute
        result = Gjp::Project.new(".").finish        
        if result == :gathering
          puts "Gathering finished."
          puts "New files have been added to gjp_file_list files in respective directories."
          puts "Feel free to edit them if needed."
          puts "You can start a dry run build with \"gjp dry-run\" or add more files with \"gjp gather\"."
        end
      end
    end

    subcommand "generate-kit-spec", "Scaffolds or refreshes a spec file for the kit" do
      def execute
        project = Gjp::Project.new(".")
        result_path = Gjp::Scaffolder.new(project).generate_kit_spec
        puts "#{result_path} generated"
      end
    end

    subcommand "generate-kit-archive", "Archives contents of kit in archives/" do
      def execute
        project = Gjp::Project.new(".")
        result_path = Gjp::Archiver.new(project).archive_kit
        if result_path != nil
          puts "#{result_path} generated"
        else
          "The file_list/kit file was not found. Ensure you already added content to kit/ " +
          "during a gathering and/or dry-running phase, and ensure you ended that phase " +
          "with \"gjp finish\"."
        end
      end
    end

    subcommand "generate-package-spec", "Scaffolds or refreshes a spec file for a package" do
      option ["-f", "--filter"], "FILTER", "filter files to be installed by this spec", :default => "*.jar"
      parameter "NAME", "name of a package, that is, an src/ subdirectory name"
      parameter "POM", "a pom file path or URI"
      def execute
        project = Gjp::Project.new(".")
        result_path = Gjp::Scaffolder.new(project).generate_package_spec name, pom, filter
        if result_path != nil
          puts "#{result_path} generated"
        else
          "The file_list/#{name}_output file was not found. Ensure you have already run a" +
          "dry run and ensure you ended that phase with \"gjp finish\"."
        end
      end
    end

    subcommand "generate-package-archive", "Archives contents of a package in archives/" do
      parameter "NAME", "name of a package, that is, an src/ subdirectory name"
      def execute
        project = Gjp::Project.new(".")
        result_path = Gjp::Archiver.new(project).archive_package name
        if result_path != nil
          puts "#{result_path} generated"
        else
          "The file_list/#{name}_input file was not found. Ensure you have already added content to " +
          "src/#{name} during a gathering phase, and ensure you ended that phase with \"gjp finish\"."
        end
      end
    end

    subcommand "set-up-nonet-user", "Sets up a \"nonet\" user that cannot access the network" do
      def execute
        user = Gjp::LimitedNetworkUser.new("nonet")
        user.set_up

        "sudo #{user.get_path("useradd")} nonet\n" +
        "sudo #{user.get_path("iptables")} -A OUTPUT -m owner --uid-owner nonet -j DROP\n" +
        "User \"nonet\" set up, you can use \"sudo nonet\" to dry-run your build with no network access.\n" +
        "Note that the above iptables rule will be cleared at next reboot, you can use your distribution " +
        "tools to make it persistent or run \"gjp set-up-limited-nertwork-user\" again next time."
      end
    end

    subcommand "tear-down-nonet-user", "Deletes a user previously created by gjp" do
      def execute
        user = Gjp::LimitedNetworkUser.new("nonet")

        user.tear_down

        "sudo #{user.get_path("iptables")} -D OUTPUT -m owner --uid-owner nonet -j DROP\n" +
        "sudo #{user.get_path("userdel")} nonet\n"
      end
    end

    subcommand "get-pom", "Retrieves a pom corresponding to a filename" do
      parameter "NAME", "a jar file path, a project directory path or a non-existing filename in the `project-version` form"
      def execute
        puts Gjp::PomGetter.new.get_pom(name)
      end
    end

    subcommand "get-parent-pom", "Retrieves a pom that is the parent of an existing pom" do
      parameter "POM", "a pom file path or URI"
      def execute
        puts Gjp::ParentPomGetter.new.get_parent_pom(pom)
      end
    end
      
    subcommand "get-source-address", "Retrieves a project's SCM Internet address" do
      parameter "POM", "a pom file path or URI"

      def execute
        puts Gjp::SourceAddressGetter.new.get_source_address(pom)
      end    
    end
    
    subcommand "get-source", "Retrieves a project's source code directory" do
      parameter "ADDRESS", "project's SCM Internet address"
      parameter "POM", "project's pom file path or URI"
      parameter "[DIRECTORY]", "directory in which to save the source code", :default => "."

      def execute
        puts Gjp::SourceGetter.new.get_source(address, pom, directory)
      end    
    end

    subcommand "scaffold-jar-table", "Creates a heuristic version of a project's jar table" do
      parameter "[DIRECTORY]", "project directory", :default => "."
      option ["--include-all"], :flag, "include tests and samples in produced jars", :default => false

      def execute
        puts Gjp::JarTable.new(directory, include_all?).to_s
      end    
    end
  end
end
