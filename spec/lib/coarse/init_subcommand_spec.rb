require "spec_helper"

describe "`tetra`", type: :aruba do
  it "shows an error if required parameters are not set" do
    run_command_and_stop("tetra init", fail_on_error: false)

    expect(last_command_started.stderr).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if required parameters are not set, even if options are set" do
    run_command_and_stop("tetra init -n", fail_on_error: false)

    expect(last_command_started.stderr).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if no sources are specified and -n is not set" do
    run_command_and_stop("tetra init mypackage", fail_on_error: false)

    expect(last_command_started.stderr).to include("please specify a source archive")

    # Old: check_directory_presence(["mypackage"], false)
    expect("mypackage").not_to be_an_existing_directory
  end

  it "inits a new project without sources" do
    run_command_and_stop("tetra init --no-archive mypackage")

    expect(last_command_started.output).to include("Project inited in mypackage/.")

    # Old: check_directory_presence(["mypackage"], true)
    expect("mypackage").to be_an_existing_directory

    cd("mypackage")

    # Old: check_directory_presence([".git", "kit", "src"], true)
    expect(".git").to be_an_existing_directory
    expect("kit").to be_an_existing_directory
    expect("src").to be_an_existing_directory
  end

  it "inits a new project with a zip source file" do
    # Note: File.read runs in RSpec process (project root), write_file writes to Aruba tmp dir
    archive_contents = File.read(File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_command_and_stop("tetra init commons-collections commons-collections.zip")

    output = last_command_started.output
    expect(output).to include("Project inited in commons-collections/.")
    expect(output).to include("Sources decompressed in commons-collections/src/")
    expect(output).to include("original archive copied in commons-collections/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    expect("commons-collections").to be_an_existing_directory

    cd("commons-collections")

    expect(".git").to be_an_existing_directory
    expect("kit").to be_an_existing_directory
    expect("src").to be_an_existing_directory
    expect("packages").to be_an_existing_directory

    expect(File.join("src", Tetra::CCOLLECTIONS)).to be_an_existing_directory
    expect(File.join("src", Tetra::CCOLLECTIONS, "pom.xml")).to be_an_existing_file

    expect(File.join("packages", "commons-collections", "commons-collections.zip")).to be_an_existing_file

    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("Inital sources added from archive")
  end

  it "inits a new project with a tar source file" do
    archive_contents = File.read(File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.tar.gz"))
    write_file("commons-collections.tar.gz", archive_contents)

    run_command_and_stop("tetra init commons-collections commons-collections.tar.gz")

    output = last_command_started.output
    expect(output).to include("Project inited in commons-collections/.")
    expect(output).to include("Sources decompressed in commons-collections/src/")
    expect(output).to include("original archive copied in commons-collections/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    expect("commons-collections").to be_an_existing_directory

    cd("commons-collections")

    expect(".git").to be_an_existing_directory
    expect("kit").to be_an_existing_directory
    expect("src").to be_an_existing_directory
    expect("packages").to be_an_existing_directory

    expect(File.join("src", Tetra::CCOLLECTIONS)).to be_an_existing_directory
    expect(File.join("src", Tetra::CCOLLECTIONS, "pom.xml")).to be_an_existing_file

    expect(File.join("packages", "commons-collections", "commons-collections.tar.gz")).to be_an_existing_file

    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("Inital sources added from archive")
  end
end
