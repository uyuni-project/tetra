# frozen_string_literal: true

module Tetra
  # represents a Java project packaged in tetra
  class Package
    extend Forwardable
    include Speccable
    include Scriptable

    attr_reader :patches

    def_delegator :@project, :name
    def_delegator :@project, :src_archive
    def_delegator :@kit, :name, :kit_name
    def_delegator :@kit, :version, :kit_version
    def_delegator :@pom, :url
    def_delegator :@pom, :group_id
    def_delegator :@pom, :version
    def_delegator :@pom, :runtime_dependency_ids

    def initialize(project, pom_path = nil, filter = nil, patches = [])
      @project = project
      @kit = Tetra::KitPackage.new(project)
      @pom = Tetra::Pom.new(pom_path)
      @filter = filter
      @patches = patches.map { |f| File.basename(f) }
    end

    def license
      Tetra::LicenseMapper.map(@pom.license_name)
    end

    # Scans for license files in the src/ directory (Issue #12)
    def license_files
      @project.from_directory do
        # Tetra unpacks sources into 'src/', so we search there.
        # We manually check filenames with Ruby regex to ensure reliable
        # case-insensitive matching across different OS filesystems (Linux vs macOS).

        candidates = Dir.glob("src/*")

        files = candidates.select do |file|
          next unless File.file?(file)

          basename = File.basename(file)

          # Match standard license filenames (case insensitive)
          # Equivalent to: LICENSE*, COPYING*, COPYRIGHT*
          basename.match?(/^LICENSE/i) ||
            basename.match?(/^COPYING/i) ||
            basename.match?(/^COPYRIGHT/i)
        end

        # Return just the filenames (e.g. "LICENSE") so the spec file
        # (which runs inside src/ due to %setup -n src) can reference them directly.
        files.map { |f| File.basename(f) }.uniq.sort
      end
    end

    def artifact_ids
      @pom.modules.any? ? @pom.modules : [@pom.artifact_id]
    end

    # a short summary from the POM
    def summary
      cleanup_description(@pom.description, 60)
    end

    # a long summary from the POM
    def description
      cleanup_description(@pom.description, 1500)
    end

    # files produced by this package
    def outputs
      @project.produced_files.select do |file|
        File.fnmatch?(@filter, File.basename(file))
      end
    end

    def cleanup_description(raw, max_length)
      return "" if raw.nil? || raw.strip.empty?

      # Normalize spaces (collapse multiple spaces/newlines to single space)
      clean = raw.gsub(/\s+/, " ").strip

      # Truncate to max_length
      clean = clean[0, max_length]

      # Remove the last word if it looks cut off (ends in letters, not punctuation)
      clean = clean.sub(/\s\w+\z/, "")

      # Remove ALL trailing dots efficiently
      clean = clean.chomp(".") while clean.end_with?(".")

      clean
    end

    def to_spec
      _to_spec(@project, name, "package.spec", @project.packages_dir)
    end

    def to_script
      _to_script(@project)
    end
  end
end
