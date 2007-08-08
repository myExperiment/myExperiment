class HyperlinksController < ApplicationController
  # GET /hyperlinks
  # GET /hyperlinks.xml
  def index
    @hyperlinks = Hyperlink.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @hyperlinks.to_xml }
    end
  end

  # GET /hyperlinks/1
  # GET /hyperlinks/1.xml
  def show
    @hyperlink = Hyperlink.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @hyperlink.to_xml }
    end
  end

  # GET /hyperlinks/new
  def new
    @hyperlink = Hyperlink.new
  end

  # GET /hyperlinks/1;edit
  def edit
    @hyperlink = Hyperlink.find(params[:id])
  end

  # POST /hyperlinks
  # POST /hyperlinks.xml
  def create
    @hyperlink = Hyperlink.new(params[:hyperlink])

    respond_to do |format|
      if @hyperlink.save
        flash[:notice] = 'Hyperlink was successfully created.'
        format.html { redirect_to hyperlink_url(@hyperlink) }
        format.xml  { head :created, :location => hyperlink_url(@hyperlink) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hyperlink.errors.to_xml }
      end
    end
  end

  # PUT /hyperlinks/1
  # PUT /hyperlinks/1.xml
  def update
    @hyperlink = Hyperlink.find(params[:id])

    respond_to do |format|
      if @hyperlink.update_attributes(params[:hyperlink])
        flash[:notice] = 'Hyperlink was successfully updated.'
        format.html { redirect_to hyperlink_url(@hyperlink) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @hyperlink.errors.to_xml }
      end
    end
  end

  # DELETE /hyperlinks/1
  # DELETE /hyperlinks/1.xml
  def destroy
    @hyperlink = Hyperlink.find(params[:id])
    @hyperlink.destroy

    respond_to do |format|
      format.html { redirect_to hyperlinks_url }
      format.xml  { head :ok }
    end
  end
end
