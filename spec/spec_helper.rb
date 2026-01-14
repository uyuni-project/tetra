# encoding: UTF-8

require "aruba/rspec"
require "simplecov"
require "simplecov-cobertura"

require "tetra"

SimpleCov.start do
  # Use the Cobertura formatter for CI, but keep HTML for local browsing
  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       SimpleCov::Formatter::CoberturaFormatter
                                                     ])
end

Aruba.configure do |config|
  # Increase the default timeout from 3 seconds to 15 seconds.
  # This covers standard commands that are just slightly slow.
  config.exit_timeout = 15

  # Optional: Increase I/O wait time if your tool is slow to output text
  config.io_wait_timeout = 2
end

# configure aruba for rspec use
RSpec.configure do |config|
  config.include Aruba::Api
  # If running in a CI environment, use the verbose 'documentation'
  # formatter so we see progress line-by-line.
  config.formatter = :documentation if ENV["CI"]

  # We use aruba's helper to prepend the bin path safely for each test.
  config.before(:each) do
    # 1. Configure Git identity for Unit Tests (running in this Ruby process)
    ENV["GIT_AUTHOR_NAME"] = "Tetra Test"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "Tetra Test"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"

    # 2. Configure Git identity for aruba and CI tests (running in subprocesses)
    if respond_to?(:set_environment_variable)
      set_environment_variable("GIT_AUTHOR_NAME", "Tetra Test")
      set_environment_variable("GIT_AUTHOR_EMAIL", "test@example.com")
      set_environment_variable("GIT_COMMITTER_NAME", "Tetra Test")
      set_environment_variable("GIT_COMMITTER_EMAIL", "test@example.com")
    end

    # 3. Existing PATH setup
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "bin"))
    prepend_environment_variable("PATH", bin_path + File::PATH_SEPARATOR) if respond_to?(:prepend_environment_variable)

    bin_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "bin"))
    prepend_environment_variable("PATH", bin_path + File::PATH_SEPARATOR)
  end
end

module Tetra
  # custom mock methods
  module Mockers
    # creates a minimal tetra project
    def create_mock_project
      @project_path = File.join("spec", "data", "test-project")
      Tetra::Project.init(@project_path, false)
      @project = Tetra::Project.new(@project_path)
    end

    # deletes the mock project and all contents
    def delete_mock_project
      FileUtils.rm_rf(@project_path)
    end

    # creates an executable in kit that will print its parameters
    # in a test_out file for checking. Returns mocked executable
    # full path
    def create_mock_executable(executable_name)
      Dir.chdir(@project_path) do
        dir = mock_executable_dir(executable_name)
        FileUtils.mkdir_p(dir)
        executable_path = mock_executable_path(executable_name)
        File.open(executable_path, "w") { |io| io.puts "echo $0 $*>test_out" }
        File.chmod(0777, executable_path)
        executable_path
      end
    end

    # returns the path for a mocked executable's directory
    def mock_executable_dir(executable_name)
      File.join("kit", executable_name, "bin")
    end

    # returns the path for a mocked executable
    def mock_executable_path(executable_name)
      File.join(mock_executable_dir(executable_name), executable_name)
    end
  end
end
