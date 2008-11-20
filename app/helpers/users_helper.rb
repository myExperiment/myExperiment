# myExperiment: app/helpers/users_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module UsersHelper
  
  def remove_bookmarkable_url(bookmarkableType, bookmarkableID)
    url = ""
    
    case bookmarkableType
      when 'Blob'; url = favourite_delete_file_url(bookmarkableID)
      when 'Workflow'; url = favourite_delete_workflow_url(bookmarkableID)
      when 'Pack'; url = favourite_delete_pack_url(bookmarkableID)
      when 'Blog'; url = favourite_delete_blog_url(bookmarkableID)
      else;        url = nil;
    end
    
    return( url )
  end
  
end
