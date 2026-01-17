# frozen_string_literal: true

require "spec_helper"

describe "`tetra`", type: :aruba do
  it "lists subcommands" do
    # Run the command and wait for it to finish
    run_command_and_stop("tetra")

    # Check the output
    output = last_command_started.stdout
    expect(output).to include("Usage:")

    # Define expected subcommands in a list for cleaner verification
    expected_subcommands = %w[
      init
      dry-run
      generate-kit
      generate-script
      generate-spec
      generate-all
      patch
      move-jars-to-kit
      get-pom
    ]

    expected_subcommands.each do |subcommand|
      expect(output).to include(subcommand)
    end
  end
end
