#
#
# Copyright (c) 2007, Mark Borkum (mib104@ecs.soton.ac.uk)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# 

module Squirrel # :nodoc

  def self.go
    puts "phase 0 - house keeping"
    @tuples = self.sql_to_hash("#{RAILS_ROOT}/carlin/myexperiment_production.sql", "pictures", "moderatorships", "monitorships", "posts", "topics")

    names = {}
    @tuples["profiles"].each do |profile_tuple|
      names[profile_tuple["user_id"]] = profile_tuple["name"]
    end
    
    pictures = {}
    @tuples["users"].each do |user_tuple|
      pictures[user_tuple["id"]] = user_tuple["avatar"]
    end
    
    forums = {}
    @tuples["projects"].each do |project_tuple|
      forums[project_tuple["forum_id"]] = project_tuple["id"]
    end
    
    permissions = {}
    @tuples["workflows"].each do |workflow_tuple|
      edit_u, view_u, download_u = acl_to_permission(workflow_tuple["acl_r"], workflow_tuple["acl_m"], workflow_tuple["acl_d"])
      edit_p, view_p, download_p = acl_to_permission(workflow_tuple["acl_r"], workflow_tuple["acl_m"], workflow_tuple["acl_d"], false)
      
      permissions[workflow_tuple["id"]] = { "user" => { "edit" => edit_u, "view" => view_u, "download" => download_u},
                                            "project" => { "edit" => edit_p, "view" => view_p, "download" => download_p} }
    end
    puts "end phase 0"
    
    puts "phase 1 - user accounts"
    @tuples["users"].each do |user_tuple|
      User.create(:id               => user_tuple["id"],
                  :openid_url       => user_tuple["openid_url"],
                  :name             => names[user_tuple["id"]],
                  :created_at       => user_tuple["created_at"],
                  :updated_at       => user_tuple["updated_at"],
                  :posts_count      => user_tuple["posts_count"],
                  :last_seen_at     => user_tuple["last_seen_at"],
                  :username         => user_tuple["username"],
                  :crypted_password => user_tuple["crypted_password"],
                  :salt             => user_tuple["salt"])
    end
    puts "end phase 1"
    
    puts "phase 2 - user assets"
    puts "Pictures must be imported manually"
    @tuples["blogs"].each do |blog_tuple|
      unless (blog = Blog.find_by_contributor_id_and_contributor_type(blog_tuple["user_id"], "User"))
        blog = Blog.create(:contributor_id    => blog_tuple["user_id"],
                           :contributor_type  => "User",
                           :title             => "#{names[blog_tuple["user_id"]]}'s Blog",
                           :created_at        => blog_tuple["created_at"],
                           :updated_at        => blog_tuple["created_at"])
      end
    
      BlogPost.create(:id         => blog_tuple["id"],
                      :blog_id    => blog.id,
                      :title      => blog_tuple["title"],
                      :body       => blog_tuple["body"],
                      :created_at => blog_tuple["created_at"],
                      :updated_at => blog_tuple["created_at"])
    end
    
    @tuples["profiles"].each do |profile_tuple|
      profile = User.find(profile_tuple["user_id"]).profile
      
      profile.update_attributes({ :picture_id   => pictures[profile_tuple["user_id"]],
                                  :email        => profile_tuple["email"],
                                  :website      => profile_tuple["website"],
                                  :description  => profile_tuple["profile"],
                                  :created_at   => profile_tuple["created_at"],
                                  :updated_at   => profile_tuple["updated_at"] })
    end
    
    @tuples["friendships"].each do |friendship_tuple|
      Friendship.create(:user_id      => friendship_tuple["user_id"],
                        :friend_id    => friendship_tuple["friend_id"],
                        :created_at   => friendship_tuple["created_at"],
                        :accepted_at  => friendship_tuple["accepted_at"])
    end
                      
    @tuples["messages"].each do |message_tuple|
      Message.create(:id          => message_tuple["id"],
                     :from        => message_tuple["from_id"],
                     :to          => message_tuple["to_id"],
                     :subject     => message_tuple["subject"],
                     :body        => message_tuple["body"],
                     :reply_id    => message_tuple["reply_id"],
                     :created_at  => message_tuple["created_at"],
                     :read_at     => message_tuple["read_at"])
    end
    puts "end phase 2"
                   
    puts "phase 3 - projects"
    @tuples["projects"].each do |project_tuple|
      Network.create(:id          => project_tuple["id"],
                     :user_id     => project_tuple["user_id"],
                     :title       => project_tuple["title"],
                     :unique      => project_tuple["unique"],
                     :created_at  => project_tuple["created_at"],
                     :updated_at  => project_tuple["updated_at"])
    end
    puts "end phase 3"
    
    puts "phase 4 - project assets"
    @tuples["memberships"].each do |membership_tuple|
      unless Network.find_by_id_and_user_id(membership_tuple["project_id"], membership_tuple["user_id"])
        Membership.create(:user_id      => membership_tuple["user_id"],
                          :network_id   => membership_tuple["project_id"],
                          :created_at   => Time.now,
                          :accepted_at  => Time.now)
      end
    end
    puts "end phase 4"
    
    puts "phase 5 - workflows"
    @tuples["workflows"].each do |workflow_tuple|
      workflow = create_workflow("#{RAILS_ROOT}/carlin/scufl/#{workflow_tuple["id"]}/#{workflow_tuple["scufl"]}",
                                 workflow_tuple["id"], 
                                 workflow_tuple["user_id"])
                                 
      workflow.save
      
      workflow.update_attributes({ :title       => workflow_tuple["title"],
                                   :description => workflow_tuple["description"] })
      
      edit_pub, view_pub, download_pub, edit_pro, view_pro, download_pro = acl_to_policy(workflow_tuple["acl_r"], workflow_tuple["acl_m"], workflow_tuple["acl_d"])
      policy = Policy.create(:contributor        => workflow.contributor,
                             :name               => "Policy for #{workflow.title}",
                             :download_public    => download_pub,
                             :edit_public        => edit_pub, 
                             :view_public        => view_pub, 
                             :download_protected => download_pro,
                             :edit_protected     => edit_pro,
                             :view_protected     => view_pro)
                             
      workflow.contribution.update_attribute(:policy_id, policy.id)
    end
                  
    @tuples["sharing_projects"].each do |sharing_project_tuple|
      policy = Workflow.find(sharing_project_tuple["workflow_id"]).contribution.policy
      
      Permission.create(:contributor_id     => sharing_project_tuple["project_id"],
                        :contributor_type   => "Network",
                        :policy_id          => policy.id,
                        :download           => permissions[sharing_project_tuple["workflow_id"]]["project"]["download"],
                        :edit               => permissions[sharing_project_tuple["workflow_id"]]["project"]["edit"],
                        :view               => permissions[sharing_project_tuple["workflow_id"]]["project"]["view"])
    end
                      
    @tuples["sharing_users"].each do |sharing_user_tuple|
      policy = Workflow.find(sharing_user_tuple["workflow_id"]).contribution.policy
      
      Permission.create(:contributor_id     => sharing_user_tuple["user_id"],
                        :contributor_type   => "User",
                        :policy_id          => policy.id,
                        :download           => permissions[sharing_user_tuple["workflow_id"]]["user"]["download"],
                        :edit               => permissions[sharing_user_tuple["workflow_id"]]["user"]["edit"],
                        :view               => permissions[sharing_user_tuple["workflow_id"]]["user"]["view"])
    end                  
    puts "end phase 5"
    
    puts "phase 6 - workflow assets"
    @tuples["bookmarks"].each do |bookmark_tuple|
      Bookmark.create(:id                   => bookmark_tuple["id"],
                      :title                => bookmark_tuple["title"],
                      :created_at           => bookmark_tuple["created_at"],
                      :bookmarkable_id      => bookmark_tuple["bookmarkable_id"],
                      :bookmarkable_type    => bookmark_tuple["bookmarkable_type"],
                      :user_id              => bookmark_tuple["user_id"])
    end
                    
    @tuples["comments"].each do |comment_tuple|
      Comment.create(:id                => comment_tuple["id"],
                     :title             => comment_tuple["title"],
                     :comment           => comment_tuple["comment"],
                     :commentable_id    => comment_tuple["commentable_id"],
                     :commentable_type  => comment_tuple["commentable_type"],
                     :user_id           => comment_tuple["user_id"])
    end
    
    @tuples["ratings"].each do |rating_tuple|
      Rating.create(:id               => rating_tuple["id"],
                    :rating           => rating_tuple["rating"],
                    :rateable_id      => rating_tuple["rateable_id"],
                    :rateable_type    => rating_tuple["rateable_type"],
                    :user_id          => rating_tuple["user_id"])
    end
    
    @tuples["tags"].each do |tag_tuple|
      Tag.create(:id                => tag_tuple["id"],
                 :name              => tag_tuple["name"],
                 :taggings_count    => 0)
    end
               
    @tuples["taggings"].each do |tagging_tuple|
      Tagging.create(:id              => tagging_tuple["id"],
                     :tag_id          => tagging_tuple["tag_id"],
                     :taggable_id     => tagging_tuple["taggable_id"],
                     :taggable_type   => tagging_tuple["taggable_type"],
                     :user_id         => nil,
                     :created_at      => Time.now)
    end
                   
    taggings_count = {}
    Tagging.find(:all, :order => "tag_id ASC").each do |tagging_record|
      if taggings_count[tagging_record.tag_id]
        taggings_count[tagging_record.tag_id] = taggings_count[tagging_record.tag_id].to_i + 1
      else
        taggings_count[tagging_record.tag_id] = 1
      end
    end
    
    taggings_count.each do |tag_id, count|
      Tag.find(tag_id).update_attribute(:taggings_count, count)
    end
    puts "end phase 6"
    
    puts "phase 7 - forums"
    @tuples["forums"].each do |forum_tuple|
      forum = Forum.create(:id                  => forum_tuple["id"],
                           :contributor_id      => forums[forum_tuple["id"]],
                           :contributor_type    => "Network",
                           :name                => forum_tuple["name"],
                           :posts_count         => forum_tuple["posts_count"],
                           :topics_count        => forum_tuple["topics_count"],
                           :position            => forum_tuple["position"],
                           :description         => forum_tuple["description"])
                           
      policy = Policy.create(:contributor        => forum.contributor.owner,
                             :name               => "Policy for #{forum.name}",
                             :download_public    => false,
                             :edit_public        => false, 
                             :view_public        => (forum_tuple["public"].to_i == 1), 
                             :download_protected => false,
                             :edit_protected     => false,
                             :view_protected     => (forum_tuple["public"].to_i == 0))
                             
      forum.contribution.update_attribute(:policy_id, policy.id)
    end
    puts "end phase 7"
    
    puts "phase 8 - forum assets"
    puts "Moderatorships, Monitorships, Posts and Topics must be imported manually"
    puts "end phase 8"
    
    true
  end

  # The Squirrel serves a single purpose, to convert the SQL dump of a database into a 
  # format that is useful for a dba (particularly when the database corresponds to a Rails model).
  #
  # This function takes two parameters, the path to the +sql_dump+ file and a list of table names 
  # to be +exclude+d from the resulting hash. The +schema_info+ table is automatically removed if found. 
  #
  # The returned hash has a key for each table name, each value is an array of hashs, where each hash
  # is a mapping between schema attributes and "INSERT INTO..." values. 
  #
  # == Useage
  # include Squirrel
  # myhash = Squirrel.sql_to_hash(myfile.path, "foobars")
  # myhash.each do |table_name, objects|
  #   objects.each do |object|
  #     # do something with object
  #   end
  # end
  def self.sql_to_hash(sql_dump, *exclude)
    rtn = {}
    
    read(sql_dump, rtn)
    
    exclude << "schema_info" if rtn["schema_info"] and !exclude.include?("schema_info")
    exclude.each do |table_name|
      rtn.delete(table_name) if rtn.key?(table_name)
    end
  
    parse(rtn)
  
    return rtn
  end

private

  # heavily modified version of workflow_controller.rb::create_workflow
  def create_workflow(scufl_file, old_id, contributor_id, contributor_type="User")
    sf = File.open(scufl_file)
    
    scufl_model = Scufl::Parser.new.parse(sf.read)
    sf.rewind
    
    salt = rand 32768
    title, unique = scufl_model.description.title.blank? ? ["untitled", "untitled_#{salt}"] : [scufl_model.description.title,  "#{scufl_model.description.title.gsub(/[^\w\.\-]/,'_').downcase}_#{salt}"]
    
    unless RUBY_PLATFORM =~ /mswin32/
      i = Tempfile.new("image")
      Scufl::Dot.new.write_dot(i, scufl_model)
      i.close(false)
      d = StringIO.new(`dot -Tpng #{i.path}`)
      i.unlink
      d.extend FileUpload
      d.original_filename = "#{unique}.png"
      d.content_type = "image/png"
    end
    
    rtn = Workflow.new(:id => old_id,
                       :scufl => sf.read, 
                       :contributor_id => contributor_id, 
                       :contributor_type => contributor_type,
                       :title => title,
                       :unique => unique,
                       :description => scufl_model.description.description)
                       
    unless RUBY_PLATFORM =~ /mswin32/
      rtn.image = d
    end
    
    sf.close
    
    return rtn
  end
  
  def acl_to_policy(acl_r, acl_m, acl_d)
    edit_pub, view_pub, download_pub, edit_pro, view_pro, download_pro = false, false, false, false, false, false
    
    case acl_r.to_i
    when 4..7
      view_pro = download_pro = true
    when 8
      view_pub = download_pub = true
    end
    
    case acl_m.to_i
    when 4..7
      edit_pro = true
    when 8
      edit_pub = true
    end
    
    return edit_pub, view_pub, download_pub, edit_pro, view_pro, download_pro
  end
  
  def acl_to_permission(acl_r, acl_m, acl_d, user=true)
    edit, view, download = false, false, false
    
    # acl - permissions
    # 0 - owner only (owner for 1-8 incl.)
    # 1 - projects
    # 2 - users
    # 3 - users and projects
    # 4 - friends
    # 5 - friends and projects
    # 6 - friends and users
    # 7 - friends, users and projects
    # 8 - ALL
    
    if user
      case acl_r.to_i
      when 2..3, 6..7
        view = download = true
      end
      
      case acl_m.to_i
      when 2..3, 6..7
        edit = true
      end
    else
      case acl_r.to_i
      when 1, 3, 5, 7
        view = download = true
      end
      
      case acl_m.to_i
      when 1, 3, 5, 7
        edit = true
      end
    end
    
    return edit, view, download
  end

  def chomper(str)
    current = str[i = 0, 1]
  
    if current =~ /\d/
      output = current
    
      i = i.to_i + 1
      while true
        current = str[i, 1]
        if current =~ /\d/
          output = output + current
        else
          break
        end
        i = i.to_i + 1
      end
      return output, str[i.to_i + 1...str.length]
    elsif current =~ /'/
      output = ""
    
      i = i.to_i + 1
      while true
        current = str[i, 1]
        if current =~ /'/
          if (i.to_i + 1 == str.length) or str[i.to_i + 1, 1] =~ /,/
            break
          else
            output = output + current
          end
        else
          output = output + current
        end
        i = i.to_i + 1
      end
      return output, str[i.to_i + 2...str.length]
    elsif current =~ /N/
      output = (str[i, 4] =~ /NULL/) ? "NULL" : ""
      return output, str[i.to_i + 5...str.length]
    else
      # nothing
    end
  end

  def chomp(str)
    rtn = []
  
    input = str
    while true
      output, input = chomper(input)
      rtn << output
      break if input.nil?
    end
  
    return rtn
  end

  def read(file, hash)
    arr, i = File.open(file).readlines, 0
    while i < arr.length
      if arr[i] =~ /^CREATE TABLE `([a-z_]*)`/
        hash[key = $1] ||= []
        schema = []
    
        while true
          if arr[i = i.to_i + 1] =~ /^\s*`([a-z_]*)`/
            attribute = $1
            schema << attribute
          else
            break
          end
        end
    
        hash[key] << schema.join(",")
      elsif arr[i] =~ /^INSERT INTO `([a-z_]*)` VALUES (.*)/
        key, tuples = $1, $2
        tuples[1..-3].split("),(").each do |tuple| 
          hash[key] << tuple
        end
      else
        # do nothing
      end
  
      i = i.to_i + 1
    end
  end

  def parse(hash)
    hash.keys.sort.each do |table_name|
      schema = hash[table_name][0].split(",")
    
      i = 1
      while i < hash[table_name].length
        input, record = hash[table_name][i], {}
        chomped = chomp(input)
      
        j = 0
        while j < schema.length
          # bug - "Mark\\'s forum", "\\r\\n\\r", "\\\"" --> "\['"rn]"
          result = (chomped[j] =~ /NULL/) ? nil : CGI::unescape(chomped[j])
          result = result.to_i if result =~ /^[0-9]+$/
          
          record[schema[j]] = result
          j = j.to_i + 1
        end
        hash[table_name][i] = record
        i = i.to_i + 1
      end
    
      hash[table_name][0] = nil
      hash[table_name].compact!
    end
  end

  module FileUpload
    attr_accessor :original_filename, :content_type
  end
end