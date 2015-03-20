# encoding: UTF-8

module Tetra
  # adds methods to generate text files from an ERB template
  module Generatable
    # returns the template path
    def template_path
      File.join(File.dirname(__FILE__), "..", "template")
    end

    # generates content from an ERB template and an object binding
    # if destination_path is given, write it to that file, otherwise just
    # return it
    def generate(template_name, object_binding, destination_path = nil)
      erb = ERB.new(File.read(File.join(template_path, template_name)), nil, "<>")
      new_content =  erb.result(object_binding)

      unless destination_path.nil?
        File.open(destination_path, "w") { |io| io.write new_content }
      end

      new_content
    end
  end
end
