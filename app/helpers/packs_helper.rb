# myExperiment: app/helpers/packs_helper.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module PacksHelper
  def remove_item_button(pack_id, entry_type, item_id)
    # return link_to_remote(delete_image("float: right; margin-left: 0.5em;", "Remove item from pack"),
    #                       :update => "packItems",
    #                       :url => { :controller => "Packs", :id => pack_id, :action => "destroy_item", :item_type => item_type, :item_id => item_id },
    #                       :method => :delete,
    #                       :complete => "Element.hide('refresh_indicator1'); new Effect.Highlight('packItems', { duration: 1.5 });",
    #                       :confirm => "Are you sure you want to remove this item from this pack?",
    #                       :loading => "Element.show('refresh_indicator1')")

    return link_to(delete_image("float: right; margin-left: 0.8em;", "Remove entry from pack"),
                   { :controller => "packs", :id => pack_id, :action => "destroy_item", :entry_type => entry_type, :entry_id => item_id },
                   :method => :delete,
                   :confirm => "Are you sure you want to remove this item from this pack?")
  end
  
  def edit_item_link(pack_id, entry_type, item_id)
    return url_for(:controller => "packs", :id => pack_id, :action => "edit_item", :entry_type => entry_type, :entry_id => item_id)
  end
  
  def edit_item_button(pack_id, entry_type, item_id)
    return link_to(edit_image("float: right; margin-left: 0.4em;", "Edit this entry"),
                   edit_item_link(pack_id, entry_type, item_id))
  end

  def user_and_created_at_bit(entry)
    return "<small>Added by <b>#{contributor(entry.user_id, 'User')}</b> ... #{timeago_fuzzy entry.created_at} (#{datetime entry.created_at, false})</small>"
  end
  
  def type_to_UI_text(type)
    return 'N/A' if type.blank?
    case type.downcase
      when 'contributable'
        return 'internal'
      when 'remote'
        return 'external'
      else
        return 'UNKNOWN'
    end
  end
  
  def contributable_entry_description(entry)
    desc = ""
    c = entry.get_contributable_version
    
    if c and c.respond_to?(:body)
      if c.body.blank?
        desc = '<p class="none_text">No description available</p>'
      else
        desc = white_list c.body_html
      end
    else
      desc = "ERROR: failed to retrieve description data."
    end
    
    return desc
  end
  
  def unique_tags_from_items(items)
    tags = [ ]
    
    items.each do |i|
      if (c = i.contributable) 
        if taggable?(c.class.to_s)
          c.tags.each do |t|
            unless tags.include?(t)
              tags << t
            end
          end
        end
      end
    end
    
    return tags
  end

  def pack_entry_link(entry)

    case entry.class.name
    when "PackContributableEntry"
      text = entry.contributable.label
      href = rest_resource_uri(entry.contributable)
    when "PackRemoteEntry"
      text = entry.title
      href = entry.uri
    end

    link_to(text, href)
  end

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
    association = find_association(resource)
      "<img src='#{association["image"]}'> #{link_to(h(resource.folder_entry.entry_name),
        pack_items_path(resource.research_object.pack) + "/" + resource.ore_path)}"
  end
end
