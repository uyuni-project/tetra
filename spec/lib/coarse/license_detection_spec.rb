# frozen_string_literal: true

require "spec_helper"

describe "tetra generate-spec license handling", type: :aruba do
  # Helper to generate a minimal, valid POM with DYNAMIC artifactId
  def create_pom(group_id, artifact_id, version, license_name)
    <<~XML
      <project>
        <modelVersion>4.0.0</modelVersion>
        <groupId>#{group_id}</groupId>
        <artifactId>#{artifact_id}</artifactId>
        <version>#{version}</version>
        <packaging>jar</packaging>
        <licenses>
          <license>
            <name>#{license_name}</name>
            <url>http://example.com/license</url>
          </license>
        </licenses>
      </project>
    XML
  end

  # Raw POM License Name => Expected SPDX Identifier
  let(:test_cases) do
    {
      "The Apache Software License, Version 2.0" => "Apache-2.0",
      "The MIT License" => "MIT",
      "Eclipse Public License 1.0" => "EPL-1.0",
      "GNU General Public License, version 2" => "GPL-2.0-only",
      "GNU Lesser General Public License" => "LGPL-2.1-only",
      "Unmapped Custom License" => "Unmapped Custom License"
    }
  end

  it "detects license names and converts them to SPDX" do
    test_cases.each do |raw_name, expected_spdx|
      project_name = "proj-#{expected_spdx.downcase.gsub(/[^a-z0-9]/, "")}"
      version      = "1.0"
      group_id     = "com.example"

      # Place files directly in the tarball root so they unpack to src/
      write_file("pom.xml", create_pom(group_id, project_name, version, raw_name))
      write_file("LICENSE", "License text")
      write_file("COPYING", "Copying text")
      write_file("README", "Readme text")

      tarball_name = "#{project_name}.tar"
      run_command_and_stop("tar -cvf #{tarball_name} pom.xml LICENSE COPYING README")

      run_command_and_stop("tetra init #{project_name} #{tarball_name}")

      cd(project_name) do
        run_command_and_stop("git config user.email 'test@example.com'")
        run_command_and_stop("git config user.name 'Test User'")

        run_command("tetra dry-run")
        expect(last_command_started).to have_output(/Dry-run started/)

        # SIMULATE BUILD:
        # Create a JAR that matches the POM's artifactId and version.
        # This confirms to tetra that the build produced valid output.
        jar_name = "#{project_name}-#{version}.jar"
        type "echo 'dummy-content' > #{jar_name}"

        type "exit"
        last_command_started.wait
        expect(last_command_started).to be_successfully_executed

        # We explicitly point to src/pom.xml so tetra finds the metadata securely.
        run_command_and_stop("tetra generate-spec src/pom.xml")

        spec_path = "packages/#{project_name}/#{project_name}.spec"

        expect(file?(spec_path)).to be(true), "Spec file missing for #{project_name}"

        spec_content = read(spec_path).join("\n")

        expect(spec_content).to include("Version:        #{version}"),
                                "Metadata missing. Tetra failed to read POM for #{project_name}."

        expect(spec_content).to match(/License:\s+#{Regexp.escape(expected_spdx)}/),
                                "Failed to map '#{raw_name}' to '#{expected_spdx}'"

        expect(spec_content).to include("%doc LICENSE")
        expect(spec_content).to include("%doc COPYING")
      end
    end
  end
end
