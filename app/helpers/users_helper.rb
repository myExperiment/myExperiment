# myExperiment: app/helpers/users_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module UsersHelper
  
  def remove_bookmarkable_path(bookmarkableType, bookmarkableID)
    url = ""
    
    case bookmarkableType
      when 'Blob'; url = favourite_delete_blob_path(bookmarkableID)
      when 'Workflow'; url = favourite_delete_workflow_path(bookmarkableID)
      when 'Pack'; url = favourite_delete_pack_path(bookmarkableID)
      else;        url = nil;
    end
    
    return( url )
  end

  def new_recaptcha_tags(opts)
    content_tag(:div, '', { :class => 'g-recaptcha', 'data-sitekey' => opts[:public_key] })
  end
end
