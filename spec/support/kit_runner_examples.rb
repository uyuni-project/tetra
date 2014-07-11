# encoding: UTF-8

shared_examples_for Tetra::KitRunner do
  include Tetra::Mockers

  describe "#find_executable"  do
    it "finds an executable in kit" do
      executable_path = create_mock_executable("any")
      expect(@kit_runner.find_executable("any")).to eq executable_path
    end
    it "doesn't find a Maven executable in kit" do
      expect(@kit_runner.find_executable("any")).to be_nil
    end
  end
end
