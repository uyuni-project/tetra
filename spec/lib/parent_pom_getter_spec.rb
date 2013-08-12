# encoding: UTF-8

require 'spec_helper'

describe Gjp::ParentPomGetter do
  let(:parent_pom_getter) { Gjp::ParentPomGetter.new }

  describe "#get_parent_pom" do
    it "gets the the parent of a pom" do
      dir_path = File.join("spec", "data", "commons-logging")
      pom_path = File.join(dir_path, "pom.xml")
      parent_pom_path = File.join(dir_path, "parent_pom.xml")
      parent_pom_getter.get_parent_pom(pom_path).should eq(File.read(parent_pom_path))
    end
  end
end
