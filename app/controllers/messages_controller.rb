class MessagesController < ApplicationController
  before_filter :authorize
  
  before_filter :find_message_by_to_or_from, :only => [:show]
  
  before_filter :find_message_by_to, :only => [:destroy]
  
  before_filter :find_reply_by_to, :only => [:new]
  
  # GET /messages
  # GET /messages.xml
  def index
    @messages = current_user.messages_inbox

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @messages.to_xml }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message.read! if @message.to.to_i == current_user.id.to_i
      
    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @message.to_xml }
    end
  end

  # GET /messages/new
  def new
    if params[:reply_id]
      @message = Message.new(:to => @reply.from,
                             :reply_id => @reply.id,
                             :subject => "RE: " + @reply.subject,
                             :body => @reply.body.split(/\n/).collect {|line| ">> #{line}"}.join) # there has to be a 'ruby-er' way of doing this?
    else
      @message = Message.new
    end
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])
    @message.from ||= current_user.id
    @message.created_at = Time.now
    
    # test for spoofing of "from" field
    unless @message.from.to_i == current_user.id.to_i
      errors = true
      @message.errors.add :from, "must be logged on"
    end
    
    begin
      # test for existance of reply_id
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
    
    respond_to do |format|
      if !errors and @message.save
        flash[:notice] = 'Message was successfully sent.'
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
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url }
      format.xml  { head :ok }
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
  
private

  def error(notice, message)
    flash[:notice] = notice
    (err = Message.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to messages_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
