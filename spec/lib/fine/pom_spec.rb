# encoding: UTF-8

require "spec_helper"

describe Tetra::Pom do
  let(:commons_pom) { Tetra::Pom.new(File.join("spec", "data", "commons-logging", "pom.xml")) }
  let(:nailgun_pom) { Tetra::Pom.new(File.join("spec", "data", "nailgun", "pom.xml")) }
  let(:struts_apps_pom) { Tetra::Pom.new(File.join("spec", "data", "struts-apps", "pom.xml")) }

  describe "#group_id" do
    it "reads the group id" do
      expect(commons_pom.group_id).to eq "commons-logging"
      expect(nailgun_pom.group_id).to eq "com.martiansoftware"
      expect(struts_apps_pom.group_id).to eq ""
    end
  end

  describe "#artifact_id" do
    it "reads the artifact id" do
      expect(commons_pom.artifact_id).to eq "commons-logging"
      expect(nailgun_pom.artifact_id).to eq "nailgun-all"
      expect(struts_apps_pom.artifact_id).to eq "struts2-parent"
    end
  end

  describe "#name" do
    it "reads artifact name" do
      expect(commons_pom.name).to eq "Apache Commons Logging"
      expect(nailgun_pom.name).to eq "nailgun-all"
      expect(struts_apps_pom.name).to eq "Struts 2"
    end
  end

  describe "#version" do
    it "reads the version" do
      expect(commons_pom.version).to eq "1.3.4"
      expect(nailgun_pom.version).to eq "0.9.1"
      expect(struts_apps_pom.version).to eq "6.7.0"
    end
  end

  # rubocop:disable Layout/LineLength, Layout/TrailingWhitespace
  describe "#description" do
    it "reads the description" do
      expect(commons_pom.description).to eq "Apache Commons Logging is a thin adapter allowing configurable bridging to other,\n    well-known logging systems."
      expect(nailgun_pom.description).to eq "
        Nailgun is a client, protocol, and server for running Java programs 
        from the command line without incurring the JVM startup overhead. 
        Programs run in the server (which is implemented in Java), and are 
        triggered by the client (written in C), which handles all I/O.
    
        This project contains the server and examples.
    "
      expect(struts_apps_pom.description).to eq "Apache Struts 2"
    end
  end
  # rubocop:enable Layout/LineLength, Layout/TrailingWhitespace

  describe "#url" do
    it "reads the url" do
      expect(commons_pom.url).to eq "https://commons.apache.org/proper/commons-logging/"
      expect(nailgun_pom.url).to eq "http://martiansoftware.com/nailgun"
      expect(struts_apps_pom.url).to eq "https://struts.apache.org/"
    end
  end

  describe "#license_name" do
    it "reads the license name" do
      expect(commons_pom.license_name).to eq ""
      expect(nailgun_pom.license_name).to eq "The Apache Software License, Version 2.0"
      expect(struts_apps_pom.license_name).to eq "The Apache Software License, Version 2.0"
    end
  end

  describe "#runtime_dependency_ids" do
    it "reads the dependency maven ids" do
      expect(commons_pom.runtime_dependency_ids).to eq []
      expect(nailgun_pom.runtime_dependency_ids).to eq []
      expect(struts_apps_pom.runtime_dependency_ids).to eq []
    end
  end

  describe "#scm_connection" do
    it "reads the SCM connection address" do
      expect(commons_pom.scm_connection).to eq "scm:git:https://gitbox.apache.org/repos/asf/commons-logging"
      expect(nailgun_pom.scm_connection).to eq "scm:git:git@github.com:martylamb/nailgun.git"
      expect(struts_apps_pom.scm_connection).to eq "scm:git:https://gitbox.apache.org/repos/asf/struts.git"
    end
  end

  describe "#scm_url" do
    it "reads the SCM connection url" do
      expect(commons_pom.scm_url).to eq "https://gitbox.apache.org/repos/asf/commons-logging"
      expect(nailgun_pom.scm_url).to eq "scm:git:git@github.com:martylamb/nailgun.git"
      expect(struts_apps_pom.scm_url).to eq "https://github.com/apache/struts/"
    end
  end
end
