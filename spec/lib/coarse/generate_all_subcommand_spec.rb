require "spec_helper"

describe "`tetra generate-all`", type: :aruba do
  it "generates specs and tarballs for a sample package, source archive workflow" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.4-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_command("tetra init commons-collections commons-collections.zip")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    cd(File.join("commons-collections", "src", "commons-collections4-4.4-src"))

    # first dry-run, all normal
    @aruba_timeout_seconds = 240
    run_command("tetra dry-run --very-very-verbose")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(last_command_started).to have_output(/[INFO] BUILD SUCCESS/)
    expect(last_command_started).to have_output(/Checking for tetra project/)

    # first generate-all, all normal
    run_command("tetra generate-all")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/commons-collections-kit.spec generated/)
    expect(last_command_started).to have_output(/commons-collections-kit.tar.xz generated/)
    expect(last_command_started).to have_output(/build.sh generated/)
    expect(last_command_started).to have_output(/commons-collections.spec generated/)

    # patch one file
    append_to_file("README.txt", "patched by tetra test")

    # second dry-run fails: sources changed
    run_command("tetra dry-run")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Changes detected in src/)
    expect(last_command_started).to have_output(/Dry run not started/)

    # run patch
    run_command("tetra patch")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    # third dry-run succeeds with patch
    run_command("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(last_command_started).to have_output(/[INFO] BUILD SUCCESS/)

    run_command("tetra generate-all --very-very-verbose")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    expect(last_command_started).to have_output(/commons-collections-kit.spec generated/)
    expect(last_command_started).to have_output(/commons-collections-kit.tar.xz generated/)
    expect(last_command_started).to have_output(/build.sh generated/)
    expect(last_command_started).to have_output(/commons-collections.spec generated/)
    expect(last_command_started).to have_output(/0001-Sources-updated.patch generated/)

    with_file_content("../../packages/commons-collections/commons-collections.spec") do |content|
      expect(content).to include("0001-Sources-updated.patch")
    end
  end

  it "generates specs and tarballs for a sample package, manual source workflow" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.4-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_command("tetra init -n commons-collections")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    # add sources
    run_command("unzip commons-collections.zip -d commons-collections/src")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    cd("commons-collections")

    # first dry-run fails: sources changed
    run_command("tetra dry-run")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Changes detected in src/)
    expect(last_command_started).to have_output(/Dry run not started/)

    # run change-sources
    run_command("tetra change-sources ../commons-collections.zip")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/New sources committed/)

    # second dry-run, all normal
    cd(File.join("src", "commons-collections4-4.4-src"))
    @aruba_timeout_seconds = 240
    run_command("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(last_command_started).to have_output(/[INFO] BUILD SUCCESS/)

    # first generate-all, all normal
    run_command("tetra generate-all")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/commons-collections-kit.spec generated/)
    expect(last_command_started).to have_output(/commons-collections-kit.tar.xz generated/)
    expect(last_command_started).to have_output(/build.sh generated/)
    expect(last_command_started).to have_output(/commons-collections.spec generated/)

    # patch one file
    append_to_file("README.txt", "patched by tetra test")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    # second dry-run fails: sources changed
    run_command("tetra dry-run")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Changes detected in src/)
    expect(last_command_started).to have_output(/Dry run not started/)

    # run patch
    run_command("tetra patch")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)

    # third dry-run succeeds with patch
    run_command("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0
    expect(last_command_started).to have_output(/[INFO] BUILD SUCCESS/)

    run_command("tetra generate-all")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/commons-collections-kit.spec generated/)
    expect(last_command_started).to have_output(/commons-collections-kit.tar.xz generated/)
    expect(last_command_started).to have_output(/build.sh generated/)
    expect(last_command_started).to have_output(/commons-collections.spec generated/)
    expect(last_command_started).to have_output(/0001-Sources-updated.patch generated/)


    with_file_content("../../packages/commons-collections/commons-collections.spec") do |content|
      expect(content).to include("0001-Sources-updated.patch")
      expect(content).to include("commons-collections.zip")
    end
  end
end
