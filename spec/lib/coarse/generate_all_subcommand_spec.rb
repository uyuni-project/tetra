require "spec_helper"

describe "`tetra generate-all`", type: :aruba do
  it "generates specs and tarballs for a sample package, source archive workflow" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.1-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_simple("tetra init commons-collections commons-collections.zip")
    cd(File.join("commons-collections", "src", "commons-collections4-4.1-src"))

    # first dry-run, all normal
    @aruba_timeout_seconds = 240
    run_interactive("tetra dry-run --very-very-verbose")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")
    expect(all_output).to include("Checking for tetra project")

    # first generate-all, all normal
    run_simple("tetra generate-all")

    expect(output_from("tetra generate-all")).to include("commons-collections-kit.spec generated")
    expect(output_from("tetra generate-all")).to include("commons-collections-kit.tar.xz generated")
    expect(output_from("tetra generate-all")).to include("build.sh generated")
    expect(output_from("tetra generate-all")).to include("commons-collections.spec generated")

    # patch one file
    append_to_file("README.txt", "patched by tetra test")

    # second dry-run fails: sources changed
    run_simple("tetra dry-run")
    expect(output_from("tetra dry-run")).to include("Changes detected in src")
    expect(output_from("tetra dry-run")).to include("Dry run not started")

    # run patch
    run_simple("tetra patch")

    # third dry-run succeeds with patch
    run_interactive("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")

    run_simple("tetra generate-all --very-very-verbose")

    expect(output_from("tetra generate-all --very-very-verbose")).to include("commons-collections-kit.spec generated")
    expect(output_from("tetra generate-all --very-very-verbose")).to include("commons-collections-kit.tar.xz generated")
    expect(output_from("tetra generate-all --very-very-verbose")).to include("build.sh generated")
    expect(output_from("tetra generate-all --very-very-verbose")).to include("commons-collections.spec generated")
    expect(output_from("tetra generate-all --very-very-verbose")).to include("0001-Sources-updated.patch generated")

    with_file_content("../../packages/commons-collections/commons-collections.spec") do |content|
      expect(content).to include("0001-Sources-updated.patch")
    end
  end

  it "generates specs and tarballs for a sample package, manual source workflow" do
    archive_contents = File.read(File.join("spec", "data", "commons-collections4-4.1-src.zip"))
    write_file("commons-collections.zip", archive_contents)

    # init project
    run_simple("tetra init -n commons-collections")

    # add sources
    run_simple("unzip commons-collections.zip -d commons-collections/src")

    cd("commons-collections")

    # first dry-run fails: sources changed
    run_simple("tetra dry-run")
    expect(output_from("tetra dry-run")).to include("Changes detected in src")
    expect(output_from("tetra dry-run")).to include("Dry run not started")

    # run change-sources
    run_simple("tetra change-sources ../commons-collections.zip")
    expect(output_from("tetra change-sources ../commons-collections.zip")).to include("New sources committed")

    # second dry-run, all normal
    cd(File.join("src", "commons-collections4-4.1-src"))
    @aruba_timeout_seconds = 240
    run_interactive("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("[INFO] BUILD SUCCESS")

    # first generate-all, all normal
    run_simple("tetra generate-all")

    expect(output_from("tetra generate-all")).to include("commons-collections-kit.spec generated")
    expect(output_from("tetra generate-all")).to include("commons-collections-kit.tar.xz generated")
    expect(output_from("tetra generate-all")).to include("build.sh generated")
    expect(output_from("tetra generate-all")).to include("commons-collections.spec generated")

    # patch one file
    append_to_file("README.txt", "patched by tetra test")

    # second dry-run fails: sources changed
    run_simple("tetra dry-run")
    expect(output_from("tetra dry-run")).to include("Changes detected in src")
    expect(output_from("tetra dry-run")).to include("Dry run not started")

    # run patch
    run_simple("tetra patch")

    # third dry-run succeeds with patch
    run_interactive("tetra dry-run")
    type("mvn package -DskipTests")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0
    expect(all_output).to include("[INFO] BUILD SUCCESS")

    run_simple("tetra generate-all")

    expect(output_from("tetra generate-all")).to include("commons-collections-kit.spec generated")
    expect(output_from("tetra generate-all")).to include("commons-collections-kit.tar.xz generated")
    expect(output_from("tetra generate-all")).to include("build.sh generated")
    expect(output_from("tetra generate-all")).to include("commons-collections.spec generated")
    expect(output_from("tetra generate-all")).to include("0001-Sources-updated.patch generated")

    with_file_content("../../packages/commons-collections/commons-collections.spec") do |content|
      expect(content).to include("0001-Sources-updated.patch")
      expect(content).to include("commons-collections.zip")
    end
  end
end
