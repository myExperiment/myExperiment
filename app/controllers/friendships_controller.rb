class FriendshipsController < ApplicationController
  # GET /friendships
  # GET /friendships.xml
  def index
    @friendships = Friendship.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @friendships.to_xml }
    end
  end

  # GET /friendships/1
  # GET /friendships/1.xml
  def show
    @friendship = Friendship.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @friendship.to_xml }
    end
  end

  # GET /friendships/new
  def new
    @friendship = Friendship.new
  end

  # GET /friendships/1;edit
  def edit
    @friendship = Friendship.find(params[:id])
  end

  # POST /friendships
  # POST /friendships.xml
  def create
    @friendship = Friendship.new(params[:friendship])
    
    # set initial datetime
    @friendship.created_at = Time.now

    respond_to do |format|
      if @friendship.save
        flash[:notice] = 'Friendship was successfully created.'
        format.html { redirect_to friendship_url(@friendship) }
        format.xml  { head :created, :location => friendship_url(@friendship) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @friendship.errors.to_xml }
      end
    end
  end

  # PUT /friendships/1
  # PUT /friendships/1.xml
  def update
    @friendship = Friendship.find(params[:id])

    respond_to do |format|
      if @friendship.update_attributes(params[:friendship])
        flash[:notice] = 'Friendship was successfully updated.'
        format.html { redirect_to friendship_url(@friendship) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @friendship.errors.to_xml }
      end
    end
  end

  # DELETE /friendships/1
  # DELETE /friendships/1.xml
  def destroy
    @friendship = Friendship.find(params[:id])
    @friendship.destroy

    respond_to do |format|
      format.html { redirect_to friendships_url }
      format.xml  { head :ok }
    end
  end
end
