# frozen_string_literal: true

require "spec_helper"
require "tetra/license_mapper"

describe "Tetra::LicenseMapper" do
  describe ".map" do
    it "maps known Maven license names to SPDX identifiers" do
      expect(Tetra::LicenseMapper.map("The Apache Software License, Version 2.0")).to eq("Apache-2.0")
      expect(Tetra::LicenseMapper.map("Eclipse Public License 1.0")).to eq("EPL-1.0")
      expect(Tetra::LicenseMapper.map("Mozilla Public License Version 2.0")).to eq("MPL-2.0")
      expect(Tetra::LicenseMapper.map("Common Development and Distribution License")).to eq("CDDL-1.0")
      expect(Tetra::LicenseMapper.map("The JSON License")).to eq("JSON")
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

    it "loads the mapping from the correct file path" do
      expect(File).to exist(Tetra::LICENSE_MAP_PATH)
    end
  end
end
