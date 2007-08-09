class ContributionsController < ApplicationController
  before_filter :authorize, :except => [:index, :show]
  
  before_filter :find_contributions, :only => [:index]
  before_filter :find_contribution_auth, :only => [:show, :edit, :update, :destroy]
  
  # GET /contributions
  # GET /contributions.xml
  def index
    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @contributions.to_xml }
    end
  end

  # GET /contributions/1
  # GET /contributions/1.xml
  def show
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
    @contribution.destroy

    respond_to do |format|
      format.html { redirect_to contributions_url }
      format.xml  { head :ok }
    end
  end
  
protected

  def find_contributions
    @contributions = Contribution.find(:all)
  end
  
  def find_contribution_auth
    begin
      contribution = Contribution.find(params[:id])
      
      if contribution.authorized?(action_name, (logged_in? ? current_user : nil))
        @contribution = contribution
      else
        error("Contribution not found (id not authorized)", "is invalid (not owner)")
      end
    rescue ActiveRecord::RecordNotFound
      error("Contribution not found", "is invalid")
    end
  end

private

  def error(notice, message, attr=:id)
    flash[:notice] = notice
    (err = Contribution.new.errors).add(attr, message)
    
    respond_to do |format|
      format.html { redirect_to contributions_url }
      format.xml { render :xml => err.to_xml }
    end
  end
end
