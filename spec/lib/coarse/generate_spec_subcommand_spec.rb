require "spec_helper"

describe "`tetra generate-spec`" do
  it "outputs a warning if source files are not found" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.4-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_command("tetra init --no-archive commons-collections")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    cd("commons-collections")

    cd("src")
    run_command("unzip ../../commons-collections.zip")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    cd("commons-collections4-4.4-src")

    run_command("tetra change-sources --no-archive")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/New sources committed/)

    @aruba_timeout_seconds = 300
    run_command("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    # expect(last_command_started).to have_output(/[INFO] BUILD SUCCESS/)

    run_command("tetra generate-spec")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Warning: source archive not found, package will not build/)
  end
end
