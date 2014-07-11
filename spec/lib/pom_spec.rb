# encoding: UTF-8

require "spec_helper"

describe Tetra::Pom do
  let(:pom) { Tetra::Pom.new(File.join("spec", "data", "commons-logging", "pom.xml")) }

  describe "#group_id" do
    it "reads the group id" do
      expect(pom.group_id).to eq "commons-logging"
    end
  end

  describe "#artifact_id" do
    it "reads the artifact id" do
      expect(pom.artifact_id).to eq "commons-logging"
    end
  end

  describe "#name" do
    it "reads artifact name" do
      expect(pom.name).to eq "Commons Logging"
    end
  end

  describe "#version" do
    it "reads the version" do
      expect(pom.version).to eq "1.1.1"
    end
  end

  describe "#description" do
    it "reads the description" do
      expect(pom.description).to eq "Commons Logging is a thin adapter allowing configurable bridging to other,\n    " \
        "well known logging systems."
    end
  end

  describe "#url" do
    it "reads the url" do
      expect(pom.url).to eq "http://commons.apache.org/logging"
    end
  end

  describe "#license_name" do
    it "reads the license name" do
      expect(pom.license_name).to eq ""
    end
  end

  describe "#runtime_dependency_ids" do
    it "reads the dependency maven ids" do
      expect(pom.runtime_dependency_ids).to eq []
    end
  end

  describe "#scm_connection" do
    it "reads the SCM connection address" do
      expect(pom.scm_connection).to eq "scm:svn:http://svn.apache.org/repos/asf/commons/proper/" \
        "logging/tags/commons-logging-1.1.1"
    end
  end

  describe "#scm_url" do
    it "reads the SCM connection url" do
      expect(pom.scm_url).to eq "http://svn.apache.org/repos/asf/commons/proper/logging/tags/commons-logging-1.1.1"
    end
  end
end
