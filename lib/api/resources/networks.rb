# Groups

def group_count(opts)

  root = LibXML::XML::Node.new('group-count')
  root << Network.count.to_s

  doc = LibXML::XML::Document.new
  doc.root = root

  { :xml => doc }
end
