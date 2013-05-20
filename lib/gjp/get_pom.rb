# encoding: UTF-8

require 'zip/zip'

class PomGetter
  def self.get_pom(file)
    if File.directory?(file)
      pom_path = File.join(file, "pom.xml")
      if File.file?(pom_path)
        File.read(pom_path)
      end
    elsif File.file?(file)
      Zip::ZipFile.foreach(file) do |entry|
        if entry.name =~ /\/pom.xml$/
          return entry.get_input_stream.read
        end
      end
      nil
    end
  end
end
