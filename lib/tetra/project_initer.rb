# encoding: UTF-8

module Tetra
  # takes care of intiializing a tetra project
  module ProjectIniter
    include Logging

    # path of the project template files
    TEMPLATE_PATH = File.join(File.dirname(__FILE__), "..", "template")

    # includers get class methods defined in ClassMethods
    def self.included(base)
      base.extend(ClassMethods)
    end
    # class methods container
    module ClassMethods
      # returns true if the specified directory is a valid tetra project
      def project?(dir)
        File.directory?(File.join(dir, "src")) &&
          File.directory?(File.join(dir, "kit")) &&
          File.directory?(File.join(dir, ".git"))
      end

      # inits a new project directory structure
      def init(dir, include_bundled_software = true)
        Dir.mkdir(dir)
        Dir.chdir(dir) do
          git = Tetra::Git.new(".")

          git.init

          FileUtils.mkdir_p("src")
          FileUtils.mkdir_p("kit")

          # populate the project with templates and commit it
          project = Project.new(".")

          project.template_files(include_bundled_software).each do |source, destination|
            FileUtils.cp_r(File.join(TEMPLATE_PATH, source), destination)
          end

          git.commit_directories(["."], "Template files added")
        end
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
        Dir.chdir(TEMPLATE_PATH) do
          Dir.glob(File.join("bundled", "*")).each do |file|
            result[file] = "kit"
          end
        end
      end

      result
    end

    # adds a source archive at the project, both in original and unpacked forms
    def commit_source_archive(file)
      from_directory do
        result_dir = File.join(packages_dir, name)
        FileUtils.mkdir_p(result_dir)

        result_path = File.join(result_dir, File.basename(file))
        FileUtils.cp(file, result_path)
        @git.commit_file(result_path, "Source archive added")

        unarchiver = if file =~ /\.zip$/
                       Tetra::Unzip.new
                     else
                       Tetra::Tar.new
                     end

        unarchiver.decompress(file, "src")
      end
    end
  end
end
