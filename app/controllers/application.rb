##
##
## myExperiment - a social network for scientists
##
## Copyright (C) 2007 University of Manchester/University of Southampton
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License
## as published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program; if not, see http://www.gnu.org/licenses
## or write to the Free Software Foundation,Inc., 51 Franklin Street,
## Fifth Floor, Boston, MA 02110-1301  USA
##
##

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  before_filter :login_from_cookie
  
  helper ForumsHelper

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_m2_session_id'
  
  # Safe HTML - http://www.anyexample.com/webdev/rails/how_to_allow_some_safe_html_in_rails_projects.xml
  def ae_some_html(s)
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

    return if params[:sharing].nil?

    params[:updating] = "6" if params[:updating].nil?

    view_protected     = false
    view_public        = false
    download_protected = false
    download_public    = false
    edit_protected     = false
    edit_public        = false

    sharing_class  = params[:sharing][:class_id]
    updating_class = params[:updating][:class_id]

    case sharing_class
      when "0"
        view_public        = "1"
        download_public    = "1"
      when "1"
        view_public        = "1"
        download_protected = "1"
      when "2"
        view_public        = "1"
      when "3"
        view_protected     = "1"
        download_protected = "1"          
      when "4"
        view_protected     = "1"
    end

    case updating_class
      when "0"
        edit_protected = true if view_protected == "1" or download_protected == "1"
        edit_public    = true if view_public    == "1" or download_public    == "1"
      when "1"
        edit_protected = true
    end

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

    case sharing_class
      when "5"
        params[:sharing_networks1].each do |n|
          Permission.new(:policy => policy,
              :contributor => (Network.find n[1].to_i),
              :view => 1, :download => 1, :edit => (updating_class == "0")).save
        end
      when "6"
        params[:sharing_networks2].each do |n|
          Permission.new(:policy => policy,
              :contributor => (Network.find n[1].to_i),
              :view => 1, :download => 0, :edit => (updating_class == "0")).save
        end
    end

    case updating_class
      when "3" # some of my networks
        params[:updating_networkmembers].each do |n|
          Permission.new(:policy => policy,
              :contributor => (Network.find n[1].to_i),
              :view => 0, :download => 0, :edit => 1).save
        end
      when "5" # some of my friends
        params[:updating_somefriends].each do |f|
          Permission.new(:policy => policy,
              :contributor => (User.find f[1].to_i),
              :view => 0, :download => 0, :edit => 1).save
        end
    end

    contributable.contribution.policy = policy
    contributable.contribution.save

    puts "------ Workflow create summary ------------------------------------"
    puts "current_user   = #{current_user.id}"
    puts "updating_class = #{updating_class}"
    puts "sharing_class  = #{sharing_class}"
    puts "policy         = #{policy}"
    puts "Sharing net1   = #{params[:sharing_networks1]}"
    puts "-------------------------------------------------------------------"

  end

  def determine_sharing_mode(contributable)

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

    else        

      mode5 = true
      mode6 = true

      policy.permissions.each do |p|

        if (p.contributor_type != 'Network')
          mode5 = false
          mode6 = false
        end

        if ((p.view != true) || (p.download != true))
          mode5 = false
        end

        if ((p.view != true) || (p.download != false))
          mode6 = false
        end

      end

      return 5 if mode5
      return 6 if mode6

    end

    return 8

  end

  def determine_updating_mode(contributable)

    policy = contributable.contribution.policy

    return policy.update_mode if !policy.update_mode.nil?

    v_pub  = policy.view_public;
    v_prot = policy.view_protected;
    d_pub  = policy.download_public;
    d_prot = policy.download_protected;
    e_pub  = policy.edit_public;
    e_prot = policy.edit_protected;

    perms  = policy.permissions.select do |p| p.edit end

    if (perms.empty?)

      # mode 1? only friends and network members can edit
   
      if (e_pub == false and e_prot == true)
        return 1
      end
   
      # mode 6? noone else
   
      if (e_pub == false and e_prot == false)
        return 6
      end

    else

      # mode 0? same as those that can view or download

      if (e_pub == v_pub or d_pub)
        if (e_prot == v_prot or d_prot)
          if (perms.collect do |p| p.edit != p.view or p.download end).empty?
            return 0;
          end
        end
      end

      contributor = User.find(contributable.contributor_id)

      contributors_friends  = contributor.friends.map do |f| f.id end
      contributors_networks = (contributor.networks + contributor.networks_owned).map do |n| n.id end

      my_networks    = []
      other_networks = []
      my_friends     = []
      other_users    = []

      puts "contributors_networks = #{contributors_networks.map do |n| n.id end}"

      perms.each do |p|
      puts "contributor_id = #{p.contributor_id}"
        case
          when 'Network'

            if contributors_networks.index(p.contributor_id).nil?
              other_networks.push p
            else
              my_networks.push p
            end

          when 'User'

            if contributors_friends.index(p.contributor_id).nil?
              other_users.push p
            else
              friends.push p
            end

        end
      end

      puts "my_networks    = #{my_networks.length}"
      puts "other_networks = #{other_networks.length}"
      puts "my_friends     = #{my_friends.length}"
      puts "other_users    = #{other_users.length}"

      if (other_networks.empty? and other_users.empty?)

        # mode 3? members of some of my networks?
   
        if (!my_networks.empty? and my_friends.empty?)
          return 3 
        end

        # mode 5? some of my friends?

        if (my_networks.empty? and !my_friends.empty?)
          return 5
        end

      end
    end

    # custom

    return 7

  end

  def refresh_tags(taggable, tags, tagger)

    old_tags = taggable.tags.map do |tag| tag.name end
    new_tags = Tag.parse(tags)

    puts "#DEBUG: old_tags = #{old_tags}"
    puts "#DEBUG: new_tags = #{new_tags}"

    # remove tags

    taggable.taggings.each do |tagging|

      name = tagging.tag.name

      if new_tags.index(name) == nil
        tagging.destroy
        tag = Tag.find_by_name(name)
        tag.destroy if tag.taggings_count == 0
      end

    end

    # add tags

    (new_tags - old_tags).each do |name|

      tag = Tag.find_by_name(name);

      if tag.nil?
        tag = Tag.new(:name => name)
        tag.save
      end

      Tagging.new(:tag_id => tag.id,
          :taggable_type => taggable.class.to_s,
          :taggable_id => taggable.id,
          :user_id => tagger.id).save
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
  
end
