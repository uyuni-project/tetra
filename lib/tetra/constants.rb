# frozen_string_literal: true

# base module for tetra
module Tetra
  CCOLLECTIONS = "commons-collections4-4.5.0-M2-src".freeze
  CHUNK_SEPARATOR_VERSION_MATCHER = /[.\-_ ~,]/ # Constant regex for splitting version chunks
  LICENSE_MAP_PATH = File.join(__dir__, "data", "license_map.yml").freeze
end
