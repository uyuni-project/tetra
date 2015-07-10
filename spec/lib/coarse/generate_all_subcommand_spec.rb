require "spec_helper"

describe "`tetra generate-all`", type: :aruba do
  it "generates specs and tarballs for a sample package" do
    run_simple("tetra init --no-sources commons-collections")
    cd("commons-collections")

    archive_contents = File.read(File.join("spec", "data", "commons-collections-3.2.1-src.zip"))
    write_file(File.join("src", "commons-collections.zip"), archive_contents)

    cd("src")
    run_simple("unzip commons-collections.zip")
    cd("commons-collections-3.2.1-src")

    @aruba_timeout_seconds = 120
    run_interactive("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")

    run_simple("tetra generate-all")

    expect(stdout_from("tetra generate-all")).to include("commons-collections-kit.spec generated")
    expect(stdout_from("tetra generate-all")).to include("commons-collections-kit.tar.xz generated")
    expect(stdout_from("tetra generate-all")).to include("build.sh generated")
    expect(stdout_from("tetra generate-all")).to include("commons-collections.tar.xz generated")
    expect(stdout_from("tetra generate-all")).to include("commons-collections.spec generated")
  end
end
