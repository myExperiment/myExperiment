class ContributionsController < ApplicationController
  # GET /contributions
  # GET /contributions.xml
  def index
    @contributions = Contribution.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @contributions.to_xml }
    end
  end

  # GET /contributions/1
  # GET /contributions/1.xml
  def show
    @contribution = Contribution.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @contribution.to_xml }
    end
  end

  # GET /contributions/new
  def new
    @contribution = Contribution.new
  end

  # GET /contributions/1;edit
  def edit
    @contribution = Contribution.find(params[:id])
  end

  # POST /contributions
  # POST /contributions.xml
  def create
    @contribution = Contribution.new(params[:contribution])

    respond_to do |format|
      if @contribution.save
        flash[:notice] = 'Contribution was successfully created.'
        format.html { redirect_to contribution_url(@contribution) }
        format.xml  { head :created, :location => contribution_url(@contribution) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contribution.errors.to_xml }
      end
    end
  end

  # PUT /contributions/1
  # PUT /contributions/1.xml
  def update
    @contribution = Contribution.find(params[:id])

    respond_to do |format|
      if @contribution.update_attributes(params[:contribution])
        flash[:notice] = 'Contribution was successfully updated.'
        format.html { redirect_to contribution_url(@contribution) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contribution.errors.to_xml }
      end
    end
  end

  # DELETE /contributions/1
  # DELETE /contributions/1.xml
  def destroy
    @contribution = Contribution.find(params[:id])
    @contribution.destroy

    respond_to do |format|
      format.html { redirect_to contributions_url }
      format.xml  { head :ok }
    end
  end
end
