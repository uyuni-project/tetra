# frozen_string_literal: true

# base module for tetra
module Tetra
  CCOLLECTIONS = "commons-collections4-4.5.0-M2-src".freeze
  CHUNK_SEPARATOR_VERSION_MATCHER = /[.\-_ ~,]/ # Constant regex for splitting version chunks
  LICENSE_MAP_PATH = File.join(__dir__, "data", "license_map.yml").freeze
  LICENSE_MAPPINGS = {
    "The Apache Software License, Version 2.0" => "Apache-2.0",
    "The MIT License" => "MIT",
    "Eclipse Public License 1.0" => "EPL-1.0",
    "GNU General Public License, version 2" => "GPL-2.0-only",
    "GNU Lesser General Public License" => "LGPL-2.1-only"
  }.freeze
end
