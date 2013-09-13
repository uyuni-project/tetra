# encoding: UTF-8

require "erb"

module Gjp
  # operates on files in template/
  class TemplateManager
    include Logger

    attr_reader :template_path

    def initialize
      @template_path = File.join(File.dirname(__FILE__), "..", "template")
    end

    def copy(template_name, destination_dir)
      FileUtils.cp_r(File.join(template_path, template_name), destination_dir)
    end

    def generate(template_name, object_binding, destination_path)
      erb = ERB.new File.read(File.join(template_path, template_name)), nil, "<>"
      File.open(destination_path, "w") { |io| io.write erb.result(object_binding) }
    end
  end
end
