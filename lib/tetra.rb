# encoding: UTF-8

# ruby standard library
require "digest/sha1"
require "English"
require "erb"
require "find"
require "forwardable"
require "logger"
require "open-uri"
require "pathname"
require "singleton"
require "text"

# third party libraries
require "clamp"
require "json"
require "nokogiri"
require "rest_client"
require "zip"
require "open4"

# logging
require "tetra/logger"

# facades to other programs
require "tetra/facades/process_runner"
require "tetra/facades/git"
require "tetra/facades/tar"

# internal, backend
require "tetra/version"
require "tetra/project"
require "tetra/pom"
require "tetra/version_matcher"
require "tetra/maven_website"
require "tetra/pom_getter"
require "tetra/source_getter"
require "tetra/kit_runner"
require "tetra/ant_runner"
require "tetra/maven_runner"
require "tetra/kit_checker"

# internal, package related
require "tetra/packages/archivable"
require "tetra/packages/speccable"
require "tetra/packages/scriptable"
require "tetra/packages/kit_package"
require "tetra/packages/package"

# internal, UI
require "tetra/commands/base"
require "tetra/commands/ant"
require "tetra/commands/download_maven_source_jars"
require "tetra/commands/dry_run"
require "tetra/commands/generate_all"
require "tetra/commands/generate_kit"
require "tetra/commands/generate_archive"
require "tetra/commands/generate_script"
require "tetra/commands/generate_spec"
require "tetra/commands/get_pom"
require "tetra/commands/get_source"
require "tetra/commands/init"
require "tetra/commands/list_kit_missing_sources"
require "tetra/commands/move_jars_to_kit"
require "tetra/commands/mvn"

require "tetra/main"
