# frozen_string_literal: true

require "spec_helper"

describe Tetra::Kit do
  include Tetra::Mockers

  before(:each) do
    create_mock_project
  end

  let(:instance) { Tetra::Kit.new(@project) }

  after(:each) do
    delete_mock_project
  end

  describe "#find_executable" do
    it "finds an executable in kit" do
      create_mock_executable("any")
      expect(instance.find_executable("any")).to eq mock_executable_dir("any")
    end

    it "doesn't find an executable in kit" do
      expect(instance.find_executable("any")).to be_nil
    end
  end
end
