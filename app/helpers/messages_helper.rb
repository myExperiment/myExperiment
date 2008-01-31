# myExperiment: app/helpers/messages_helper.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module MessagesHelper
  def reply_message_path(message)
    url_for :action => "new", :reply_id => message
  end
end
