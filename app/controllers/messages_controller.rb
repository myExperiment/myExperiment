class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml
  def index
    @messages = Message.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @messages.to_xml }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml
  def show
    @message = Message.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @message.to_xml }
    end
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1;edit
  def edit
    @message = Message.find(params[:id])
  end

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])

    respond_to do |format|
      if @message.save
        flash[:notice] = 'Message was successfully created.'
        format.html { redirect_to message_url(@message) }
        format.xml  { head :created, :location => message_url(@message) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors.to_xml }
      end
    end
  end

  # PUT /messages/1
  # PUT /messages/1.xml
  def update
    @message = Message.find(params[:id])

    respond_to do |format|
      if @message.update_attributes(params[:message])
        flash[:notice] = 'Message was successfully updated.'
        format.html { redirect_to message_url(@message) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @message.errors.to_xml }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url }
      format.xml  { head :ok }
    end
  end
end
