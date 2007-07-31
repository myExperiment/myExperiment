class MessagesController < ApplicationController
  before_filter :login_required
  
  # GET /messages
  # GET /messages.xml
  def index
    #@messages = Message.find(:all, :conditions => ["`to` = ?", current_user.id])
    @messages = current_user.messages_inbox

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @messages.to_xml }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.find(params[:id], :conditions => ["`to` = ? or `from` = ?", current_user.id, current_user.id])
    
    # update read_at datetime
    @message.read!

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @message.to_xml }
    end
  end

  # GET /messages/new
  def new
    # if params[:reply_id] is set, attempt to find the @reply or return nil if not-authorized
    (params[:reply_id] = nil unless 
      (@reply = Message.find(params[:reply_id], :conditions => ["`to` = ? or `from` = ?", current_user.id, current_user.id]))) if params[:reply_id]
    
    @message = Message.new
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(:from => User.find(current_user.id),
                           :to => User.find(params[:message][:to]),
                           :subject => params[:message][:subject],
                           :body => params[:message][:body],
                           :reply_id => params[:message][:reply_id],
                           :created_at => Time.now)
    
    # prevent spoofing of sender id
    errors = nil
    if @message.from.id.to_i != current_user.id.to_i
      errors = true
      @message.errors.add(:from, "Message sender must be currently logged in user")
    end
    
    respond_to do |format|
      if @message.save and !errors
        flash[:notice] = 'Message was successfully created.'
        format.html { redirect_to messages_url }
        format.xml  { head :ok } 
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors.to_xml }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id], :conditions => ["`to` = ?", current_user.id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url }
      format.xml  { head :ok }
    end
  end
end
