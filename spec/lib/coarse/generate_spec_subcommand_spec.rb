require "spec_helper"

describe "`tetra generate-spec`", type: :aruba do
  it "outputs a warning if source files are not found" do
    archive_contents = File.read(File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip"))
    write_file("commons-collections.zip", archive_contents)

    run_simple("tetra init --no-archive commons-collections")
    cd("commons-collections")

    cd("src")
    run_simple("unzip ../../commons-collections.zip")
    cd(Tetra::CCOLLECTIONS)

    run_simple("tetra change-sources --no-archive")
    expect(output_from("tetra change-sources --no-archive")).to include("New sources committed")

    @aruba_timeout_seconds = 300
    run("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")

    run_simple("tetra generate-spec")

    expect(output_from("tetra generate-spec")).to include("Warning: source archive not found, package will not build")
  end
end
