# encoding: UTF-8

module Tetra
  # generates file archives that accompany spec files
  class Archiver
    include Logging

    def initialize(project)
      @project = project
    end

    # generates an archive for the kit package
    def archive_kit(whole)
      destination_dir = File.join(@project.full_path, "output", "#{@project.name}-kit")
      FileUtils.mkdir_p(destination_dir)
      file_prefix = "#{@project.name}-kit"
      file_suffix = ".tar.xz"

      @project.take_snapshot "Kit archival started"

      destination_file = (
        if whole
          remove_stale_incremental(destination_dir, file_prefix, file_suffix)
          archive_single("kit", File.join(destination_dir, file_prefix + file_suffix))
        else
          log.debug "doing incremental archive"
          archive_incremental("kit", destination_dir, file_prefix, file_suffix, :archive_kit)
        end
      )

      @project.take_snapshot "Kit archive generated", :archive_kit

      destination_file
    end

    # generates an archive for a project's package based on its file list
    def archive_package(name)
      destination_dir = File.join(@project.full_path, "output", name)
      FileUtils.mkdir_p(destination_dir)
      destination_file = File.join(destination_dir, "#{name}.tar.xz")

      archive_single(File.join("src", name), destination_file)
    end

    # archives a directory's contents to the destination file
    def archive_single(source_directory, destination_file)
      log.debug "creating #{destination_file}"
      @project.from_directory source_directory do
        `tar -cJf #{destination_file} *`
      end

      destination_file
    end

    # archives a directory's changed contents since last time archive_incremental was called
    # uses snapshots with tag_prefix to keep track of calls to this method
    # destination files will be file_prefix_NNNN_file_suffix
    def archive_incremental(source_directory, destination_dir, file_prefix, file_suffix, tag_prefix)
      @project.from_directory do
        latest_tag_count = @project.latest_tag_count(tag_prefix)

        if latest_tag_count == 0
          archive_single(source_directory, File.join(destination_dir, file_prefix + file_suffix))
        else
          destination_file = File.join(destination_dir,
                                       "#{file_prefix}_#{format("%04d", latest_tag_count)}#{file_suffix}")
          tag = @project.latest_tag(tag_prefix)
          log.debug "creating #{destination_file} with files newer than #{tag}"

          log.debug "files that changed since then: #{@project.git.changed_files_since(tag)}"
          list = @project.git.changed_files_since(tag).select do |file|
            File.expand_path(file) =~ /^#{File.expand_path(source_directory)}\//
          end.map do |file|
            Pathname.new(file).relative_path_from Pathname.new(source_directory)
          end
          @project.from_directory source_directory do
            `tar -cJf #{destination_file} #{list.join(" ")}`
          end

          destination_file
        end
      end
    end

    # removes any stale incremental files
    def remove_stale_incremental(destination_dir, file_prefix, file_suffix)
      Dir.entries(destination_dir)
        .select { |f| f =~ /^#{file_prefix}_([0-9]+)#{file_suffix}$/ }
        .each do |f|
        log.debug "removing stale incremental archive #{f}"
        File.delete(File.join(destination_dir, f))
      end
    end
  end
end
