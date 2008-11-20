# myExperiment: app/controllers/messages_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MessagesController < ApplicationController
  before_filter :login_required
  
  before_filter :find_message_by_to_or_from, :only => [:show, :destroy]
  before_filter :find_reply_by_to, :only => [:new]

  # declare sweepers and which actions should invoke them
  cache_sweeper :message_sweeper, :only => [ :create, :show, :destroy, :delete_all_selected ]
  
  # GET /messages
  def index
    # inbox
    @message_folder = "inbox"
    @messages = Message.find(:all, 
                             :conditions => ["`to` = ? AND `deleted_by_recipient` = ?", current_user.id, false],
                             :order => produce_sql_ordering_string(params[:sort_by], params[:order]),
                             :page => { :size => 20, 
                                        :current => params[:page] })
    
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /messages/sent
  def sent
    # outbox
    @message_folder = "outbox"
    @messages = Message.find(:all, 
                             :conditions => ["`from` = ? AND `deleted_by_sender` = ?", current_user.id, false],
                             :order => produce_sql_ordering_string(params[:sort_by], params[:order]),
                             :page => { :size => 20, 
                                        :current => params[:page] })
    
    respond_to do |format|
      format.html # sent.rhtml
    end
  end


  # GET /messages/1
  def show
    # 'before_filter' for 'show' action finds the message based on "TO" || "FROM" fields;
    # the system won't allow to send a message to the user themself
    # (both through UI - neither in the form with selection of recipient, not with a direct link : /messages/new?user_id=X ).
    # 
    # therefore, it's possible to infer whether this message is in the inbox or in the outbox for current user,
    # and so check the relevant flag (for the message being deleted from inbox/outbox respectively)
    
    # if current_user is not recipient, they must be the sender
    message_folder = ( @message.recipient?(current_user.id) ? "inbox" : "outbox" )
    
    if (message_folder == "inbox" && @message.deleted_by_recipient == true)
      error("Message not found (id not authorized)", "is invalid (not sender or recipient)")
    elsif (message_folder == "outbox" && @message.deleted_by_sender == true)
      error("Message not found (id not authorized)", "is invalid (not sender or recipient)")
    else
      # message is found, and is not deleted by current_user -> show the message;
      # mark message as read if it is viewed by the receiver
      @message.read! if @message.to.to_i == current_user.id.to_i
        
      @message_folder = message_folder
      respond_to do |format|
        format.html # show.rhtml
      end  
    end
    
  end

  
  # GET /messages/new
  def new
    if params[:user_id] && params[:user_id].to_i == current_user.id.to_i
      # can't send a message to the user themself - error
      respond_to do |format|
        flash[:error] = "You cannot send a message to yourself"
        format.html { redirect_to new_message_url }
      end
    else
      if params[:reply_id]
        @message = Message.new(:to => @reply.from,
                               :reply_id => @reply.id,
                               :subject => "RE: " + @reply.subject,
                               :body => @reply.body.split(/\n/).collect {|line| ">> #{line}"}.join) # there has to be a 'ruby-er' way of doing this?
      else
        @message = Message.new
      end
    end
  end

  # POST /messages
  def create
    @message = Message.new(params[:message])
    @message.from ||= current_user.id
    
    # set initial datetimes
    @message.read_at = nil
    
    # test for spoofing of "from" field
    unless @message.from.to_i == current_user.id.to_i
      errors = true
      @message.errors.add :from, "must be logged on"
    end
    
    # test for existance of reply_id
    if @message.reply_id
      begin
        reply = Message.find(@message.reply_id) 
      
        # test that user is replying to a message that was actually received by them
        unless reply.to.to_i == current_user.id.to_i
          errors = true
          @message.errors.add :reply_id, "not addressed to sender"
        end
      rescue ActiveRecord::RecordNotFound
        errors = true
        @message.errors.add :reply_id, "not found"
      end
    end
    
    respond_to do |format|
      if !errors and @message.save
        
        begin
          Notifier.deliver_new_message(@message, base_host) if @message.u_to.send_notifications?
        rescue Exception => e
          puts "ERROR: failed to send New Message email notification. Message ID: #{@message.id}"
          puts "EXCEPTION: " + e
          logger.error("ERROR: failed to send New Message email notification. Message ID: #{@message.id}")
          logger.error("EXCEPTION: " + e)
        end
        
        flash[:notice] = 'Message was successfully sent.'
        format.html { redirect_to messages_url }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # DELETE /messages/1
  def destroy
    # determine, which flag to mark as deleted (sender|recipient), and if need to destroy the object;
    # (and where to go back after deletion)
    if (params[:deleted_from].nil? || params[:deleted_from].blank? || params[:deleted_from] == "inbox")
      @message.destroy if @message.mark_as_deleted!(true)
      return_to_path = messages_path
    else
      @message.destroy if @message.mark_as_deleted!(false)
      return_to_path = sent_messages_path
    end
     
    respond_to do |format|
      flash[:notice] = "Message was successfully deleted"
      format.html { redirect_to return_to_path }
    end
  end
  
  # DELETE /messages/delete_all_selected
  def delete_all_selected
    
    # determine, which flag to mark as deleted (sender|recipient), and where to go back after deletion
    if (params[:deleted_from].nil? || params[:deleted_from].blank? || params[:deleted_from] == "inbox")
      deleted_by_recipient = true
      return_to_path = messages_path
    else
      deleted_by_recipient = false
      return_to_path = sent_messages_path
    end
    
    ids = params[:msg_ids].delete("a-z_").to_s
    ids_arr = ids.split(";")
    counter = 0
    
    ids_arr.each { |msg_id|
      @message = Message.find(msg_id)
      @message.destroy if @message.mark_as_deleted!(deleted_by_recipient)
      counter += 1
    }
    
    respond_to do |format|
      flash[:notice] = "Successfully deleted #{counter} message(s)" # + pluralize (counter, "message")
      format.html { redirect_to return_to_path }
    end
  end
  
protected

  def find_message_by_to
    begin
      @message = Message.find(params[:id], :conditions => ["`to` = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Message not found (id not authorized)", "is invalid (not recipient)")
    end
  end
  
  def find_message_by_to_or_from
    begin
      @message = Message.find(params[:id], :conditions => ["`to` = ? OR `from` = ?", current_user.id, current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("Message not found (id not authorized)", "is invalid (not sender or recipient)")
    end
  end
  
  def find_reply_by_to
    if params[:reply_id]
      begin
        @reply = Message.find(params[:reply_id], :conditions => ["`to` = ?", current_user.id])
      rescue ActiveRecord::RecordNotFound
        error("Reply not found (id not authorized)", "is invalid (not recipient)")
      end
    end
  end
  
  def produce_sql_ordering_string(sort_by, order)
    # get required field for sorting by it from parameters;
    # sort by 'created_at' date in the case of unknown parameter
    case sort_by
      when "date";    ordering = "created_at"
      when "status";  ordering = "read_at"
      when "subject"; ordering = "subject"
      else;           ordering = "created_at"
    end
    
    # check if the default value needed
    if sort_by.blank?
      ordering = "created_at"
    end
    
    # get required sorting order from parameters;
    # ascending order will be used in case of unknown value of a parameter
    case order
      when "ascending";  ordering += " ASC"
      when "descending"; ordering += " DESC"
    end
    
    # check if the default value needed;
    # therefore, in the case of both parameters missing - we get sort by date descending;
    # if the sort_by parameter is present, but ordering missing - go ascending
    if order.blank?
      if sort_by.blank?
        ordering += " DESC"
      else
        ordering += " ASC"
      end
    end
  
    return ordering
  end
  
private

  def error(notice, message)
    flash[:error] = notice
    (err = Message.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to messages_url }
    end
  end
end
