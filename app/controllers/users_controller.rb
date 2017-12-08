# myExperiment: app/controllers/users_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

require 'open-uri'
require 'recaptcha'

class UsersController < ApplicationController

  contributable_actions = [:workflows, :files, :packs]
  show_actions = [:show, :news, :friends, :groups, :credits, :tags, :favourites] + contributable_actions

  before_filter :login_required, :except => [:index, :new, :create, :search, :all, :confirm_email, :forgot_password, :reset_password] + show_actions
  
  before_filter :find_users, :only => [:all]
  before_filter :find_user, :only => [:destroy, :edit, :update] + show_actions
  before_filter :auth_user, :only => [:edit, :update]

  # declare sweepers and which actions should invoke them
  cache_sweeper :user_sweeper, :only => [ :create, :update, :destroy ]
  
  # GET /users;search
  def search
    redirect_to(search_path + "?type=users&query=" + params[:query])
  end
  
  # GET /users
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  # GET /users/all
  def all
    respond_to do |format|
      format.html # all.rhtml
    end
  end

  # GET /users/1
  def show

    @lod_nir  = user_url(@user)
    @lod_html = user_url(:id => @user.id, :format => 'html')
    @lod_rdf  = user_url(:id => @user.id, :format => 'rdf')
    @lod_xml  = user_url(:id => @user.id, :format => 'xml')

    @user.salt = nil
    @user.crypted_password = nil
    
    respond_to do |format|
      format.html # show.rhtml

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} users #{@user.id}`
        }
      end
    end
  end

  def news
    @tab = "News"
    render :action => 'show'
  end

  def friends
    @tab = "Friends"
    render :action => 'show'
  end

  def groups
    @tab = "Groups"
    render :action => 'show'
  end

  def workflows
    @tab = "Workflows"
    render :action => 'show'
  end

  def files
    @tab = "Files"
    render :action => 'show'
  end
  
  def packs
    @tab = "Packs"
    render :action => 'show'
  end

  def credits
    @tab = "Credits"
    render :action => 'show'
  end

  def tags
    @tab = "Tags"
    render :action => 'show'
  end
  
  def favourites
    @tab = "Favourites"
    render :action => 'show'
  end

  # GET /users/new
  def new
    @user = User.new
    
    # default values in case not supplied, or contain an error
    @email_value = ""
    @token = ""
    
    # check if the registration token was set
    if params[:token]
      # the token was set, so search 'pending_invitations' table for an entry
      pending_invite = PendingInvitation.find(:first, :conditions => ["token = ?", params[:token]])
      
      if pending_invite
        # if the entry's there, use the address from it as a default for the registration
        @email_value = pending_invite.email
        @token = params[:token]
      else
        # the entry is not there, so we've got a bad token - redirect & notify the user
        flash[:error] = "Registration token provided in URL is invalid, but you may still register without it"
        redirect_to(:controller => 'users', :action => 'new')
      end
    end
    
  end

  # GET /users/1;edit
  def edit
    
  end

  # POST /users
  def create

    if params[:user][:username] && params[:user][:password] && params[:user][:password_confirmation]
      params[:user].delete("openid_url") if params[:user][:openid_url] # strip params[:user] of it's openid_url if username and password is provided
    end

    unless params[:user][:name] # why is this here
      params[:user][:name] = "#{params[:user][:given_name]} #{params[:user][:family_name]}"
    end

    # Reset certain fields (to prevent injecting the values)
    params[:user][:email] = nil
    params[:user][:email_confirmed_at] = nil
    params[:user][:activated_at] = nil

    @user = User.new(params[:user])

    # check that captcha was entered correctly

    unless Rails.env == 'test'
      if Conf.recaptcha_enable
        if !verify_recaptcha(:private_key => Conf.recaptcha_private)
          flash.now[:error] = 'Recaptcha text was not entered correctly - please try again.'
          render :action => 'new'
          return
        end
      end
    end

    respond_to do |format|

      sent_email = false
      spammer = false

      if @user.valid?

        # basic spam check

        unless Rails.env == 'test'
          url = "http://www.stopforumspam.com/api?email=#{CGI::escape(@user.unconfirmed_email)}&username=#{CGI::escape(@user.username)}&ip=#{CGI::escape(request.ip)}&f=json"

          sfs_response = ActiveSupport::JSON.decode(open(url).read)

          if (sfs_response["success"] == 1)
            if ((sfs_response["email"]["appears"] == 1) || (sfs_response["ip"]["appears"] == 1))
              spammer = true
            end
          end
        end

        # DO NOT log in user yet, since account needs to be validated and activated first (through email).
        if !spammer
          @user.send_email_confirmation_email
          sent_email = true
        end
      end

      if sent_email && !spammer && @user.save
        
        # If required, copy the email address to the Profile
        if params[:make_email_public]
          @user.profile.email = @user.unconfirmed_email
          @user.profile.save
        end
        
        # if the user has registered with an email address different than that which was used
        # for invitation, need to update all entries in PendingInvitations table, so that the
        # requests would reach the new user even with an updated email:
        unless params[:invitation_token].blank?
          invitations = PendingInvitation.find(:all, :conditions => ["token = ?", params[:invitation_token]]) 
          invitations.each { |pi|
            pi.email = @user.unconfirmed_email
            pi.save
          }
        end
        
        flash[:notice] = "Thank you for registering! An email has been sent to #{@user.unconfirmed_email} with instructions on how to activate your account."
        format.html { redirect_to(:action => "index") }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /users/1
  def update
    # openid url's must be validated and updated separately
    # FIXME: shouldn't the line below be for params[:user][:openid_url]
    params.delete("openid_url") if params[:openid_url]
    
    respond_to do |format|
      if @user.update_attributes(params[:user])
        
        # Check to see if user tried to set the new email address to the same as an existing one
        if !@user.unconfirmed_email.blank? and @user.unconfirmed_email == @user.email
          # Reset the field
          @user.unconfirmed_email = nil;
          @user.save
          
          flash.now[:error] = 'The new email address you are trying to set is the same as your current email address'
        else
          # If a new email address was set, then need to send out a confirmation email
          if params[:user][:unconfirmed_email]
            @user.send_update_email_confirmation
            flash.now[:notice] = "We have sent an email to #{@user.unconfirmed_email} with instructions on how to confirm this new email address"
          elsif params[:update_type]
            case params[:update_type]
              when "upd_t_up"; flash.now[:notice] = 'You have successfully updated your password'
              when "upd_t_name"; flash.now[:notice] = 'You have successfully updated your name'
              when "upd_t_notify"; flash.now[:notice] = 'You have successfully updated notification options'
            end
          else
              flash.now[:notice] = 'You have successfully updated your account' # general message to be displayed when hidden field 'update_type' was not created for a certain form on the page
          end
        end
        
        #format.html { redirect_to user_url(@user) }
        format.html { redirect_to :action => "edit" }
      else
        format.html { redirect_to :action => "edit" }
      end
    end
  end

  # DELETE /users/1
  def destroy

    unless Authorization.check('destroy', @user, current_user)
      flash[:notice] = 'You do not have permission to delete this user.'
      redirect_to :action => :index
      return
    end
    
    @user.destroy
    
    # If the destroyed account belongs to the current user, then
    # it is important to log them out afterwards or they'll 
    # receive a nasty error message..

    session[:user_id] = nil if @user == current_user
    
    respond_to do |format|
      flash[:notice] = 'User account was successfully deleted'
      format.html { redirect_to(params[:return_to] ? "#{Conf.base_uri}#{params[:return_to]}" : users_path) }
    end
  end
  
  # GET /users/confirm_email/:hash
  def confirm_email
    # NOTE: this action is used for both:
    # - new users who sign up with username/password and need to confirm their email address
    # - existing users who want to change their email address (but old email address is still active) 
        
    @users = User.find :all

    confirmed = false
    
    user = User.find(:first,
        :conditions => ['SHA1(CONCAT(users.unconfirmed_email, ?)) = ?', Conf.secret_word,
        params[:hash]])

    if user
      confirmed = user.confirm_email!
      # BEGIN DEBUG
      logger.error("ERRORS!") unless user.errors.empty?
      user.errors.full_messages.each { |e| logger.error(e) } 
      #END DEBUG
      if confirmed
        Activity.create(:subject => user, :action => 'register')
        self.current_user = user
        self.current_user.process_pending_invitations! # look up any pending invites for this user + transfer them to relevant tables from 'pending_invitations' table
        confirmed = false if !logged_in?
      end
      @user = user
    end

    respond_to do |format|
      if confirmed
        flash[:notice] = "Thank you for confirming your email address.  Welcome to #{Conf.sitename}!"
        format.html { redirect_to user_path(@user) }
      else
        flash[:error] = "Invalid confirmation URL"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end
  end
  
  # GET /users/forgot_password
  # POST /users/forgot_password
  def forgot_password
    
    if request.get?
      # forgot_password.rhtml
    elsif request.post?
      user = User.find_by_email(params[:email])

      respond_to do |format|
        if user
          user.reset_password_code_until = 1.day.from_now
          user.reset_password_code =  Digest::SHA1.hexdigest( "#{user.email}#{Time.now.to_s.split(//).sort_by {rand}.join}" )
          user.save!
          Mailer.forgot_password(user).deliver
          flash[:notice] = "Instructions on how to reset your password have been sent to #{user.email}"
          format.html { render :action => "forgot_password" }
        else
          flash[:error] = "Invalid email address: #{params[:email]}"
          format.html { render :action => "forgot_password" }
        end
      end
    end
    
  end
  
  # GET /users/reset_password
  def reset_password
    user = User.find_by_reset_password_code(params[:reset_code])
    
    respond_to do |format|
      if user
        if user.reset_password_code_until && Time.now < user.reset_password_code_until
          user.reset_password_code = nil
          user.reset_password_code_until = nil
          if user.save
            self.current_user = user
            if logged_in?
              flash[:notice] = "You can reset your password here"
              format.html { redirect_to(:action => "edit", :id => user.id) }
            else
              flash[:error] = "An unknown error has occurred. We are sorry for the inconvenience. You can request another password reset here."
              format.html { render :action => "forgot_password" }
            end
          end
        else
          flash[:error] = "Your password reset code has expired"
        format.html { redirect_to(:controller => "session", :action => "new") }
        end
      else
        flash[:error] = "Invalid password reset code"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end 
  end

  # For sending invitation emails
  def invite
    sending_allowed_with_reset_timestamp = ActivityLimit.check_limit(current_user, "user_invite", false)
    
    respond_to do |format|
      if sending_allowed_with_reset_timestamp[0]
        format.html # invite.rhtml
      else
        # limit of invitation for this user is already exceeded
        error_msg = "You can't send invitations - your limit is reached, "
        if sending_allowed_with_reset_timestamp[1].nil?
          error_msg += "it will not be reset. Please contact #{Conf.sitename} administration for details."
        elsif sending_allowed_with_reset_timestamp[1] <= 60
          error_msg += "please try again within a couple of minutes"
        else
          error_msg += "it will be reset in " + formatted_timespan(sending_allowed_with_reset_timestamp[1])
        end
        
        flash[:error] = error_msg 
        format.html { redirect_to user_path(current_user) }
      end
    end
  end
  
  def process_invitations
    # first of all, check that captcha was entered correctly
    captcha_verified = false
    if Conf.recaptcha_enable && !verify_recaptcha(:private_key => Conf.recaptcha_private)
      respond_to do |format|
        flash.now[:error] = 'Verification text was not entered correctly - your invitations have not been sent.'
        format.html { render :action => 'invite' }
      end
    else
      # captcha verified correctly, can proceed
      
      addr_count, validated_addr_count, valid_addresses, db_user_addresses, err_addresses = Invitation.validate_address_list(params[:invitations][:addr_to], current_user)
      existing_invitation_emails = []
      valid_addresses_tokens = {}     # a hash for pairs of 'email' => 'token'
      overflow_addresses = []
        
      # if validation found valid addresses, do the sending
      # (limit on the number of invitation email is only checked where the actual email will be sent)
      if validated_addr_count > 0
        if params[:invitations][:as_friendship].nil?
          valid_addresses.each { |email_addr|
            if ActivityLimit.check_limit(current_user, "user_invite")[0]
              valid_addresses_tokens[email_addr] = ""
            else
              overflow_addresses << email_addr
            end
          }
          Invitation.send_invitation_emails("invite", base_host, User.find(params[:invitations_user_id]), valid_addresses_tokens, params[:invitations][:msg_text])
        elsif params[:invitations][:as_friendship] == "true"
          # for each email check if such invitation wasn't sent before;
          # reject the address if it was, store the data into 'pending_invitations' otherwise
          valid_addresses.each do |email_addr|
            if PendingInvitation.find_by_email_and_request_type_and_request_for(email_addr, "friendship", params[:invitations_user_id])
              existing_invitation_emails << email_addr
            else 
              if ActivityLimit.check_limit(current_user, "user_invite")[0]
                token_code = Digest::SHA1.hexdigest( email_addr.reverse + Conf.secret_word )
                valid_addresses_tokens[email_addr] = token_code
                invitation = PendingInvitation.new(:email => email_addr, :request_type => "friendship", :requested_by => params[:invitations_user_id], :request_for => params[:invitations_user_id], :message => params[:invitations][:msg_text], :token => token_code)
                invitation.save
              else
                overflow_addresses << email_addr
              end
            end
          end
          
          # update the actual number of validated addresses
          validated_addr_count = valid_addresses_tokens.length
          
          # send out invitation emails, if there are any successful emails in 'valid_addresses_tokens'
          unless valid_addresses_tokens.empty?
            Invitation.send_invitation_emails("friendship_invite", base_host, User.find(params[:invitations_user_id]), valid_addresses_tokens, params[:invitations][:msg_text])
          end  
        end
      end
      
      
      # process those addresses that are ones of existing users (not as the current user assumed them to be as new)
      own_address_err = ""
      existing_db_addr_plain_invite_err_list = []
      existing_db_addr_existing_friendship_err_list = []
      existing_db_addr_successful_friendship_requests_list = []
      
      is_friendship_request = (!params[:invitations][:as_friendship].nil? && params[:invitations][:as_friendship] == "true" ? true : false)
      db_user_addresses.each { |db_addr, user|
        if db_addr == current_user.email
          own_address_err += db_addr
        elsif !is_friendship_request 
          # no use to send plain invite to an existing user
          existing_db_addr_plain_invite_err_list << db_addr
        else
          # email doesn't belong to current user & it's a friendship request
          if current_user.friend?(user.id) || current_user.friendship_pending?(user.id)
            existing_db_addr_existing_friendship_err_list << db_addr
          else
            # need to create internal friendship request, as one not yet exists
            existing_db_addr_successful_friendship_requests_list << db_addr
            req = Friendship.new(:user_id => current_user.id, :friend_id => user.id, :accepted_at => nil, :message => params[:invitations][:msg_text])
            req.save
          end
        end
      }
      
          
      # in future, potentially there's going to be a way to get results of sending;
      # now display message based on number of valid / invalid addresses..
      respond_to do |format|
        if validated_addr_count == 0 && existing_invitation_emails.empty? && db_user_addresses.empty? && overflow_addresses.empty?
          flash.now[:notice] = "None of the supplied address(es) could be validated, no emails were sent.<br/>Please check your input!"
          format.html { render :action => 'invite' }
        elsif (addr_count == validated_addr_count) && (!err_addresses || err_addresses.empty?) && (!overflow_addresses || overflow_addresses.empty?)
          flash[:notice] = validated_addr_count.to_s + " Invitation email(s) sent successfully"
          format.html { redirect_to :action => 'show', :id => params[:invitations_user_id] }
        else
          # something went wrong, so will assemble complex error message
          error_msg = (valid_addresses_tokens.empty? ? "No invitation emails were sent." : "Some invitations email(s) were sent successfully.") + " See errors below.<span style='color: red;'>"
          addr_params = ""
          
          unless own_address_err.blank?
            error_msg += "<br/><br/>Can't send invitation to your own registered email address: <br/>" + own_address_err
          end
          
          unless existing_db_addr_plain_invite_err_list.empty?
            error_msg += "<br/><br/>People with the following email addresses are existing users (no invitations were sent): <br/>" + existing_db_addr_plain_invite_err_list.join("<br/>")
          end
          
          unless existing_db_addr_existing_friendship_err_list.empty?
            error_msg += "<br/><br/>There are existing or pending friendships between you and users of the following email addresses (no invitations were sent): <br/>" + existing_db_addr_existing_friendship_err_list.join("<br/>")
          end
          
          unless existing_db_addr_successful_friendship_requests_list.empty?
            error_msg += "<br/><br/>People with the following email addresses are existing users, internal friendship requests were sent instead of emails: <br/>" + existing_db_addr_successful_friendship_requests_list.join("<br/>")
          end
            
          unless existing_invitation_emails.empty?
            error_msg += "<br/><br/>Invitations to the following address(es) have not been sent now because this was already done earlier:<br/>" + existing_invitation_emails.join("<br/>")
            addr_params += existing_invitation_emails.join("; ")
          end
            
          unless err_addresses.empty?
            error_msg += "<br/><br/>The following address(es) could not be validated:<br/>" + err_addresses.join("<br/>")
            
            addr_params += "; " unless addr_params.blank?
            addr_params += err_addresses.join("; ")
          end
          
          unless overflow_addresses.empty?
            error_msg += "<br/><br/>You have ran out of quota for sending invitations, "
            reset_quota_after = ActivityLimit.check_limit(current_user, "user_invite", false)[1]
            if reset_quota_after.nil?
              error_msg += "it will not be reset. Please contact #{Conf.sitename} administration for details."
            elsif reset_quota_after <= 60
              error_msg += "please try again within a couple of minutes."
            else
              error_msg += "it will be reset in " + formatted_timespan(reset_quota_after) + "."
            end
            
            error_msg += "<br/>The following addresses were not processed because maximum allowed amount of invitations was exceeded:<br/>" + overflow_addresses.join("<br/>")
          end
          
          error_msg += "</span>"
          flash.now[:notice] = error_msg  
          params[:invitations][:addr_to] = addr_params
          format.html { render :action => 'invite' }
        end
      end
    end
  end

  def check

    def add(strings, opts = {})
      if opts[:string] && opts[:string] != ""

        label  = opts[:label]
        label = self.class.helpers.link_to(label, opts[:link]) if opts[:link]

        strings << { :label => label, :string => opts[:string], :escape => opts[:escape] }
      end
    end

    unless logged_in? && Conf.admins.include?(current_user.username)
      render :text => "Not authorised"
      return
    end

    @from = params[:from].to_i
    @to   = params[:to].to_i

    if @to > 0
      users = User.users_to_check.find(:all, :conditions => ["id >= ? AND id <= ?", @from, @to])
    else
      users = User.users_to_check.find(:all)
    end

    @userlist = users.map do |user|

      strings = []

      add(strings, :label => "email",        :string => user.email)
      add(strings, :label => "openid",       :string => user.openid_url)
      add(strings, :label => "created at",   :string => user.created_at)
      add(strings, :label => "last login",   :string => user.last_seen_at ? user.last_seen_at : "never logged back in")
      add(strings, :label => "name",         :string => user.name)
      add(strings, :label => "public email", :string => user.profile.email)
      add(strings, :label => "website",      :string => user.profile.website, :escape => :website)
      add(strings, :label => "description",  :string => user.profile.body_html, :escape => :false)
      add(strings, :label => "field / ind",  :string => user.profile.field_or_industry)
      add(strings, :label => "occ / roles",  :string => user.profile.occupation_or_roles)
      add(strings, :label => "city",         :string => user.profile.location_city)
      add(strings, :label => "country",      :string => user.profile.location_country)
      add(strings, :label => "interests",    :string => user.profile.interests)
      add(strings, :label => "contact",      :string => user.profile.contact_details)
      add(strings, :label => "tags",         :string => user.tags.map do |tag| tag.name end.join(", "))

      user.networks_owned.each do |network|

        add(strings, :label  => "group title",
                     :link   => polymorphic_path(network),
                     :string => network.title) 

        add(strings, :label  => "group description",
                     :link   => polymorphic_path(network),
                     :string => network.description_html,
                     :escape => :false) 
      end

      user.packs.each do |pack|

        add(strings, :label  => "pack title",
                     :link   => polymorphic_path(pack),
                     :string => pack.title) 

        add(strings, :label  => "pack description",
                     :link   => polymorphic_path(pack),
                     :string => pack.description_html,
                     :escape => :false) 
      end

      user.workflows.each do |workflow|

        add(strings, :label  => "workflow title",
                     :link   => polymorphic_path(workflow),
                     :string => workflow.title) 

        add(strings, :label  => "workflow description",
                     :link   => polymorphic_path(workflow),
                     :string => workflow.body_html,
                     :escape => :false) 
      end

      user.blobs.each do |blob|

        add(strings, :label  => "file title",
                     :link   => polymorphic_path(blob),
                     :string => blob.title) 

        add(strings, :label  => "file description",
                     :link   => polymorphic_path(blob),
                     :string => blob.body_html,
                     :escape => :false) 
      end

      user.comments.each do |comment|

        commentable = comment.commentable
        commentable = commentable.context if commentable.kind_of?(Activity)

        add(strings, :label  => "comment",
                     :link   => polymorphic_path(commentable),
                     :string => comment.comment,
                     :escape => :white_list) 
      end

      { :ob => user, :strings => strings }

    end
  end

  def change_status

    unless logged_in? && Conf.admins.include?(current_user.username)
      render :text => "Not authorised"
      return
    end

    from = params[:from].to_i
    to   = params[:to].to_i

    params.keys.each do |key|

      match_data = key.match(/user-([0-9]*)/)

      if match_data
        if user = User.find_by_id(match_data[1])
          puts "Processing user #{user.id}"
          case params[key]
          when "whitelist"
            user.update_attributes(:account_status => "whitelist")
          when "sleep"
            user.update_attributes(:account_status => "sleep")
          when "suspect"
            user.update_attributes(:account_status => "suspect")
          when "delete"

            # build an "all elements" user.xml record

            elements = {}

            TABLES['Model'][:data]['user']['REST Attribute'].each do |attr|
              add_to_element_hash(attr, elements)
            end

            doc  = LibXML::XML::Document.new()
            root = rest_get_request_aux(user, nil, {}, elements) 
            doc.root = root

            File.open("#{Conf.deleted_data_directory}#{user.id}.xml", "wb+") { |f| f.write(doc.to_s) }

            user.destroy
          end
        end
      end
    end

    respond_to do |format|
      format.html {
        redirect_to(url_for(:controller => "users", :action => "check", :from => params[:from], :to => params[:to]))
      }
    end
  end

  def auto_complete
    text = params[:user_name] || ''

    users = User.find(:all,
                     :conditions => ["LOWER(name) LIKE ?", text.downcase + '%'],
                     :order => 'name ASC',
                     :limit => 20,
                     :select => 'DISTINCT *')

    render :partial => 'users/autocomplete_list', :locals => { :users => users }
  end

protected

  def find_users
    @users = User.find(:all, 
                       :order => "users.name ASC",
                       :conditions => "users.activated_at IS NOT NULL",
                       :include => :profile)

    @users = @users.paginate(:page => params[:page], :per_page => 20)

    @users.each do |user|
      user.salt = nil
      user.crypted_password = nil
    end
  end

  def find_user
    @user = User.find_by_id(params[:id], :include => [ :profile, :owned_tags ])

    if @user.nil? || !@user.activated?
      render_404("User not found, or not activated.")
    end
  end

  def auth_user
    unless @user == current_user
      render_401("You may only manage your own account.")
    end
  end
end
