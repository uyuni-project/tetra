require "spec_helper"

describe "`tetra`" do
  it "shows an error if required parameters are not set" do
    run_command("tetra init")

    expect(last_command_started).to have_output(/parameter 'PACKAGE_NAME': no value provided/)
    expect(last_command_started).to have_exit_status(1)
  end

  it "shows an error if required parameters are not set, even if options are set" do
    run_command("tetra init -n")

    expect(last_command_started).to have_output(/parameter 'PACKAGE_NAME': no value provided/)
    expect(last_command_started).to have_exit_status(1)
  end

  it "shows an error if no sources are specified and -n is not set" do
    run_command("tetra init mypackage")

    expect(last_command_started).to have_output(/please specify a source archive/)
    expect(last_command_started).to have_exit_status(1)
    expect(exist?("mypackage")).to be false
  end

  it "inits a new project without sources" do
    run_command_and_stop("tetra init --no-archive mypackage")

    expect(last_command_started).to have_output(/Project inited in mypackage/)
    expect(last_command_started).to have_exit_status(0)
    expect(exist?("mypackage")).to be true

    cd("mypackage")
    expect(exist?(".git")).to be true
    expect(exist?("kit")).to be true
    expect(exist?("src")).to be true
  end

  it "inits a new project with a zip source file" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.4-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_command("tetra init commons-collections commons-collections.zip")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Project inited in commons-collections/)
    expect(last_command_started).to have_output(/Sources decompressed in commons-collections/)
    expect(last_command_started).to have_output(/original archive copied in commons-collections/)
    expect(last_command_started).to have_output(/Please add any other precompiled build dependency to kit/)
    expect(exist?("commons-collections")).to be true

    cd("commons-collections")
    expect(exist?(".git")).to be true
    expect(exist?("kit")).to be true
    expect(exist?("src")).to be true
    expect(exist?("packages")).to be true
    expect(exist?(File.join("src", "commons-collections4-4.4-src"))).to be true
    expect(exist?(File.join("src", "commons-collections4-4.4-src", "pom.xml"))).to be true
    expect(exist?(File.join("packages", "commons-collections", "commons-collections.zip"))).to be true

    run_command("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Initial sources added from archive/)
  end

  it "inits a new project with a tar source file" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.4-src.tar.gz"))
    write_file("commons-collections.tar.gz", archive_contents)

    run_command("tetra init commons-collections commons-collections.tar.gz")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Project inited in commons-collections/)
    expect(last_command_started).to have_output(/Sources decompressed in commons-collections/)
    expect(last_command_started).to have_output(/original archive copied in commons-collections/)
    expect(last_command_started).to have_output(/Please add any other precompiled build dependency to kit/)
    expect(exist?("commons-collections")).to be true

    cd("commons-collections")
    expect(exist?(".git")).to be true
    expect(exist?("kit")).to be true
    expect(exist?("src")).to be true
    expect(exist?("packages")).to be true
    expect(exist?(File.join("src", "commons-collections4-4.4-src"))).to be true
    expect(exist?(File.join("src", "commons-collections4-4.4-src", "pom.xml"))).to be true
    expect(exist?(File.join("packages", "commons-collections", "commons-collections.tar.gz"))).to be true

    run_command("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Initial sources added from archive/)
  end
end
