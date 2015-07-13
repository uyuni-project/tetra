require "spec_helper"

describe "`tetra`", type: :aruba do
  it "shows an error if required parameters are not set" do
    run_simple("tetra init", false)

    expect(stderr_from("tetra init")).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if required parameters are not set, even if options are set" do
    run_simple("tetra init -n", false)

    expect(stderr_from("tetra init -n")).to include("parameter 'PACKAGE_NAME': no value provided")
  end

  it "shows an error if no sources are specified and -n is not set" do
    run_simple("tetra init mypackage", false)

    expect(stderr_from("tetra init mypackage")).to include("please specify a source archive")

    check_directory_presence(["mypackage"], false)
  end

  it "inits a new project without sources" do
    run_simple("tetra init --no-archive mypackage")

    expect(output_from("tetra init --no-archive mypackage")).to include("Project inited in mypackage/.")

    check_directory_presence(["mypackage"], true)
    cd("mypackage")
    check_directory_presence([".git", "kit", "src"], true)
  end

  it "inits a new project with a zip source file" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections-3.2.1-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_simple("tetra init commons-collections commons-collections.zip")

    output = output_from("tetra init commons-collections commons-collections.zip")
    expect(output).to include("Project inited in commons-collections/.")
    expect(output).to include("Sources decompressed in commons-collections/src/")
    expect(output).to include("original archive copied in commons-collections/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    check_directory_presence(["commons-collections"], true)

    cd("commons-collections")
    check_directory_presence([".git", "kit", "src", "packages"], true)

    check_directory_presence([File.join("src", "commons-collections-3.2.1-src")], true)
    check_file_presence([File.join("src", "commons-collections-3.2.1-src", "pom.xml")], true)

    check_file_presence([File.join("packages", "commons-collections", "commons-collections.zip")], true)

    run_simple("git rev-list --format=%B --max-count=1 HEAD")
    expect(stdout_from("git rev-list --format=%B --max-count=1 HEAD")).to include("Inital sources added from archive")
  end

  it "inits a new project with a tar source file" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections-3.2.1-src.tar.gz"))
    write_file("commons-collections.tar.gz", archive_contents)

    run_simple("tetra init commons-collections commons-collections.tar.gz")

    output = output_from("tetra init commons-collections commons-collections.tar.gz")
    expect(output).to include("Project inited in commons-collections/.")
    expect(output).to include("Sources decompressed in commons-collections/src/")
    expect(output).to include("original archive copied in commons-collections/packages/.")
    expect(output).to include("Please add any other precompiled build dependency to kit/.")

    check_directory_presence(["commons-collections"], true)

    cd("commons-collections")
    check_directory_presence([".git", "kit", "src", "packages"], true)

    check_directory_presence([File.join("src", "commons-collections-3.2.1-src")], true)
    check_file_presence([File.join("src", "commons-collections-3.2.1-src", "pom.xml")], true)

    check_file_presence([File.join("packages", "commons-collections", "commons-collections.tar.gz")], true)

    run_simple("git rev-list --format=%B --max-count=1 HEAD")
    expect(stdout_from("git rev-list --format=%B --max-count=1 HEAD")).to include("Inital sources added from archive")
  end
end
