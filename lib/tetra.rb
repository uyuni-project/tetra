# frozen_string_literal: true

# ruby standard library
require "digest/sha1"
require "English"
require "erb"
require "forwardable"
require "json"
require "logger"
require "net/http"
require "open3"
require "open-uri"
require "pathname"
require "rexml/document"
require "singleton"
require "stringio"
require "tempfile"
require "uri"

# third party libraries
require "clamp"
require "text"
require "yaml"
require "zip"

# base components
require "tetra/logger"
require "tetra/generatable"

# facades to other programs
require "tetra/facades/process_runner"
require "tetra/facades/git"
require "tetra/facades/ant"
require "tetra/facades/mvn"
require "tetra/facades/gradle"
require "tetra/facades/bash"
require "tetra/facades/unzip"
require "tetra/facades/tar"

# main internal classes
require "tetra/constants"
require "tetra/version"
require "tetra/project_initer"
require "tetra/project"
require "tetra/pom"
require "tetra/kit"
require "tetra/version_matcher"
require "tetra/maven_website"
require "tetra/pom_getter"

# package building
require "tetra/license_mapper"
require "tetra/packages/speccable"
require "tetra/packages/scriptable"
require "tetra/packages/kit_package"
require "tetra/packages/package"

# UI
require "tetra/ui/subcommand"
require "tetra/ui/dry_run_subcommand"
require "tetra/ui/generate_all_subcommand"
require "tetra/ui/generate_kit_subcommand"
require "tetra/ui/generate_script_subcommand"
require "tetra/ui/generate_spec_subcommand"
require "tetra/ui/get_pom_subcommand"
require "tetra/ui/init_subcommand"
require "tetra/ui/move_jars_to_kit_subcommand"
require "tetra/ui/patch_subcommand"
require "tetra/ui/change_sources_subcommand"
require "tetra/ui/main"
