# encoding: UTF-8

require "nokogiri"

# encapsulates a pom.xml file
class Pom
  def initialize(filename)
    @doc = Nokogiri::XML(File.read(filename))
    @doc.remove_namespaces!
  end
  
  def connection_address
    connection_nodes = @doc.xpath("//scm/connection/text()")    
    if connection_nodes.any?
      connection_nodes.first.to_s.sub(/^scm:/, "")
    end
  end
  
  def group_id
    @doc.xpath("project/groupId/text()").to_s
  end
  
  def artifact_id
    @doc.xpath("project/artifactId/text()").to_s
  end
  
  def version
    @doc.xpath("project/version/text()").to_s
  end
end
