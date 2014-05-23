# encoding: UTF-8

require "spec_helper"

describe Gjp::Pom do
  let(:pom) { Gjp::Pom.new(File.join("spec", "data", "commons-logging", "pom.xml")) }

  describe "#group_id" do
    it "reads the group id" do
      pom.group_id.should eq "commons-logging"
    end
  end

  describe "#artifact_id" do
    it "reads the artifact id" do
      pom.artifact_id.should eq "commons-logging"
    end
  end

  describe "#name" do
    it "reads artifact name" do
      pom.name.should eq "Commons Logging"
    end
  end

  describe "#version" do
    it "reads the version" do
      pom.version.should eq "1.1.1"
    end
  end

  describe "#description" do
    it "reads the description" do
      pom.description.should eq "Commons Logging is a thin adapter allowing configurable bridging to other,\n    " +
        "well known logging systems."
    end
  end

  describe "#url" do
    it "reads the url" do
      pom.url.should eq "http://commons.apache.org/logging"
    end
  end

  describe "#license_name" do
    it "reads the license name" do
      pom.license_name.should eq ""
    end
  end

  describe "#runtime_dependency_ids" do
    it "reads the dependency maven ids" do
      pom.runtime_dependency_ids.should eq []
    end
  end

  describe "#scm_connection" do
    it "reads the SCM connection address" do
      pom.scm_connection.should eq "scm:svn:http://svn.apache.org/repos/asf/commons/proper/" +
        "logging/tags/commons-logging-1.1.1"
    end
  end

  describe "#scm_url" do
    it "reads the SCM connection url" do
      pom.scm_url.should eq "http://svn.apache.org/repos/asf/commons/proper/logging/tags/commons-logging-1.1.1"
    end
  end
end

