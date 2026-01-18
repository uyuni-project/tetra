# frozen_string_literal: true

require "spec_helper"

describe "Tetra::LicenseMapper" do
  describe ".map" do
    it "maps known Maven license names to SPDX identifiers" do
      expect(Tetra::LicenseMapper.map("The Apache Software License, Version 2.0")).to eq("Apache-2.0")
      expect(Tetra::LicenseMapper.map("Eclipse Public License 1.0")).to eq("EPL-1.0")
    end

    it "handles whitespace around the license name" do
      expect(Tetra::LicenseMapper.map("  Apache License, Version 2.0  ")).to eq("Apache-2.0")
    end

    it "returns the original name if no mapping is found" do
      expect(Tetra::LicenseMapper.map("My Custom Proprietary License")).to eq("My Custom Proprietary License")
    end

    it "returns 'unknown' for nil input" do
      expect(Tetra::LicenseMapper.map(nil)).to eq("unknown")
    end

    it "returns 'unknown' for empty string input" do
      expect(Tetra::LicenseMapper.map("")).to eq("unknown")
    end

    it "returns 'unknown' for whitespace-only input" do
      expect(Tetra::LicenseMapper.map("   ")).to eq("unknown")
      expect(Tetra::LicenseMapper.map("\t\n")).to eq("unknown")
    end

    it "loads the mapping from the correct file path" do
      expect(File).to exist(Tetra::LICENSE_MAP_PATH)
    end

    context "when the mapping file is missing" do
      it "warns the user and returns the original name" do
        allow(Tetra::LicenseMapper).to receive(:load_mapping).and_raise(Errno::ENOENT)

        expect do
          expect(Tetra::LicenseMapper.map("Some License")).to eq("Some License")
        end.to output(/Warning: failed to load license mapping/).to_stderr
      end
    end

    context "when the mapping file is corrupted (invalid YAML)" do
      it "warns the user and handles the Psych error gracefully" do
        allow(Tetra::LicenseMapper).to receive(:load_mapping)
          .and_raise(Psych::SyntaxError.new("", 0, 0, 0, "", ""))

        expect do
          expect(Tetra::LicenseMapper.map("Some License")).to eq("Some License")
        end.to output(/Psych::SyntaxError/).to_stderr
      end
    end

    context "when the mapping file is empty" do
      it "returns the original name without crashing" do
        allow(Tetra::LicenseMapper).to receive(:load_mapping).and_return({})

        expect(Tetra::LicenseMapper.map("Some License")).to eq("Some License")
      end
    end
  end
end
