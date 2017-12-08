# myExperiment: app/controllers/messages_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MessagesController < ApplicationController
  before_filter :login_required
  
  before_filter :find_and_auth_message, :only => [:show, :destroy]
  before_filter :find_and_auth_reply, :only => :new

  # declare sweepers and which actions should invoke them
  cache_sweeper :message_sweeper, :only => [ :create, :show, :destroy, :delete_all_selected ]
  
  # GET /messages
  def index
    # inbox
    @message_folder = "inbox"
    @messages = Message.where(["`to` = ? AND `deleted_by_recipient` = ?", current_user.id, false]).
                        order(produce_sql_ordering_string(params[:sort_by], params[:order]))
    
    @messages = @messages.paginate(:page => params[:page], :per_page => 20)

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /messages/sent
  def sent
    # outbox
    @message_folder = "outbox"
    @messages = Message.where(["`from` = ? AND `deleted_by_sender` = ?", current_user.id, false]).
                        order(produce_sql_ordering_string(params[:sort_by], params[:order]))
    
    @messages = @messages.paginate(:page => params[:page], :per_page => 20)

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
    
    if (message_folder == "inbox" && @message.deleted_by_recipient == true) ||
       (message_folder == "outbox" && @message.deleted_by_sender == true)
      render_404("Message not found.")
    else
      # message is found, and is not deleted by current_user -> show the message;
      # mark message as read if it is viewed by the receiver
      @message.read! if @message.to.to_i == current_user.id.to_i
        
      @message_folder = message_folder
      respond_to do |format|
        format.html {
          
        @lod_nir  = message_url(@message)
        @lod_html = message_url(:id => @message.id, :format => 'html')
        @lod_rdf  = message_url(:id => @message.id, :format => 'rdf')
        @lod_xml  = message_url(:id => @message.id, :format => 'xml')
          
          # show.rhtml
        }

        if Conf.rdfgen_enable
          format.rdf {
            render :inline => `#{Conf.rdfgen_tool} messages #{@message.id}`
          }
        end
      end  
    end
  end

  
  # GET /messages/new
  def new
    if params[:user_id] && params[:user_id].to_i == current_user.id.to_i
      # can't send a message to the user themself - error
      respond_to do |format|
        flash[:error] = "You cannot send a message to yourself"
        format.html { redirect_to new_message_path }
      end
    elsif (allowed_plus_timespan = ActivityLimit.check_limit(current_user, "internal_message", false))[0]
      # the user is allowed to send messages - limit not yet reached; show the new message screen 
      # (but the counter is not updated just yet - the user might not send the message after all,
      #  so this is a mere validation - which saves user from typing the message in and learning that
      #  it can't be set because of the limit, which is expired)
      if params[:reply_id]

        subject = @reply.subject
        subject = "RE: #{subject}" unless subject.starts_with?("RE: ")

        @message = Message.new(:to => @reply.from,
                               :reply_id => @reply.id,
                               :subject => subject,
                               :body => ActionController::Base.helpers.strip_tags(@reply.body.gsub(/^/, ">> ")))
      else
        @message = Message.new
      end
    else
      # no more messages can be sent because of the activity limit
      respond_to do |format|
        error_msg = "You can't send messages - your limit is reached, "
        if allowed_plus_timespan[1].nil?
          error_msg += "it will not be reset. Please contact #{Conf.sitename} administration for details."
        elsif allowed_plus_timespan[1] <= 60
          error_msg += "please try again within a couple of minutes"
        else
          error_msg += "it will be reset in " + formatted_timespan(allowed_plus_timespan[1])
        end
        
        flash[:error] = error_msg 
        format.html { redirect_to messages_path }
      end
    end
  end

  # POST /messages
  def create
    # check if sending is allowed and increment the message counter
    sending_allowed = ActivityLimit.check_limit(current_user, "internal_message")[0]
    
    if params[:message] && params[:message].kind_of?(Hash)
      if sending_allowed
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
      end
    else
      @message = Message.new
      errors = true
    end
    
    respond_to do |format|
      if sending_allowed && !errors && @message.save
        
        begin
          Notifier.deliver_new_message(@message, base_host) if @message.u_to.send_notifications?
        rescue Exception => e
          logger.error("ERROR: failed to send New Message email notification. Message ID: #{@message.id}")
          logger.error("EXCEPTION: " + e)
        end
        
        flash[:notice] = 'Message was successfully sent.'
        format.html { redirect_to messages_path }
      elsif !sending_allowed
        # when redirecting, the check will be carried out again, and full error message displayed to the user
        # (this is an unlikely event - can only happen when the user opens several "new message" pages one
        #  after another and then posts messages from each of them, rather than opening a new one for each
        #  message - therefore, it will not have significant performance effect on running the allowance check again)
        format.html { redirect_to new_message_path }
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

  def find_and_auth_message
    action = action_name == "show" ? "view" : action_name

    @message = Message.find_by_id(params[:id])
    if @message.nil?
      render_404("Message not found.")
    elsif !Authorization.check(action, @message, current_user)
      render_401("You are not authorized to #{action} this message.")
    end
  end

  def find_and_auth_reply
    if params[:reply_id]
      @reply = Message.find_by_id(params[:reply_id])
      if @reply.nil?
        render_404("Original message not found.")
      elsif !Authorization.check('view', @reply, current_user)
        render_401("You are not authorized to reply to this message.")
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
end
