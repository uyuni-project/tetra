# frozen_string_literal: true

require "spec_helper"

describe Tetra::PomGetter do
  let(:pom_getter) { Tetra::PomGetter.new }

  describe "#get_pom" do
    it "gets the pom from a jar" do
      dir_path = File.join("spec", "data", "commons-logging")
      jar_path = File.join(dir_path, "commons-logging-1.3.4.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_in_jar
      expect(File.exist?(path)).to be_truthy

      FileUtils.rm(path)
    end

    it "gets the pom from sha1" do
      dir_path = File.join("spec", "data", "antlr")
      jar_path = File.join(dir_path, "antlr-2.7.2.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_via_sha1
      expect(File.exist?(path)).to be_truthy

      FileUtils.rm(path)
    end

    it "gets the pom from a heuristic" do
      dir_path = File.join("spec", "data", "nailgun")
      jar_path = File.join(dir_path, "nailgun-0.7.1.jar")
      path, status = pom_getter.get_pom(jar_path)

      expect(status).to eq :found_via_heuristic
      expect(File.exist?(path)).to be_truthy

      FileUtils.rm(path)
    end
  end
end
