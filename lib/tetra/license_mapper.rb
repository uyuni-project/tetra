# frozen_string_literal: true

module Tetra
  # Handles mapping raw license names to SPDX identifiers
  class LicenseMapper
    def self.map(raw_name)
      return "unknown" if raw_name.nil?

      @mapping ||= YAML.safe_load_file(Tetra::LICENSE_MAP_PATH)

      # Strip whitespace
      key = raw_name.strip

      # Return the mapped SPDX ID, or the original name if no match found
      @mapping[key] || key
    end
  end
end
