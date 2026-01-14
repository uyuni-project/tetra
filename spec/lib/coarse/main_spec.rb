require "spec_helper"

describe "`tetra`", type: :aruba do
  it "lists subcommands" do
    # Run the command and wait for it to finish
    run_command_and_stop("tetra")

    # Check the output of the command that just finished
    expect(last_command_started.stdout).to include("Usage:")

    expect(last_command_started.stdout).to include("init")
    expect(last_command_started.stdout).to include("dry-run")
    expect(last_command_started.stdout).to include("generate-kit")
    expect(last_command_started.stdout).to include("generate-script")
    expect(last_command_started.stdout).to include("generate-spec")
    expect(last_command_started.stdout).to include("generate-all")
    expect(last_command_started.stdout).to include("patch")
    expect(last_command_started.stdout).to include("move-jars-to-kit")
    expect(last_command_started.stdout).to include("get-pom")
  end
end
