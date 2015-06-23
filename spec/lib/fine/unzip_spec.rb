# encoding: UTF-8

require "spec_helper"

describe Tetra::Unzip do
  include Tetra::Mockers

  let(:zipfile) { File.join("spec", "data", "commons-collections-3.2.1-src.zip") }
  let(:unzip) { Tetra::Unzip.new }

  describe "#decompress"  do
    it "decompresses a file in a directory" do
      Dir.mktmpdir do |dir|
        unzip.decompress(zipfile, dir)

        files = Find.find(dir).to_a

        expect(files).to include("#{dir}/commons-collections-3.2.1-src/DEVELOPERS-GUIDE.html")
      end
    end
  end
end
