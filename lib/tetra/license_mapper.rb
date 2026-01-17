# frozen_string_literal: true

module Tetra
  # Handles mapping raw license names to SPDX identifiers
  class LicenseMapper
    class << self
      def map(raw_name)
        return "unknown" if raw_name.nil? || raw_name.strip.empty?

        name = raw_name.strip
        mapping[name] || name
      end

      def reset!
        @mapping = nil
      end

      private

      def mapping
        @mapping ||= begin
          load_mapping
        rescue Errno::ENOENT, Psych::SyntaxError, Psych::DisallowedClass, IOError => e
          warn "Warning: failed to load license mapping from #{Tetra::LICENSE_MAP_PATH}: #{e.class}: #{e.message}"
          {}
        end
      end

      def load_mapping
        YAML.safe_load_file(Tetra::LICENSE_MAP_PATH) || {}
      end
    end
  end
end
