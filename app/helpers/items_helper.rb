# myExperiment: app/helpers/items_helper.rb
#
# Copyright (c) 2007-2013 The University of Manchester, the University of
# Oxford, and the University of Southampton.  See license.txt for details.

module ItemsHelper

  def find_association(resource)

    is_folder = resource.is_folder
    is_proxy  = resource.is_proxy
    extension = resource.folder_entry.entry_name.split(".").last
    generic   = nil

    Conf.file_format_associations.each do |assoc|
      
      if is_folder
        return assoc if assoc["special"] == "folder"
        next
      end

      if is_proxy
        return assoc if assoc["special"] == "link"
        next
      end

      generic = assoc if assoc["special"] == "generic"

      if assoc["extensions"]
        return assoc if assoc["extensions"].include?(extension)
      end
    end

    generic
  end

  def user_link(uri)

    # Get absolute URI.
    uri = URI.parse(Conf.base_uri).merge(uri).to_s

    # Match it up with the users
    resource = parse_resource_uri(uri)

    if resource && resource[0] == User
      link_to(User.find(resource[1]).name, uri)
    else
      link_to(uri, uri)
    end
  end

  def resource_link(resource)

    if resource.kind_of?(Pack)
      return "<span class='resource-link'>#{image_tag("manhattan_studio/folder-closed_16.png")}" +
             " #{link_to(h(resource.label), polymorphic_path(resource))}</span>"
    end

    association = find_association(resource)

    image = "<img src='#{association["image"]}'>"

    if resource.is_proxy
      label = resource.proxy_for_path
    else
      label = resource.folder_entry.entry_name
    end

    uri = pack_items_path(resource.research_object.context) + "/" + resource.ore_path

    "<span class='resource-link'>#{image} #{link_to(h(label), uri)}</span>"
  end
end
