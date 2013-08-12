# encoding: UTF-8

require 'spec_helper'

describe Gjp::LimitedNetworkUser do
  let(:user) { Gjp::LimitedNetworkUser.new("nonet_test") }

  before(:each)  do
    user.set_up
  end

  after(:each)  do
    if user.set_up?
      user.tear_down
    end
  end

  describe "#set_up" do
    it "set_ups a limited network user" do
      user.set_up?.should be_true
    end
  end

  describe "#tear_down" do
    it "tears down a limited network user" do
      user.tear_down
      user.set_up?.should be_false
    end
  end

  describe "#set_up?" do
    it "checks if a limited network user has been set up" do
      user.set_up?.should be_true

      user.tear_down
      user.set_up?.should be_false
    end
  end
end
