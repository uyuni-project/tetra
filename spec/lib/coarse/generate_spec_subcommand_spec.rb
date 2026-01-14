require "spec_helper"

describe "`tetra generate-spec`", type: :aruba do
  it "outputs a warning if source files are not found" do
    archive_contents = File.read(File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_command_and_stop("tetra init --no-archive commons-collections")
    cd("commons-collections")

    cd("src")
    run_command_and_stop("unzip ../../commons-collections.zip")
    cd(Tetra::CCOLLECTIONS)

    run_command_and_stop("tetra change-sources --no-archive")
    expect(last_command_started.output).to include("New sources committed")

    # Interactive dry-run with increased timeout
    run_command("tetra dry-run", exit_timeout: 300)
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D)
    stop_all_commands

    expect(last_command_started.output).to include("[INFO] BUILD SUCCESS")

    run_command_and_stop("tetra generate-spec")

    expect(last_command_started.output).to include("Warning: source archive not found, package will not build")
  end
end
