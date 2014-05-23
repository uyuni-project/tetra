# encoding: UTF-8

module Gjp
  class ListKitMissingSourcesCommand < Gjp::BaseCommand

    def execute
      checking_exceptions do
        project = Gjp::Project.new(".")
        kit_checker = Gjp::KitChecker.new(project)

        ensure_dry_running(false, project) do
          puts "Some source files were not found in these archives:"
          kit_checker.unsourced_archives.each do |archive|
            percentage = "%.2f" % (100.0 * archive[:unsourced_class_names].length()/archive[:class_names].length())
            puts "#{format_path(archive[:archive], project)} (~#{percentage}% missing)"
          end
        end
      end
    end
  end
end
