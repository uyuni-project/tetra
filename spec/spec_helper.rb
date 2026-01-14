# encoding: UTF-8

require "aruba/rspec"
require "aruba/reporting"
require "simplecov"

require "tetra"

SimpleCov.start

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

  # We use Aruba's helper to prepend the bin path safely for each test.
  config.before(:each) do
    bin_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'bin'))
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
