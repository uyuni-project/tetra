require "spec_helper"

describe "`tetra dry-run`" do
  it "does not start a dry-run if init has not run yet" do
    run_command("tetra dry-run")

    expect(last_command_started).to have_output(/is not a tetra project directory/)
    expect(last_command_started).to have_exit_status(0)
  end

  # FIXME: Fix run_interactive()
  # it "does a dry-run build" do
  #   run_command("tetra init --no-archive mypackage")
  #   expect(last_command_started).to be_successfully_executed
  #   expect(last_command_started).to have_exit_status(0)
  #   cd("mypackage")
  #
  #   run_interactive("tetra dry-run")
  #   type("echo ciao")
  #   type("echo ciao > ciao.jar")
  #   type("\u{0004}") # ^D (Ctrl+D), terminates bash with exit status 0
  #
  #   expect(last_command_started).to have_output(/Dry-run started/)
  #   expect(last_command_started).to have_output(/bash shell/)
  #   expect(last_command_started).to have_output(/ciao/)
  #   expect(last_command_started).to have_output(/Dry-run finished/)
  #
  #   # check that markers were written in git repo
  #   run_command("git rev-list --format=%B --max-count=1 HEAD~")
  #   expect(last_command_started).to be_successfully_executed
  #   expect(last_command_started).to have_exit_status(0)
  #   expect(last_command_started).to have_output(/tetra: dry-run-started/)
  #
  #   run_command("git rev-list --format=%B --max-count=1 HEAD")
  #   expect(last_command_started).to be_successfully_executed
  #   expect(last_command_started).to have_exit_status(0)
  #   expect(last_command_started).to have_output(/tetra: dry-run-finished/)
  #   expect(last_command_started).to have_output(/tetra: build-script-line: echo ciao/)
  # end

  it "does a scripted dry-run" do
    run_command("tetra init --no-archive mypackage")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    cd("mypackage")

    run_command("tetra dry-run -s 'echo ciao > ciao.jar'")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Scripted dry-run started/)

    # check that markers were written in git repo
    run_command("git rev-list --format=%B --max-count=1 HEAD~")
    expect(last_command_started).to have_output(/tetra: dry-run-started/)

    run_command("git rev-list --format=%B --max-count=1 HEAD")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/tetra: dry-run-finished/)
    expect(last_command_started).to have_output(/tetra: build-script-line: echo ciao > ciao.jar/)
  end
end
