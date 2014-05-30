# encoding: UTF-8

require "gjp"

module Gjp
  # custom mock methods
  module Mockers
    # creates a minimal gjp project
    def create_mock_project
      @project_path = File.join("spec", "data", "test-project")
      Dir.mkdir(@project_path)

      Gjp::Project.init(@project_path)
      @project = Gjp::Project.new(@project_path)
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
        bin_dir = File.join("kit", executable_name, "bin")
        FileUtils.mkdir_p(bin_dir)
        executable_path = File.join(bin_dir, executable_name)
        File.open(executable_path, "w") { |io| io.puts "echo $0 $*>test_out" }
        File.chmod(0777, executable_path)
        executable_path
      end
    end
  end
end
