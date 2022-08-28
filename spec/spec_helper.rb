require "aruba/api"

require "tetra"

# configure aruba for rspec use
RSpec.configure do |config|
  config.include Aruba::Api

  # use tetra executable from the bin path, not the system-installed one
  config.before(:suite) do
    ENV["PATH"] = "#{File.join(File.dirname(__FILE__), '..', 'bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
  end

  # set up aruba API
  config.before(:each) { setup_aruba }
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
