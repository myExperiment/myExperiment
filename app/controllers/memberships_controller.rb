# encoding: utf-8
# myExperiment: app/controllers/memberships_controller.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

class MembershipsController < ApplicationController
  before_filter :login_required
  
  before_filter :check_user_present # only allow actions on memberships as on nested resources

  before_filter :find_network, :only => :new
  before_filter :find_user_auth, :only => :index
  before_filter :find_membership_auth, :only => [:show, :accept, :edit, :update, :destroy]
  
  # declare sweepers and which actions should invoke them
  cache_sweeper :membership_sweeper, :only => [ :create, :accept, :update, :destroy ]
  
  # POST /users/1/memberships/1;accept
  # POST /memberships/1;accept
  def accept
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    group = Network.find(@membership.network_id)
    invite = @membership.is_invite?
      
    personal_message = "NONE"
    if params[:accept_msg] && !params[:accept_msg].blank?
      personal_message = ae_some_html(params[:accept_msg])
    end

    # the messages will appear as 'deleted-by-sender', because the owner of the account effectively didn't send it,
    # so there is no reason for showing this message in their 'sent messages' folder

    if invite
      from = User.find(@membership.user_id)

      subject = "Invitation to '" + group.title + "' accepted"
      body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                              :inline => <<EOM
<%= name(from) %> has accepted an invitation to join <%= title(group) %> group.
<br/>
<br/>
<strong><i>Personal message from user:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

      group.administrators(true).each {|to| 
        send_action_message(from.id, to.id, subject, body)
      }
    else
      from = current_user

      subject = "Membership to '" + group.title + "' accepted"
      body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                              :inline => <<EOM
<%= name(from) %> has accepted your request to join <%= title(group) %> group.
<br/>
<br/>
<strong><i>Personal message from <%= name(from) %>:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

      send_action_message(from.id, @membership.user_id, subject, body)

      subject = "Membership to '" + group.title + "' accepted"
      body = render_to_string :locals => { :from => from, :other => @membership.user_id, :group => group, :msg => personal_message },
                              :inline => <<EOM
<%= name(from) %> has accepted a request by <%= name(other) %> to join <%= title(group) %>  group.
<br/>
<br/>
<strong><i>Personal message from <%= name(from) %> to user:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

      group.administrators(true).select{|admin| admin.id != from.id}.each {|to|
        send_action_message(from.id, to.id, subject, body)
        }
    end

    respond_to do |format|
      if @membership.accept!
        flash[:notice] = 'Membership was successfully accepted.'
        format.html { redirect_to network_path(@membership.network_id) }
      else
        flash[:error] = "Membership already accepted."
      end
      format.html { redirect_to network_path(@membership.network_id) }
    end
  end
  
  # GET /users/1/memberships
  # GET /memberships
  def index
    @memberships = @user.memberships

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /users/1/memberships/1
  # GET /memberships/1
  def show
    respond_to do |format|
      format.html {

        @lod_nir  = user_membership_url(:id => @membership, :user_id => @membership.user_id)
        @lod_html = user_membership_url(:id => @membership.id, :user_id => @membership.user_id, :format => 'html')
        @lod_rdf  = user_membership_url(:id => @membership.id, :user_id => @membership.user_id, :format => 'rdf')
        @lod_xml  = user_membership_url(:id => @membership.id, :user_id => @membership.user_id, :format => 'xml')

        # show.rhtml
      }

      if Conf.rdfgen_enable
        format.rdf {
          render :inline => `#{Conf.rdfgen_tool} memberships #{@membership.id}`
        }
      end
    end
  end

  # GET /users/1/memberships/new
  # GET /memberships/new
  def new
    if @network
      @membership = Membership.new(:user_id => current_user.id, :network_id => @network.id)
    else
      @membership = Membership.new(:user_id => current_user.id)
    end
  end

  # GET /users/1/memberships/1;edit
  # GET /memberships/1;edit
  def edit
    
  end

  # POST /users/1/memberships
  # POST /memberships
  def create
    # TODO: test if "user_established_at" and "network_established_at" can be hacked (ie: set) through API calls,
    # thereby creating memberships that are already 'accepted' at creation.
    user = User.find_by_id(params[:membership][:user_id])
    if user.nil?
      render_404("User not found.")
    elsif !Membership.find_by_user_id_and_network_id(params[:membership][:user_id], params[:membership][:network_id]) ||
        Network.find(params[:membership][:network_id]).owner?(user)

      @membership = Membership.new(params[:membership])

      @membership.user_established_at = nil
      @membership.network_established_at = nil
      if @membership.message.blank?
        @membership.message = nil
      end
      
      respond_to do |format|

        if @membership.save
          # Take into account network's new member policy setting
          if (@membership.network.open?)
            @membership.accept!
            
            begin
              user = @membership.user
              network = @membership.network
              Notifier.deliver_auto_join_group(user, network, base_host) if network.administrators(true).any? {|a| a.send_notifications?}
            rescue
              logger.error("ERROR: failed to send email notification for auto join group. Membership ID: #{@membership.id}")
            end
            
            flash[:notice] = 'You have successfully joined the Group.'
          elsif (@membership.network.membership_by_request?)
            @membership.user_establish!
            
            begin
              user = @membership.user
              network = @membership.network
              Notifier.deliver_membership_request(user, network, @membership, base_host) if network.administrators(true).any? {|a| a.send_notifications?}
            rescue Exception => e
              logger.error("ERROR: failed to send Membership Request email notification. Membership ID: #{@membership.id}")
              logger.error("EXCEPTION:" + e)
            end
            
            flash[:notice] = 'Membership was successfully requested.'
          end

          format.html { redirect_to user_membership_path(current_user.id, @membership) }
        else
          format.html { render :action => "new" }
        end
      end
    else
      respond_to do |format|
        flash[:error] = "Membership not created (already exists)"
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /users/1/memberships/1
  # PUT /memberships/1
  def update
    # no spoofing of acceptance
    params[:membership].delete('network_established_at') if params[:membership][:network_established_at]
    params[:membership].delete('user_established_at') if params[:membership][:user_established_at]
    
    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        flash[:notice] = 'Membership was successfully updated.'
        format.html { redirect_to user_membership_path(@membership.user_id, @membership) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /users/1/memberships/1
  # DELETE /memberships/1
  def destroy
    network_id = @membership.network_id
    from = current_user
    
    # a notification message will be delivered to the the requestor anyway;
    # it may contain a personal note, if any was supplied
    group = Network.find(network_id)
    invite = @membership.is_invite?
    rejection = (@membership.network_established_at.nil? || @membership.user_established_at.nil?) ? true : false

    personal_message = "NONE"
    if params[:reject_msg]  && !params[:reject_msg].blank?
      personal_message = ae_some_html(params[:reject_msg])
    end
      
    # the same method ('destroy') works when membership is rejected
    # or removed after being accepted previously
    if rejection
      # if this is rejection, then just group admin can do this action, so
      # the message would go from group admin to the requesting-user
      if invite
        subject =  "Invitation to '" + group.title + "' rejected"
        body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                                :inline => <<EOM
<%= name(from) %> has rejected an invitation to join <%= title(group) %> group.
<br/>
<br/>
<strong><i>Personal message from <%= name(from) %> to user:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

        group.administrators(true).each {|to| 
          send_action_message(from.id, to.id, subject, body)
        }
      else
        to_id = @membership.user_id

        subject = "Membership to '" + group.title + "' rejected"
        body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                                :inline => <<EOM
<%= name(from) %> has rejected your request to join <%= title(group) %> group.
<br/>
<br/>
<strong><i>Personal message from <%= name(from) %> to user:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

        send_action_message(from.id, to_id, subject, body)

        subject =  "Membership to '" + group.title + "' rejected"
        body = render_to_string :locals => { :from => from, :other => @membership.user_id, :group => group, :msg => personal_message },
                                :inline => <<EOM
<%= name(from) %> has rejected the request by <%= name(other) %> to join <%= title(group) %> group."
<br/>
<strong><i>Personal message from <%= name(from) %> to user:</i></strong><hr/>
<%= msg %>
<hr/>
EOM

        group.administrators(true).select{|admin| admin.id != from.id}.each {|to|
          send_action_message(from.id, to.id, subject, body)
        }
      end
      
    else
      # membership was cancelled, so the message goes from the current user
      # (who can be either admin or a former group member) to the 'other side' of the membership;
      # NB! subject and body should change accordingly!
      
      if current_user.id == @membership.user_id
        subject = from.name + " has left the '" + group.title + "' group"
        body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                                :inline => <<EOM
User <%= name(from) %> has left <%= title(group) %> group.
<br/>
<br/>
If you want to contact this user directly, just reply to this message.
EOM

        group.administrators(true).each {|to| 
          send_action_message(from.id, to.id, subject, body)
        }
      else  
        subject = "You have been removed from '" + group.title + "' group"
        body = render_to_string :locals => { :from => from, :group => group, :msg => personal_message },
                                :inline => <<EOM
<%= name(from) %> has removed you from <%= title(group) %> group.
<br/>
<br/>
If you want to contact the administrator directly, just reply to this message.
EOM

        send_action_message(from.id, @membership.user_id, subject, body)

        subject = "User removed from '" + group.title + "' group"
        body = render_to_string :locals => { :from => from, :other => @membership.user_id, :group => group, :msg => personal_message },
                                :inline => "<%= name(from) %> has removed <%= name(other) %> from <%= title(group) %> group."

        group.administrators(true).select{|admin| admin.id != current_user.id}.each {|to|
          send_action_message(from.id, to.id, subject, body)
        }
      end
    end
      
    @membership.destroy

    respond_to do |format|
      flash[:notice] = "Membership successfully deleted"
      format.html { redirect_to(params[:return_to] ? params[:return_to] : network_path(network_id)) }
    end
  end
  
protected

  # checks that the url contains an id of the user,
  # so enforcing the use of nested links
  def check_user_present
    if params[:user_id].blank?
      flash.now[:error] = "Invalid URL"
      redirect_to user_memberships_path(current_user.id)
    end
  end

  def find_network
    @network = Network.find_by_id(params[:network_id])

    if @network.nil? && params[:network_id]
      render_404("Group not found.")
    end
  end

  def find_user_auth
    @user = User.find_by_id(params[:user_id])

    if @user.nil?
      render_404("User not found.")
    elsif @user != current_user
      render_401("You are not authorised to view other users' memberships.")
    end
  end

  def find_membership_auth
    @membership = Membership.find_by_id(params[:id])

    if @membership.nil?
      render_404("Membership not found.")
    else
      # now go through different actions and check which links (including user_id in the link) are allowed
      not_auth = false
      case action_name.to_s.downcase
        when "accept"
          # Either the owner or the user can approve, 
          # depending on who initiated it (link is for current user's id only)
          if @membership.user_established_at == nil
            unless @membership.user_id == current_user.id && params[:user_id].to_i == @membership.user_id
              not_auth = true
            end
          elsif @membership.network_established_at == nil
            unless @membership.network.administrator?(current_user) # TODO: CHECK WHY?! && params[:user_id].to_i == @membership.network.owner.id
              not_auth = true
            end
          end
        when "show", "destroy", "update"
          # Only the owner of the network OR the person who the membership is for can view/delete memberships;
          # link - just user to whom the membership belongs
          unless (@membership.network.administrator?(current_user) ||
              @membership.user_id == current_user.id) && @membership.user_id == params[:user_id].to_i
            not_auth = true
          end
        else
          # don't allow anything else, for now
          not_auth = true
      end

      # check if we had any errors
      if not_auth
        render_401("You are not authorised to view other users' memberships.")
      end
    end
  end
  
private

  def send_action_message(from_id, to_id, subject, body)
    message = Message.new(:from => from_id, :to => to_id, :subject => subject, :body => body, :reply_id => nil, :read_at => nil, :deleted_by_sender => true )
    message.save
  end
end
