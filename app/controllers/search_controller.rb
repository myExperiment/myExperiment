class SearchController < ApplicationController
  def show
    error(params[:type]) unless @@valid_types.include? params[:type]
    
    redirect_to :controller => params[:type], :action => "search", :query => params[:query]
  end
  
private

  @@valid_types = ["workflows", "users", "networks"]

  def error(type)
    flash[:notice] = "#{type} is an invalid search type"
    (err = BlogPost.new.errors).add(:type, "is an invalid type")
    
    respond_to do |format|
      format.html { redirect_to url_for(:controller => type) }
      format.xml { render :xml => err.to_xml }
    end
  end
end
