# frozen_string_literal: true

module Tetra
  # takes care of initializing a tetra project
  module ProjectIniter
    include Logging

    # path of the project template files
    TEMPLATE_PATH = File.join(__dir__, "..", "template")

    # includers get class methods defined in ClassMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    # class methods container
    module ClassMethods
      # returns true if the specified directory is a valid tetra project
      def project?(dir)
        # Use a block for logging so we don't list files unless debug is on.
        # Dir.children is faster/cleaner than Dir.new(dir).to_a
        Tetra::Logger.instance.debug { "Checking for tetra project: #{dir}, contents: #{Dir.children(dir)}" }

        File.directory?(File.join(dir, "src")) &&
          File.directory?(File.join(dir, "kit")) &&
          File.directory?(File.join(dir, ".git"))
      end

      # inits a new project directory structure
      def init(dir, include_bundled_software = true)
        Dir.mkdir(dir)

        # Avoid Dir.chdir(dir). Use absolute paths instead.
        # Initialize Git facade with the full path
        git = Tetra::Git.new(dir)
        git.init

        FileUtils.mkdir_p(File.join(dir, "src"))
        FileUtils.mkdir_p(File.join(dir, "kit"))

        # Create a project instance (now that the dir structure exists)
        project = Project.new(dir)

        project.template_files(include_bundled_software).each do |source, destination|
          # Source is relative to TEMPLATE_PATH
          src_path = File.join(TEMPLATE_PATH, source)
          # Destination is relative to the new project directory
          dst_path = File.join(dir, destination)

          FileUtils.cp_r(src_path, dst_path)
        end

        # Commit "." (Git facade handles context, "." means "all changes in repo")
        git.commit_directories(["."], "Template files added")
      end
    end

    # returns a hash that maps filenames that should be copied from TEMPLATE_PATH
    # to the value directory
    def template_files(include_bundled_software)
      result = {
        "kit" => ".",
        "packages" => ".",
        "src" => "."
      }

      if include_bundled_software
        # Use 'base:' argument to avoid unsafe Dir.chdir
        # This globs files inside TEMPLATE_PATH without changing global state
        Dir.glob(File.join("bundled", "*"), base: TEMPLATE_PATH).each do |file|
          result[file] = "kit"
        end
      end

      result
    end

    # adds a source archive at the project, both in original and unpacked forms
    def commit_source_archive(file, message)
      from_directory do
        result_dir = File.join(packages_dir, name)
        FileUtils.mkdir_p(result_dir)

        result_path = File.join(result_dir, File.basename(file))
        FileUtils.cp(file, result_path)
        @git.commit_file(result_path, "Source archive added")

        unarchiver = if /\.zip$/.match?(file)
                       Tetra::Unzip.new
                     else
                       Tetra::Tar.new
                     end

        # Glob cleaning is safer than rm_rf with wildcards in shell
        Dir.glob(File.join("src", "*")).each { |f| FileUtils.rm_rf(f) }

        unarchiver.decompress(file, "src")
        commit_sources(message, true)
      end
    end
  end
end
