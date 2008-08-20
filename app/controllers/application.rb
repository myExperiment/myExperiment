# myExperiment: app/controllers/application.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  after_filter :invalidate_home_cache_for_current_user
  
  WhiteListHelper.tags.merge %w(table tr td th div span)
  
  include AuthenticatedSystem
  before_filter :login_from_cookie
  
  helper ForumsHelper

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  def base_host
    request.host_with_port
  end
  
  def can_manage_pages?
    return admin?  # from authenticated_system
  end
  
  # Safe HTML - http://www.anyexample.com/webdev/rails/how_to_allow_some_safe_html_in_rails_projects.xml
  # Note: should only be used for text that doesn't need updating later.
  def ae_some_html(s)
    return '' if s.nil?    
    
    # converting newlines
    s.gsub!(/\r\n?/, "\n")
 
    # escaping HTML to entities
    s = s.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
 
    # blockquote tag support
    s.gsub!(/\n?&lt;blockquote&gt;\n*(.+?)\n*&lt;\/blockquote&gt;/im, "<blockquote>\\1</blockquote>")
 
    # other tags: b, i, em, strong, u
    %w(b i em strong u).each { |x|
         s.gsub!(Regexp.new('&lt;(' + x + ')&gt;(.+?)&lt;/('+x+')&gt;',
                 Regexp::MULTILINE|Regexp::IGNORECASE), 
                 "<\\1>\\2</\\1>")
        }
 
    # A tag support
    # href="" attribute auto-adds http://
    s = s.gsub(/&lt;a.+?href\s*=\s*['"](.+?)["'].*?&gt;(.+?)&lt;\/a&gt;/im) { |x|
            '<a href="' + ($1.index('://') ? $1 : 'http://'+$1) + "\">" + $2 + "</a>"
          }
 
    # replacing newlines to <br> ans <p> tags
    # wrapping text into paragraph
    s = "<p>" + s.gsub(/\n\n+/, "</p>\n\n<p>").
            gsub(/([^\n]\n)(?=[^\n])/, '\1<br />') + "</p>"
 
    s      
  end
  
  # This method takes a comma seperated list of tags (where multiple words don't need to be in quote marks)
  # and formats it into a new comma seperated list where multiple words ARE in quote marks.
  # (Note: it will actually put quote marks around all the words and then out commas).
  # eg: 
  #    this, is a, tag
  #        becomes:
  #    "this","is a","tag"
  #
  # This is so we can map the tags entered in by users to the format required by the act_as_taggable_redux gem.
  def convert_tags_to_gem_format(tags_string)
    list = parse_comma_seperated_string(tags_string)
    converted = '' 
    
    list.each do |s|
      converted = converted + '"' + s.strip + '",'
    end
    
    return converted
  end
  
  helper_method :ae_some_html
  
  # This method converts a comma seperated string of values into a collection of those values.
  # Note: currently does not cater for values in quotation marks and does not remove empty values
  # (although it does ignore a trailing comma)
  def parse_comma_seperated_string(s)
    list = s.split(',')
  end

  def update_policy(contributable, params)

    # this method will return an error message is something goes wrong (empty string in case of success)
    error_msg = ""
    

    # BEGIN validation and initialisation
    
    return if params[:sharing].nil? or params[:sharing][:class_id].blank?
    
    sharing_class  = params[:sharing][:class_id]
    updating_class = (params[:updating] and !params[:updating][:class_id].blank?) ? params[:updating][:class_id] : "6"
    
    # Check allowed sharing_class values
    return unless [ "0", "1", "2", "3", "4", "7" ].include? sharing_class
    
    # Check allowed updating_class values
    return unless [ "0", "1", "5", "6" ].include? updating_class
    
    view_protected     = 0
    view_public        = 0
    download_protected = 0
    download_public    = 0
    edit_protected     = 0
    edit_public        = 0
    
    # BEGIN initialisation and validation

    case sharing_class
      when "0"
        view_public        = 1
        download_public    = 1
        view_protected     = 1
        download_protected = 1
      when "1"
        view_public        = 1
        view_protected     = 1
        download_protected = 1
      when "2"
        view_public        = 1
        view_protected     = 1
      when "3"
        view_protected     = 1
        download_protected = 1          
      when "4"
        view_protected     = 1
    end

    case updating_class
      when "0"
        edit_protected = true if (view_protected == true && download_protected == true)
        edit_public    = true if (view_public    == true && download_public    == true)
      when "1"
        edit_protected = true      
      # when "5","6" -> no need for these cases, because both edit flags are false (default values) for these modes
    end

    unless contributable.contribution.policy
      policy = Policy.new(:name => 'auto',
          :contributor_type => 'User', :contributor_id => current_user.id,
          :view_protected     => view_protected,
          :view_public        => view_public,
          :download_protected => download_protected,
          :download_public    => download_public,
          :edit_protected     => edit_protected,
          :edit_public        => edit_public,
          :share_mode         => sharing_class,
          :update_mode        => updating_class)
      contributable.contribution.policy = policy
      contributable.contribution.save
    else
       policy = contributable.contribution.policy
       policy.view_protected = view_protected
       policy.view_public = view_public
       policy.download_protected = download_protected
       policy.download_public = download_public
       policy.edit_protected = edit_protected
       policy.edit_public = edit_public
       policy.share_mode = sharing_class
       policy.update_mode = updating_class
       policy.save
    end

    # Process 'update' permissions for "Some of my Friends"

    # Delete old User permissions
    policy.permissions.each do |p|
      if p.contributor_type == 'User'
        p.destroy
      end
    end
    
    # Now create new User permissions, if required
    if updating_class == "5"
      if params[:updating_somefriends]
        params[:updating_somefriends].each do |f|
          Permission.new(:policy => policy,
              :contributor => (User.find f[1].to_i),
              :view => 1, :download => 1, :edit => 1).save
        end
      else # none of the 'some of my friends' were selected, error
        error_msg += "You have selected to set 'update' permissions for 'Some of your Friends', but didn't select any from the list.</br>Update was unsuccessful, please try again."
      end
    end
    
    # Process explicit Group permissions now
    if params[:group_sharing]
      
      # First delete any Permission objects that don't have a checked entry in the form
      policy.permissions.each do |p|
        params[:group_sharing].each do |n|
          # If a hash value with key 'id' wasn't returned then that means the checkbox was unchecked.
          unless n[1][:id]
            if p.contributor_type == 'Network' and p.contributor_id == n[0].to_i
              p.destroy
              
              # Invalidate the associated caches
              expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => p.contributor_id)
            end
          end
        end
      end
    
      # Now create or update Permissions
      params[:group_sharing].each do |n|
        
        # Note: n[1] is used because n is an array and n[1] returns it's value (which in turn is a hash)
        # In this hash, is a value with key 'id' is present then the checkbox for that group was checked.
        if n[1][:id]
          
          n_id = n[1][:id].to_i
          level = n[1][:level]
          
          unless (perm = Permission.find(:first, :conditions => ["policy_id = ? AND contributor_type = ? AND contributor_id = ?", policy.id, 'Network', n_id]))
            # Only create new Permission if it doesn't already exist
            p = Permission.new(:policy => policy, :contributor => (Network.find(n_id)))
            p.set_level!(level) if level
          else
            # Update the 'level' on the existing permission
            perm.set_level!(level) if level
          end
          
          # Invalidate the associated caches
          expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => n_id)
          
        else
          
          n_id = n[0].to_i
          
          # Delete permission if it exists (because this one is unchecked)
          if (perm = Permission.find(:first, :conditions => ["policy_id = ? AND contributor_type = ? AND contributor_id = ?", policy.id, 'Network', n_id]))
            perm.destroy
            
            # Invalidate the associated caches
            expire_fragment(:controller => 'groups_cache', :action => 'listing', :id => perm.contributor_id)
          end
          
        end
      
      end
    end

    puts "------ Workflow create summary ------------------------------------"
    puts "current_user   = #{current_user.id}"
    puts "updating_class = #{updating_class}"
    puts "sharing_class  = #{sharing_class}"
    puts "policy         = #{policy}"
    puts "group_sharing  = #{params[:group_sharing]}"
    puts "-------------------------------------------------------------------"

    # returns some message in case of errors (or empty string in case of success)
    return error_msg
  end

  def determine_sharing_mode(contributable)
    
    # TODO: like the determine_updating_mode(..) method below, this method needs to be refactored into the Policy class. 

    policy = contributable.contribution.policy

    return policy.share_mode if !policy.share_mode.nil?

    v_pub  = policy.view_public;
    v_prot = policy.view_protected;
    d_pub  = policy.download_public;
    d_prot = policy.download_protected;
    e_pub  = policy.edit_public;
    e_prot = policy.edit_protected;

    if (policy.permissions.length == 0)

      if ((v_pub  == true ) && (v_prot == false) && (d_pub  == true ) && (d_prot == false))
        return 0
      end

      if ((v_pub  == true ) && (v_prot == false) && (d_pub  == false) && (d_prot == true ))
        return 1;
      end

      if ((v_pub  == true ) && (v_prot == false) && (d_pub  == false) && (d_prot == false))
        return 2;
      end

      if ((v_pub  == false) && (v_prot == true ) && (d_pub  == false) && (d_prot == true ))
        return 3;
      end

      if ((v_pub  == false) && (v_prot == true ) && (d_pub  == false) && (d_prot == false))
        return 4;
      end

      if ((v_pub  == false) && (v_prot == false) && (d_pub  == false) && (d_prot == false))
        return 7;
      end

    end

    return 8

  end

  def determine_updating_mode(contributable)
    if (policy = contributable.contribution.policy)
      return policy.determine_update_mode(contributable.contribution)
    else
      return 7
    end
  end

  def update_credits(creditable, params)
    
    # First delete old creditations:
    creditable.creditors.each do |c|
      c.destroy
    end
    
    # Then create new creditations:
    
    # Current user
    if (params[:credits_me].downcase == 'true')
      c = Creditation.new(:creditor_type => 'User', :creditor_id => current_user.id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
    # Friends + other users
    user_ids = parse_comma_seperated_string(params[:credits_users])
    user_ids.each do |id|
      c = Creditation.new(:creditor_type => 'User', :creditor_id => id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
    # Networks (aka Groups)
    network_ids = parse_comma_seperated_string(params[:credits_groups])
    network_ids.each do |id|
      c = Creditation.new(:creditor_type => 'Network', :creditor_id => id, :creditable_type => creditable.class.to_s, :creditable_id => creditable.id)
      c.save
    end
    
  end
  
  def update_attributions(attributable, params)
    
    # First delete old attributions:
    attributable.attributors.each do |a|
      a.destroy
    end
    
    # Then create new attributions:
    
    # Workflows
    attributor_workflow_ids = parse_comma_seperated_string(params[:attributions_workflows])
    attributor_type = 'Workflow'
    attributor_workflow_ids.each do |id|
      a = Attribution.new(:attributor_type => attributor_type, :attributor_id => id, :attributable_type => attributable.class.to_s, :attributable_id  => attributable.id)
      a.save
    end
    
    # Files
    attributor_file_ids = parse_comma_seperated_string(params[:attributions_files])
    attributor_type = 'Blob'
    attributor_file_ids.each do |id|
      a = Attribution.new(:attributor_type => attributor_type, :attributor_id => id, :attributable_type => attributable.class.to_s, :attributable_id  => attributable.id)
      a.save
    end
    
  end
  
protected
  
  # Handle ALL fragment cache invalidations (EXCEPT site announcements) for the 'Home' page in this one method
  def invalidate_home_cache_for_current_user
    puts "Hitting invalidate_home_cache_for_current_user method in application controller"
    
    if logged_in?
      
      # Updated Items box
      if ["workflows", "blobs", "blogs", "forums"].include?(controller_name) and
        ["create", "update", "destroy", "destroy_version", "update_version"].include?(action_name)
        expire_timeout_fragment(:controller => 'home_cache', :action => 'updated_items', :id => current_user.id)
      end
      
      # Latest Reviews box
      if ["reviews", "workflows"].include?(controller_name) and
        ["create", "update", "destroy", "destroy_version", "update_version"].include?(action_name)
        expire_timeout_fragment(:controller => 'home_cache', :action => 'latest_reviews', :id => current_user.id)
      end
      
      # Latest Comments box
      if ["workflows", "blobs", "networks"].include?(controller_name) and
        ["comment", "comment_delete", "update", "destroy", "destroy_version", "update_version"].include?(action_name)
        expire_timeout_fragment(:controller => 'home_cache', :action => 'latest_comments', :id => current_user.id)
      end
      
      # Latest Groups box
      if ["networks"].include?(controller_name) and
        ["create", "update", "destroy"].include?(action_name)
        expire_timeout_fragment(:controller => 'home_cache', :action => 'latest_groups', :id => current_user.id)
      end
      
      # Latest Tags box
      if ["workflows", "blobs", "networks"].include?(controller_name) and
        ["tag", "create", "update", "destroy", "destroy_version", "update_version"].include?(action_name)
        expire_timeout_fragment(:controller => 'home_cache', :action => 'latest_tags', :id => current_user.id)
      end
      
    end
  end
end
