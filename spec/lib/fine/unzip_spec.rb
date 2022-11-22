# encoding: UTF-8

require "spec_helper"

describe Tetra::Unzip do
  include Tetra::Mockers

  let(:zipfile) { File.join("spec", "data", "commons-cli-1.5.0-src.zip") }
  let(:unzip) { Tetra::Unzip.new }

  describe "#decompress"  do
    it "decompresses a file in a directory" do
      Dir.mktmpdir do |dir|
        unzip.decompress(zipfile, dir)

        files = Find.find(dir).to_a

        expect(files).to include("#{dir}/commons-cli-1.5.0-src/RELEASE-NOTES.txt")
      end
    end
  end
end
