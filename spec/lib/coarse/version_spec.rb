# frozen_string_literal: true

require "spec_helper"

describe "tetra --version and -v commands", type: :aruba do
  it "prints the version with --version" do
    # Run the command
    run_command_and_stop("tetra --version")

    # Verify the exit status is 0 (success)
    expect(last_command_started).to be_successfully_executed

    # Verify the output matches the Ruby constant
    expect(last_command_started).to have_output(Tetra::VERSION)
  end

  it "prints the version with -v" do
    run_command_and_stop("tetra -v")

    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_output(Tetra::VERSION)
  end
end
