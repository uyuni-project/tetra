# frozen_string_literal: true

require "spec_helper"

describe "`tetra`", type: :aruba do
  it "lists subcommands" do
    run_simple("tetra")

    expect(stdout_from("tetra")).to include("Usage:")

    expect(stdout_from("tetra")).to include("init")
    expect(stdout_from("tetra")).to include("dry-run")
    expect(stdout_from("tetra")).to include("generate-kit")
    expect(stdout_from("tetra")).to include("generate-script")
    expect(stdout_from("tetra")).to include("generate-spec")
    expect(stdout_from("tetra")).to include("generate-all")
    expect(stdout_from("tetra")).to include("patch")
    expect(stdout_from("tetra")).to include("move-jars-to-kit")
    expect(stdout_from("tetra")).to include("get-pom")
  end
end
