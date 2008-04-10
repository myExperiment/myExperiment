class SearchController < ApplicationController
  def show
    
    # Hacks for 'Groups' --> 'Networks' and 'Files' --> 'Blobs' renames
    
    if params[:type].to_s == 'groups'
      params[:type] = 'networks'
    end
    
    if params[:type].to_s == 'files'
      params[:type] = 'blobs'
    end

    error(params[:type]) unless @@valid_types.include? params[:type]
    
    if params[:type] == "all"
      search_all
    else
      redirect_to :controller => params[:type], :action => "search", :query => params[:query]
    end
  end
  
private

  @@valid_types = ["all", "workflows", "users", "networks", "blobs"]

  def error(type)
    flash[:notice] = "#{type} is an invalid search type"
    (err = BlogPost.new.errors).add(:type, "is an invalid type")
    
    respond_to do |format|
      format.html { redirect_to url_for(:controller => type) }
    end
  end

  def search_all
    
    @query = params[:query]

    @results = []

    if SOLR_ENABLE and not @query.nil? and @query != ""
      @results = User.multi_solr_search(@query, :limit => 100,
          :models => [User, Workflow, Blob, Network]).results
    end

    @users     = @results.select do |r| r.instance_of?(User)     end
    @workflows = @results.select do |r| r.instance_of?(Workflow) end
    @blobs     = @results.select do |r| r.instance_of?(Blob)     end
    @networks  = @results.select do |r| r.instance_of?(Network)  end

    respond_to do |format|
      format.html # search.rhtml
    end
  end
end
