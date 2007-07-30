class RelationshipsController < ApplicationController
  # GET /relationships
  # GET /relationships.xml
  def index
    @relationships = Relationship.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @relationships.to_xml }
    end
  end

  # GET /relationships/1
  # GET /relationships/1.xml
  def show
    @relationship = Relationship.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @relationship.to_xml }
    end
  end

  # GET /relationships/new
  def new
    @relationship = Relationship.new
  end

  # GET /relationships/1;edit
  def edit
    @relationship = Relationship.find(params[:id])
  end

  # POST /relationships
  # POST /relationships.xml
  def create
    @relationship = Relationship.new(params[:relationship])
    
    # set initial datetime
    @relationship.created_at = Time.now

    respond_to do |format|
      if @relationship.save
        flash[:notice] = 'Relationship was successfully created.'
        format.html { redirect_to relationship_url(@relationship) }
        format.xml  { head :created, :location => relationship_url(@relationship) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @relationship.errors.to_xml }
      end
    end
  end

  # PUT /relationships/1
  # PUT /relationships/1.xml
  def update
    @relationship = Relationship.find(params[:id])

    respond_to do |format|
      if @relationship.update_attributes(params[:relationship])
        flash[:notice] = 'Relationship was successfully updated.'
        format.html { redirect_to relationship_url(@relationship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @relationship.errors.to_xml }
      end
    end
  end

  # DELETE /relationships/1
  # DELETE /relationships/1.xml
  def destroy
    @relationship = Relationship.find(params[:id])
    @relationship.destroy

    respond_to do |format|
      format.html { redirect_to relationships_url }
      format.xml  { head :ok }
    end
  end
end
