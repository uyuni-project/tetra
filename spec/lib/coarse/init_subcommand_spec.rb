require "spec_helper"

describe "`tetra`", type: :aruba do
  it "inits a new project" do
    run_simple("tetra init")

    expect(stdout_from("tetra init")).to include("Project inited.")

    check_directory_presence([".git", "kit", "src"], true)
  end
end
