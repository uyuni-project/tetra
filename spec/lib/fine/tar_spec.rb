# frozen_string_literal: true

require "spec_helper"

describe Tetra::Tar do
  include Tetra::Mockers

  let(:zipfile) { File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.tar.gz") }
  let(:tar) { Tetra::Tar.new }

  describe "#decompress"  do
    it "decompresses a file in a directory" do
      Dir.mktmpdir do |dir|
        tar.decompress(zipfile, dir)

        files = Dir.glob(File.join(dir, "**", "*"), File::FNM_DOTMATCH)

        expect(files).to include("#{dir}/#{Tetra::CCOLLECTIONS}/DEVELOPERS-GUIDE.html")
      end
    end
  end
end
