require "spec_helper"

describe "`tetra dry-run`", type: :aruba do
  it "does not start a dry-run if init has not run yet" do
    # Expecting failure, so we disable fail_on_error
    run_command_and_stop("tetra dry-run", fail_on_error: false)

    expect(last_command_started.stderr).to include("is not a tetra project directory")
  end

  it "does a dry-run build" do
    run_command_and_stop("tetra init --no-archive mypackage")
    cd("mypackage")

    # Interactive Step:
    # 1. Start the command asynchronously (don't wait yet)
    run_command("tetra dry-run")

    # 2. Send input to the running process
    type("echo ciao")
    type("echo ciao > ciao.jar")
    type("\u{0004}") # ^D (Ctrl+D) to exit the shell

    # 3. Wait for the command to finish processing input and exit
    stop_all_commands

    # Check output of the interactive session
    output = last_command_started.output
    expect(output).to include("Dry-run started")
    expect(output).to include("bash shell")
    expect(output).to include("ciao")
    expect(output).to include("Dry-run finished")

    # check that markers were written in git repo
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD~")
    expect(last_command_started.stdout).to include("tetra: dry-run-started")

    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("tetra: dry-run-finished")
    expect(last_command_started.stdout).to include("tetra: build-script-line: echo ciao")
  end

  it "does a scripted dry-run" do
    run_command_and_stop("tetra init --no-archive mypackage")
    cd("mypackage")

    run_command_and_stop("tetra dry-run -s 'echo ciao > ciao.jar'")

    expect(last_command_started.output).to include("Scripted dry-run started")

    # check that markers were written in git repo
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD~")
    expect(last_command_started.stdout).to include("tetra: dry-run-started")

    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("tetra: dry-run-finished")
    expect(last_command_started.stdout).to include("tetra: build-script-line: echo ciao > ciao.jar")
  end
end
