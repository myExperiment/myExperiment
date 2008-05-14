# myExperiment: app/helpers/packs_helper.rb
#
# Copyright (c) 2008 University of Manchester and the University of Southampton.
# See license.txt for details.

module PacksHelper
  def remove_item_button(pack_id, item_type, item_id)
    return link_to_remote delete_image("float: right; margin-left: 0.4em;", "Remove item from pack"),
                         :update => "packItems",
                         :url => { :controller => "Packs", :id => pack_id, :action => "destroy_item", :item_type => item_type, :item_id => item_id },
                         :method => :delete,
                         :complete => "Element.hide('refresh_indicator1'); new Effect.Highlight('packItems', { duration: 1.5 });",
                         :confirm => "Are you sure you want to remove this item from this pack?",
                         :loading => "Element.show('refresh_indicator1')"   
  end
  
  def edit_item_button(pack_id, item_type, item_id)
  end

  def user_and_created_at_bit(entry)
    return "<small>Added by <b>#{contributor(entry.user_id, 'User')}</b> on #{datetime entry.created_at, false}</small>"
  end
end
