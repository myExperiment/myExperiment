class OauthController < ApplicationController
  before_filter :login_required,:except=>[:request_token,:access_token,:test_request]
  before_filter :find_client_application_auth, :only=>[:show, :edit, :update, :destroy]
  before_filter :login_or_oauth_required,:only=>[:test_request]
  before_filter :verify_oauth_consumer_signature, :only=>[:request_token]
  before_filter :verify_oauth_request_token, :only=>[:access_token]
  # Uncomment the following if you are using restful_open_id_authentication
  skip_before_filter :verify_authenticity_token

  def request_token
    @token=current_client_application.create_request_token
    if @token
      render :text=>@token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def access_token
    @token=current_token.exchange!
    if @token
      render :text=>@token.to_query
    else
      render :nothing => true, :status => 401
    end
  end

  def test_request
    render :text=>params.collect{|k,v|"#{k}=#{v}"}.join("&")
  end

  def authorize
    @client_applications=current_user.client_applications
    @token=RequestToken.find_by_token params[:oauth_token]
    if @token.client_application.nil?
       if redirect_url
         redirect_to redirect_url+"?oauth_failure=1"
       else
         render :action=>"authorize_failure"
       end
    end
    @show_permissions=@token.client_application.permissions
    redirect_url=params[:oauth_callback]||@token.client_application.callback_url
    if (@token.client_application.key_type == 'System') || @client_applications.include?(@token.client_application)
      unless @token.invalidated?
        if request.post?
          if params[:authorize]=='1'
            @token.authorize!(current_user)
            if redirect_url
              redirect_to redirect_url+"?oauth_token=#{@token.token}"
            else
              render :action=>"authorize_success"
            end
          elsif params[:commit]=="Save Changes"
            @token.invalidate!
            if redirect_url
              redirect_to redirect_url+"?oauth_failure=1"
            else
              render :action=>"authorize_failure"
            end
          end
        end
      else
       if redirect_url
         redirect_to redirect_url+"?oauth_failure=1"
       else
         render :action=>"authorize_failure"
       end
      end
    else
       if redirect_url
         redirect_to redirect_url+"?oauth_failure=1"
       else
         render :action=>"authorize_failure"
       end
    end
  end

  def revoke
    @token=current_user.tokens.find_by_token params[:token]
    if @token
      @token.invalidate!
      flash[:notice]="You've revoked the token for #{@token.client_application.name}"
    end
    redirect_to oauth_url
  end

  def index
    @client_applications=current_user.client_applications
    @admin_client_applications=ClientApplication.find(:all, :conditions => ["user_id != ? and creator_id = ?", current_user.id, current_user.id])
    @tokens=current_user.tokens.find :all, :conditions=>'oauth_tokens.invalidated_at is null and oauth_tokens.authorized_at is not null'
  end

  def new
    @permissions = TABLES['REST'][:data]
    @permissions=@permissions.sort
    @client_application=ClientApplication.new
    @permissions_for=[]
  end

  def create
    @client_application=current_user.client_applications.build(params[:client_application])
    if @client_application.save
      if params[:key_permissions] 
        for key_permission in params[:key_permissions] do
          @key_permission = KeyPermission.new(:client_application_id => @client_application.id, :for => key_permission[0])
          @key_permission.save
        end
      end
      flash[:notice]="Client Application successfully registered!"
      redirect_to :action=>"show",:id=>@client_application.id
    else
      render :action=>"new"
    end
  end

  def show
    if (!(@client_application.user_id == current_user.id or @client_application.creator_id == current_user.id))
      @client_application = nil
    end
    @show_permissions=@client_application.permissions
  end

  def edit
    @permissions = TABLES['REST'][:data]
    @permissions=@permissions.sort
    if (!(@client_application.user_id == current_user.id or @client_application.creator_id == current_user.id))
        @client_application = nil
    end
    @permissions_for=@client_application.permissions_for
    unless @client_application.nil?
      @show_permissions=@client_application.permissions
    end
  end

  def update
    if (current_user.admin? or @client_application.key_type=="User")
      @client_application.permissions.delete_all
      if params[:key_permissions] 
        for key_permission in params[:key_permissions] do
          @key_permission = KeyPermission.new(:client_application_id => @client_application.id, :for => key_permission[0])
           @key_permission.save
        end
      end
    end
    if @client_application.update_attributes(params[:client_application])
      flash[:notice]="Client Application '#{@client_application.name}' successfully updated!"
      redirect_to :action=>"show",:id=>@client_application.id
    else
      render :action=>"edit"
    end
  end

  def destroy
    client_application_name=@client_application.name
    @client_application.destroy
    flash[:notice]="Registration for Client Application '#{client_application_name}' has been removed!"
    redirect_to :action=>"index"
  end

private

  def find_client_application_auth
    if action_name == 'update'
      id = params[:client_application][:id]
    else
      id = params[:id]
    end
    begin
      client_app=ClientApplication.find(id)
      if Authorization.is_authorized?(action_name, nil, client_app, current_user)
        @client_application = client_app
      else
        error("Client Application not found (id not authorized)", "is invalid (not authorized)")
        return false
      end
    rescue ActiveRecord::RecordNotFound
      error("Client Application not found", "is invalid")
      return false
    end
  end

  def error(notice, message, attr=:id)
    flash[:error] = notice

    respond_to do |format|
      format.html { redirect_to oauth_url }
    end
  end
end
