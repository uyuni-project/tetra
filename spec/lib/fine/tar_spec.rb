# encoding: UTF-8

require "spec_helper"

describe Tetra::Tar do
  include Tetra::Mockers

  let(:zipfile) { File.join("spec", "data", "#{Tetra::CCOLLECTIONS}.tar.gz") }
  let(:tar) { Tetra::Tar.new }

  describe "#decompress"  do
    it "decompresses a file in a directory" do
      Dir.mktmpdir do |dir|
        tar.decompress(zipfile, dir)

        files = Find.find(dir).to_a

        expect(files).to include("#{dir}/#{Tetra::CCOLLECTIONS}/DEVELOPERS-GUIDE.html")
      end
    end
  end
end
