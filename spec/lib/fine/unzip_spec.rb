# frozen_string_literal: true

require "spec_helper"

describe Tetra::Unzip do
  include Tetra::Mockers

  let(:zipfile) { File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.zip") }
  let(:unzip) { Tetra::Unzip.new }

  describe "#decompress"  do
    it "decompresses a file in a directory" do
      Dir.mktmpdir do |dir|
        unzip.decompress(zipfile, dir)

        files = Dir.glob(File.join(dir, "**", "*"), File::FNM_DOTMATCH)

        expect(files).to include("#{dir}/#{Tetra::CCOLLECTIONS}/DEVELOPERS-GUIDE.html")
      end
    end
  end
end
