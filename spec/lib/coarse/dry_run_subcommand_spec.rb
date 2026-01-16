# frozen_string_literal: true

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
    # 1. Start the command asynchronously (don't wait for it to exit yet)
    run_command("tetra dry-run")

    # 2. Send input to the running process
    # Aruba's `type` simulates typing followed by a newline
    type("echo ciao")
    type("echo ciao > ciao.jar")

    # 3. Send Ctrl+D (\u{0004}) to signal EOF and exit the subshell
    type("\u{0004}")

    # 4. Wait for the command to finish processing input and exit
    stop_all_commands

    # Check output of the interactive session
    output = last_command_started.output
    expect(output).to include("Dry-run started")
    expect(output).to include("bash shell")
    expect(output).to include("ciao")
    expect(output).to include("Dry-run finished")

    # Check that markers were written in git repo

    # HEAD~ is the commit before the last one (dry-run start)
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD~")
    expect(last_command_started.stdout).to include("tetra: dry-run-started")

    # HEAD is the last commit (dry-run finish)
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("tetra: dry-run-finished")
    expect(last_command_started.stdout).to include("tetra: build-script-line: echo ciao")
  end

  it "does a scripted dry-run" do
    run_command_and_stop("tetra init --no-archive mypackage")
    cd("mypackage")

    run_command_and_stop("tetra dry-run -s 'echo ciao > ciao.jar'")

    expect(last_command_started.output).to include("Scripted dry-run started")

    # Check that markers were written in git repo
    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD~")
    expect(last_command_started.stdout).to include("tetra: dry-run-started")

    run_command_and_stop("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started.stdout).to include("tetra: dry-run-finished")
    expect(last_command_started.stdout).to include("tetra: build-script-line: echo ciao > ciao.jar")
  end
end
