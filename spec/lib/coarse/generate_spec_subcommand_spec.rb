require "spec_helper"

describe "`tetra generate-spec`", type: :aruba do
  it "outputs a warning if source files are not found" do
    run_simple("tetra init --no-archive commons-collections")
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

    run_simple("tetra generate-spec")

    expect(output_from("tetra generate-spec")).to include("Warning: source archive not found, package will not build")
  end
end
