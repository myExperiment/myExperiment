# myExperiment: app/controllers/networks_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class NetworksController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :search, :all]
  
  before_filter :find_networks, :only => [:all]
  before_filter :find_network, :only => [:membership_request, :show, :comment, :comment_delete, :tag]
  before_filter :find_network_auth, :only => [:invite, :membership_invite, :membership_invite_external, :edit, :update, :destroy]
  
  before_filter :invalidate_listing_cache, :only => [:update, :comment, :comment_delete, :tag, :destroy]
  before_filter :invalidate_tags_cache, :only => [:create, :update, :delete, :tag]

  # declare sweepers and which actions should invoke them
  cache_sweeper :network_sweeper, :only => [ :create, :update, :destroy, :membership_request, :membership_invite, :membership_invite_external ]
  cache_sweeper :membership_sweeper, :only => [ :destroy, :membership_request, :membership_invite, :membership_invite_external ]
  cache_sweeper :tag_sweeper, :only => [ :tag, :destroy ]
  
  # GET /networks;search
  def search

    @query = params[:query]
    
    @networks = SOLR_ENABLE ? Network.find_by_solr(@query, :limit => 100).results : []
    
    respond_to do |format|
      format.html # search.rhtml
    end
  end
  
  # GET /networks/1;invite
  def invite
    respond_to do |format|
      format.html # invite.rhtml
    end
  end
  
  # POST /networks/1;membership_invite
  def membership_invite
            
    if (@membership = Membership.new(:user_id => params[:user_id], :network_id => @network.id, :message => params[:membership][:message]) unless Membership.find_by_user_id_and_network_id(params[:user_id], @network.id) or Network.find(@network.id).owner? params[:user_id])
      
      @membership.user_established_at = nil
      @membership.network_established_at = nil
      if @membership.message.blank?
        @membership.message = nil
      end
        
      respond_to do |format|
        if @membership.save
  
          @membership.network_establish!
          
          begin
            user = @membership.user
            Notifier.deliver_membership_invite(user, @membership.network, @membership, base_host) if user.send_notifications?
          rescue Exception => e
            puts "ERROR: failed to send Membership Invite email notification. Membership ID: #{@membership.id}"
            puts "EXCEPTION:" + e
            logger.error("ERROR: failed to send Membership Invite email notification. Membership ID: #{@membership.id}")
            logger.error("EXCEPTION:" + e)
          end
  
          flash[:notice] = 'An invitation has been sent to the User.'
          format.html { redirect_to group_url(@network) }
        else
          flash[:error] = 'Failed to send invitation to User. Please try again or report this.'
          format.html { redirect_to invite_group_url(@network) }
        end
      end
    else
      if params[:user_id].to_i == current_user.id
        flash[:error] = "You can't invite yourself to groups"
      else
        flash[:error] = "User invited is already a member of the group"
      end
      respond_to do |format|
        format.html { redirect_to invite_group_url(@network) }
      end
    end
  end
  
  # POST /networks/1;membership_invite_external
  def membership_invite_external
    # first of all, check that captcha was entered correctly
    if !captcha_valid?(params[:invitations][:captcha_id], params[:invitations][:captcha_validation])
      respond_to do |format|
        flash.now[:error] = 'Verification text was not entered correctly - your invitations have not been sent.'
        format.html { render :action => 'invite' }
      end
    else
      # captcha verified correctly, can proceed
    
      addr_count, validated_addr_count, valid_addresses, db_user_addresses, err_addresses, overflow_addresses = Invitation.validate_address_list(params[:invitations][:address_list])
      existing_invitation_emails = []
      valid_addresses_tokens = {} # a hash for pairs of 'email' => 'token'
      
      if validated_addr_count > 0
        emails_counter = 0; counter = 0
             
        # store requests in the DB (but just for those that are not present there yet)
        valid_addresses.each do |email_addr|
          if PendingInvitation.find_by_email_and_request_type_and_request_for(email_addr, "membership", params[:id])
            existing_invitation_emails << email_addr
          else 
            token_code = Digest::SHA1.hexdigest( email_addr.reverse + SECRET_WORD )
            valid_addresses_tokens[email_addr] = token_code
            invitation = PendingInvitation.new(:email => email_addr, :request_type => "membership", :requested_by => current_user.id, :request_for => params[:id], :message => params[:invitations][:msg_text], :token => token_code)
            invitation.save
          end        
        end
          
        # update the actual number of validated addresses
        validated_addr_count = valid_addresses_tokens.length
          
        # send out invitation emails, if there are any successful emails in 'valid_addresses_tokens'
        unless valid_addresses.empty?
          Invitation.send_invitation_emails("group_invite", base_host, User.find(current_user.id), valid_addresses_tokens, params[:invitations][:msg_text], params[:id])  
        end
      end    
      
      # process those addresses that are ones of existing users (not as the current user assumed them to be as new)
      own_address_err = ""
      existing_db_addr_existing_membership_err_list = []
      existing_db_addr_successful_membership_invites_list = []
      
      db_user_addresses.each { |db_addr, usr_id|
        if db_addr == current_user.email
          own_address_err += db_addr
        elsif Network.find(params[:id]).member?(usr_id) || User.find(usr_id).membership_pending?(params[:id]) # email doesn't belong to current user
          # the invited user is already a member of that group
          existing_db_addr_existing_membership_err_list << db_addr
        else
          # need to create internal membership invite, as one not yet exists
          existing_db_addr_successful_membership_invites_list << db_addr
          req = Membership.new(:user_id => usr_id, :network_id => params[:id], :user_established_at => nil, :network_established_at => Time.now, :message => params[:invitations][:msg_text])
          req.save
        end
      }
  
      
      # in future, potentially there's going to be a way to get results of sending;
      # now display message based on number of valid / invalid addresses..
      error_occurred = true # a flag to select where to redirect from this action
      respond_to do |format|
        if validated_addr_count == 0 && existing_invitation_emails.empty? && db_user_addresses.empty?
          error_msg = "None of the supplied address(es) could be validated, no emails were sent. Please try again!<br/>You have supplied the following address list:<br/>\"#{params[:invitations][:address_list]}\""
        elsif (addr_count == validated_addr_count) && (!err_addresses || err_addresses.empty?)
          error_msg = validated_addr_count.to_s + " Invitation email(s) sent successfully"
          error_occurred = false
        else 
          # something went wrong, so will assemble complex error message
          error_msg = (valid_addresses_tokens.empty? ? "No invitation emails were sent." : "Some invitations email(s) were sent successfully.") + " See errors below.<span style='color: red;'>"
          
          unless own_address_err.blank?
            error_msg += "<br/><br/>Can't send invitation to your own registered email address: <br/>" + own_address_err
          end
          
          unless existing_db_addr_existing_membership_err_list.empty?
            error_msg += "<br/><br/>There are existing or pending memberships for users with the following email addresses and this group (no invitations were sent): <br/>" + existing_db_addr_existing_membership_err_list.join("<br/>")
          end
          
          unless existing_db_addr_successful_membership_invites_list.empty?
            error_msg += "<br/><br/>People with the following email addresses are existing users, internal membership invites were sent instead of emails: <br/>" + existing_db_addr_successful_membership_invites_list.join("<br/>")
          end
                  
          unless existing_invitation_emails.empty?
            error_msg += "<br/><br/>Invitations to the following address(es) have not been sent now because this was already done earlier:<br/>" + existing_invitation_emails.join("<br/>") 
          end
          
          unless err_addresses.empty?
            error_msg += "<br/><br/>The following address(es) could not be validated:<br/>" + err_addresses.join("<br/>") 
          end
          
          unless overflow_addresses.empty?
            error_msg += "<br/><br/>You can only send invitations to #{INVITATION_EMAIL_LIMIT} unique, valid, non-blank email addresses.<br/>The following addresses were not processed because of maximum allowed amount was exceeded:<br/>" + overflow_addresses.join("<br/>")
          end
          
          error_msg += "</span>"
          params[:invitations][:address_list] = err_addresses.join("; ")
        end
        
        # depending on the flag, load appropriate page
        if error_occurred
          flash.now[:notice] = error_msg
          format.html { render :action => 'invite' }
        else      
          flash[:notice] = error_msg
          format.html { redirect_to group_path(params[:id]) }
        end
      end
    end
  end
  
  # GET /networks/1;membership_request
  def membership_request
    redirect_to :controller => 'memberships', 
                :action => 'new', 
                :user_id => current_user.id,
                :network_id => @network.id
  end
  
  # GET /networks
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /networks/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /networks/1
  def show
    @shared_items = @network.shared_contributions
    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /networks/new
  def new
    @network = Network.new(:user_id => current_user.id)
  end

  # GET /networks/1;edit
  def edit
    
  end

  # POST /networks
  def create
    @network = Network.new(params[:network])

    respond_to do |format|
      if @network.save
        if params[:network][:tag_list]
          @network.tags_user_id = current_user
          @network.tag_list = convert_tags_to_gem_format params[:network][:tag_list]
          @network.update_tags
        end
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to group_url(@network) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /networks/1
  def update
    respond_to do |format|
      if @network.update_attributes(params[:network])
        @network.refresh_tags(convert_tags_to_gem_format(params[:network][:tag_list]), current_user) if params[:network][:tag_list]
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to group_url(@network) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /networks/1
  def destroy
    @network.destroy

    respond_to do |format|
      flash[:notice] = 'Group was successfully deleted.'
      format.html { redirect_to groups_url }
    end
  end
  
  # POST /networks/1;comment
  def comment
    text = params[:comment][:comment]
    
    if text and text.length > 0
      comment = Comment.create(:user => current_user, :comment => text)
      @network.comments << comment
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @network } }
    end
  end
  
  # DELETE /networks/1;comment_delete
  def comment_delete
    if params[:comment_id]
      comment = Comment.find(params[:comment_id].to_i)
      # security checks:
      if comment.user_id == current_user.id and comment.commentable_type.downcase == 'network' and comment.commentable_id == @network.id
        comment.destroy
      end
    end
    
    respond_to do |format|
      format.html { render :partial => "comments/comments", :locals => { :commentable => @network } }
    end
  end
  
  # POST /networks/1;tag
  def tag
    @network.tags_user_id = current_user
    @network.tag_list = "#{@network.tag_list}, #{convert_tags_to_gem_format params[:tag_list]}" if params[:tag_list]
    @network.update_tags # hack to get around acts_as_versioned
    
    respond_to do |format|
      format.html { render :partial => "tags/tags_box_inner", :locals => { :taggable => @network, :owner_id => @network.user_id } }
    end
  end
  
protected

  def find_networks
    @networks = Network.find(:all, 
                             :order => "title ASC",
                             :page => { :size => 20, 
                                        :current => params[:page] },
                             :include => [ :owner ])
  end

  def find_network
    begin
      @network = Network.find(params[:id], :include => [ :owner, :memberships ])
      @network_url = url_for :only_path => false,
                             :host => base_host,
                             :id => @network.id
    rescue ActiveRecord::RecordNotFound
      error("Group not found", "is invalid (not owner)")
    end 
  end

  def find_network_auth
    begin
      @network = Network.find(params[:id], :conditions => ["networks.user_id = ?", current_user.id], :include => [ :owner, :memberships ])
    rescue ActiveRecord::RecordNotFound
      error("Group not found (id not authorized)", "is invalid (not owner)")
    end
  end
  
  def invalidate_listing_cache
    if @network
      expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => @network.id)
    end
  end
  
  def invalidate_tags_cache
    expire_fragment(:controller => 'groups', :action => 'all_tags')
    expire_fragment(:controller => 'sidebar_cache', :action => 'tags', :part => 'most_popular_tags')
  end
  
private

  def error(notice, message)
    flash[:error] = notice
    (err = Network.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to groups_url }
    end
  end
end
