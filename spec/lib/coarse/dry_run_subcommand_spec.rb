require "spec_helper"

describe "`tetra dry-run`", type: :aruba do
  it "does not start a dry-run if init has not run yet" do
    run_simple("tetra dry-run")

    expect(stderr_from("tetra dry-run")).to include("is not a tetra project directory")
  end

  it "does a dry-run build" do
    run_simple("tetra init --no-sources mypackage")
    cd("mypackage")

    run_interactive("tetra dry-run")
    type("echo ciao")
    type("echo ciao > ciao.jar")
    type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0

    expect(all_output).to include("Dry-run started")
    expect(all_output).to include("ciao")
    expect(all_output).to include("Dry-run finished")

    # check that markers were written in git repo
    run_simple("git rev-list --format=%B --max-count=1 HEAD~")
    expect(stdout_from("git rev-list --format=%B --max-count=1 HEAD~")).to include("tetra: dry-run-started")

    run_simple("git rev-list --format=%B --max-count=1 HEAD")
    expect(stdout_from("git rev-list --format=%B --max-count=1 HEAD")).to include("tetra: dry-run-finished")
    expect(stdout_from("git rev-list --format=%B --max-count=1 HEAD")).to include("tetra: build-script-line: echo ciao")
  end
end
