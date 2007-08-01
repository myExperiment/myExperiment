class MessagesController < ApplicationController
  before_filter :authorize
  
  verify :method => :post, :only => [:create],
         :redirect_to => { :action => :index }
         
  verify :method => :get, :only => [:index, :show, :new],
         :redirect_to => { :action => :index }
         
  verify :method => :delete, :only => [:destroy],
         :redirect_to => { :action => :index }
  
  
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
    begin
      @message = Message.find(params[:id], :conditions => ["`to` = ? or `from` = ?", current_user.id, current_user.id])
    
      @message.read! if @message.to.to_i == current_user.id.to_i
      
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @message.to_xml }
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Message not found (id not authorized)"
      (@message = Message.new).errors.add(:id, "is invalid (not receiver)")
                
      respond_to do |format|
        format.html { redirect_to messages_url }
        format.xml { render :xml => @message.errors.to_xml }
      end
    end
  end

  # GET /messages/new
  def new
    if params[:reply_id]
      begin
        reply = Message.find(params[:reply_id], :conditions => ["`to` = ?", current_user.id])
        
        @message = Message.new(:to => reply.from,
                               :reply_id => reply.id,
                               :subject => "RE: " + reply.subject,
                               :body => reply.body.split(/\n/).collect {|line| ">> #{line}"}.join) # there has to be a 'ruby-er' way of doing this?
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "Message not found (id not authorized)"
        (@message = Message.new).errors.add(:reply_id, "not found")
                
        respond_to do |format|
          format.html { redirect_to messages_url }
          format.xml { render :xml => @message.errors.to_xml }
        end
      end
    else
      @message = Message.new
    end
    
    # if the message is a reply
    @reply = (params[:reply_id] && Message.find(params[:reply_id], :conditions => ["`to` = ?", current_user.id])) || nil 
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
        @message.errors.add :reply_id, "was not addressed to sender"
      end
    rescue ActiveRecord::RecordNotFound
      errors = true
      @message.errors.add :reply_id, "not found"
    end
    
    respond_to do |format|
      if @message.save or !errors
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
    begin
      @message = Message.find(params[:id], :conditions => ["`to` = ?", current_user.id])
      @message.destroy

      respond_to do |format|
        format.html { redirect_to messages_url }
        format.xml  { head :ok }
      end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Message not found (id not authorized)"
      (@message = Message.new).errors.add(:id, "is invalid (not receiver)")
                
      respond_to do |format|
        format.html { redirect_to messages_url }
        format.xml { render :xml => @message.errors.to_xml }
      end
    end
  end
end
