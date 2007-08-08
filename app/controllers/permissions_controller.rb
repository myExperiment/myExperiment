class PermissionsController < ApplicationController
  # GET /permissions
  # GET /permissions.xml
  def index
    @permissions = Permission.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @permissions.to_xml }
    end
  end

  # GET /permissions/1
  # GET /permissions/1.xml
  def show
    @permission = Permission.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @permission.to_xml }
    end
  end

  # GET /permissions/new
  def new
    @permission = Permission.new
  end

  # GET /permissions/1;edit
  def edit
    @permission = Permission.find(params[:id])
  end

  # POST /permissions
  # POST /permissions.xml
  def create
    @permission = Permission.new(params[:permission])

    respond_to do |format|
      if @permission.save
        flash[:notice] = 'Permission was successfully created.'
        format.html { redirect_to permission_url(@permission) }
        format.xml  { head :created, :location => permission_url(@permission) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @permission.errors.to_xml }
      end
    end
  end

  # PUT /permissions/1
  # PUT /permissions/1.xml
  def update
    @permission = Permission.find(params[:id])

    respond_to do |format|
      if @permission.update_attributes(params[:permission])
        flash[:notice] = 'Permission was successfully updated.'
        format.html { redirect_to permission_url(@permission) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @permission.errors.to_xml }
      end
    end
  end

  # DELETE /permissions/1
  # DELETE /permissions/1.xml
  def destroy
    @permission = Permission.find(params[:id])
    @permission.destroy

    respond_to do |format|
      format.html { redirect_to permissions_url }
      format.xml  { head :ok }
    end
  end
end
