require "spec_helper"

RSpec.describe "`tetra`" do

  it "lists subcommands" do
    run_command("tetra")
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output(/Usage:/)
    expect(last_command_started).to have_output(/init/)
    expect(last_command_started).to have_output(/dry-run/)
    expect(last_command_started).to have_output(/generate-kit/)
    expect(last_command_started).to have_output(/generate-script/)
    expect(last_command_started).to have_output(/generate-spec/)
    expect(last_command_started).to have_output(/generate-all/)
    expect(last_command_started).to have_output(/patch/)
    expect(last_command_started).to have_output(/change-sources/)
    expect(last_command_started).to have_output(/move-jars-to-kit/)
    expect(last_command_started).to have_output(/get-pom/)
  end
end
