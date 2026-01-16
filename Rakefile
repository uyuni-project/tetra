# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

# Defines the 'spec' task to run RSpec tests
RSpec::Core::RakeTask.new(:spec)

# Set the default task to 'spec'
task default: :spec

# Maintain 'test' as an alias for 'spec' for backward compatibility
task test: :spec
