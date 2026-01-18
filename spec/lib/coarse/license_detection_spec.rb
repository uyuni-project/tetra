# frozen_string_literal: true

require "spec_helper"

describe "tetra generate-spec license handling", type: :aruba do
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

  Tetra::LICENSE_MAPPINGS.each do |raw_name, expected_spdx|
    it "correctly maps '#{raw_name}' to '#{expected_spdx}'" do
      project_name = "proj-#{expected_spdx.downcase.gsub(/[^a-z0-9]/, "")}"
      version      = "1.0"
      group_id     = "com.example"

      write_file("pom.xml", create_pom(group_id, project_name, version, raw_name))
      write_file("LICENSE", "License text")
      write_file("COPYING", "Copying text")
      write_file("README", "Readme text")

      tarball_name = "#{project_name}.tar"
      run_command_and_stop("tar -cvf #{tarball_name} pom.xml LICENSE COPYING README")

      run_command_and_stop("tetra init #{project_name} #{tarball_name}")

      cd(project_name) do
        # NOTE: Identity is already set in spec_helper's around hook,
        # but we can keep these for explicit project-level config
        run_command_and_stop("git config user.email 'test@example.com'")
        run_command_and_stop("git config user.name 'Test User'")

        # --- NON-INTERACTIVE DRY-RUN ---
        run_command("tetra dry-run")
        last_command_started.write <<~COMMANDS
          touch #{project_name}-#{version}.jar
          echo 'changes' >> README
          exit 0
        COMMANDS

        last_command_started.stop
        expect(last_command_started).to be_successfully_executed

        run_command_and_stop("tetra generate-spec src/pom.xml")

        possible_paths = [
          "packages/#{project_name}/package.spec",
          "packages/#{project_name}/#{project_name}.spec"
        ]
        spec_path = possible_paths.find { |path| file?(path) }

        expect(spec_path).not_to be_nil, "Spec file missing. Checked: #{possible_paths}"

        spec_content = read(spec_path).join("\n")
        expect(spec_content).to match(/License:\s+#{Regexp.escape(expected_spdx)}/)
        expect(spec_content).to include("%doc LICENSE")
        expect(spec_content).to include("%doc COPYING")
      end
    end
  end
end
