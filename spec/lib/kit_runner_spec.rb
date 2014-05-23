# encoding: UTF-8

require "spec_helper"

shared_examples_for Gjp::KitRunner do
  include Gjp::Mockers

  describe "#find_executable"  do
    it "finds an executable in kit" do
      executable_path = create_mock_executable("any")
      @kit_runner.find_executable("any").should eq executable_path
    end
    it "doesn't find a Maven executable in kit" do
      @kit_runner.find_executable("any").should be_nil
    end
  end
end
