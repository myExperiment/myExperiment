module MessagesHelper
  def reply_message_path(message)
    url_for :action => "new", :reply_id => message
  end
end
