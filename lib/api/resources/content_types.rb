# Content Types

def content_type_count(opts)

  root = LibXML::XML::Node.new('type-count')
  root << ContentType.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
