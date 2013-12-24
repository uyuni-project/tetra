# encoding: UTF-8

require "gjp"
require "gjp/logger"

Gjp::Logger.log.level = ::Logger::DEBUG

# creates an executable in kit that will print its parameters
# in a test_out file for checking. Returns mocked executable
# full path
def mock_executable(executable_name, project_path)
  Dir.chdir(project_path) do
    bin_dir = File.join("kit", executable_name, "bin")
    FileUtils.mkdir_p(bin_dir)
    executable_path = File.join(bin_dir, executable_name)
    File.open(executable_path, "w") { |io| io.puts "echo $0 $*>test_out" }
    File.chmod(0777, executable_path)
    executable_path
  end
end
