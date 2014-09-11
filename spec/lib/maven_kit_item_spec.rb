# encoding: UTF-8

require "spec_helper"

describe Tetra::MavenKitItem do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  after(:each) do
    delete_mock_project
  end

  let(:group_id) { "com.company.project" }
  let(:artifact_id) { "artifact" }
  let(:version) { "1.0" }
  let(:dir) { File.join(group_id.gsub(".", File::SEPARATOR), artifact_id, version) }
  let(:pom) { File.join(dir, "#{artifact_id}-#{version}.pom") }
  let(:jar) { File.join(dir, "#{artifact_id}.jar") }
  let(:package_name) { "kit-item-#{group_id.gsub(".", "-")}-#{artifact_id}-#{version}" }
  let(:maven_kit_item) { Tetra::MavenKitItem.new(@project, pom, [pom, jar]) }

  describe "#provides_symbol" do
    it "returns the sepec Provides: symbol" do
      expect(maven_kit_item.provides_symbol).to eq("mvn(com.company.project:artifact)")
    end
  end

  describe "#provides_version" do
    it "returns the spec Provides: version" do
      expect(maven_kit_item.provides_version).to eq("1.0")
    end
  end

  describe "#to_spec" do
    it "generates a specfile" do
      expect(maven_kit_item.to_spec).to be_truthy

      @project.from_directory do
        spec_lines = File.readlines(File.join("output", package_name, "#{package_name}.spec"))

        expect(spec_lines).to include("# spec file for a build-time dependency of project \"test-project\"\n")
        expect(spec_lines).to include("Name:           kit-item-com-company-project-artifact-1.0\n")
        expect(spec_lines).to include("Summary:        Build-time dependency of project \"test-project\"\n")
        expect(spec_lines).to include("Provides:       mvn(#{group_id}:#{artifact_id}) == #{version}\n")

        expect(spec_lines).to include("install -d -m 0755 %{buildroot}%{_datadir}/tetra/m2/\n")
        expect(spec_lines).to include("cp -a * %{buildroot}%{_datadir}/tetra/m2/\n")
        expect(spec_lines).to include("%{_datadir}/tetra/m2/\n")
      end
    end
  end

  describe "#to_archive" do
    it "generates an archive" do
      @project.from_directory(File.join("kit", "m2")) do
        FileUtils.mkdir_p(dir)
        FileUtils.touch(pom)
        FileUtils.touch(jar)
      end

      expected_filename = File::SEPARATOR + "kit-item-com-company-project-artifact-1.0.tar.xz"
      expect(maven_kit_item.to_archive).to end_with(expected_filename)

      @project.from_directory do
        contents = `tar -Jtf output/#{package_name}/#{package_name}.tar.xz`.split
        expect(contents).to include("com/company/project/artifact/1.0/artifact-1.0.pom")
        expect(contents).to include("com/company/project/artifact/1.0/artifact.jar")
      end
    end
  end
end
