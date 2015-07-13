require "spec_helper"

describe "`tetra generate-all`", type: :aruba do
  it "generates specs and tarballs for a sample package" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections-3.2.1-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_simple("tetra init commons-collections commons-collections.zip")
    cd(File.join("commons-collections", "src", "commons-collections-3.2.1-src"))

    @aruba_timeout_seconds = 120
    run_interactive("tetra dry-run --very-very-verbose")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")
    expect(all_output).to include("Checking for tetra project")

    run_simple("tetra generate-all")

    expect(stdout_from("tetra generate-all")).to include("commons-collections-kit.spec generated")
    expect(stdout_from("tetra generate-all")).to include("commons-collections-kit.tar.xz generated")
    expect(stdout_from("tetra generate-all")).to include("build.sh generated")
    expect(stdout_from("tetra generate-all")).to include("commons-collections.spec generated")
  end
end
