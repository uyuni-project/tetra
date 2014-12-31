# encoding: UTF-8

module Tetra
  # tetra list-kit-missing-sources
  class ListKitMissingSourcesCommand < Tetra::BaseCommand
    def execute
      checking_exceptions do
        project = Tetra::Project.new(".")
        kit_checker = Tetra::KitChecker.new(project)

        ensure_dry_running(false, project) do
          puts "Some source files were not found in these archives:"
          kit_checker.unsourced_archives.each do |archive|
            percentage = 100.0 * archive[:unsourced_class_names].length / archive[:class_names].length
            puts "#{format_path(archive[:archive], project)} (~#{format('%.2f', percentage)}% missing)"
          end
        end
      end
    end
  end
end
