# myExperiment: lib/account_management.rb
#
# Copyright (c) 2010 University of Manchester and the University of Southampton.
# See license.txt for details.

module AccountManagement

  mattr_accessor :database_tables

  @@database_tables = {
    :activity_limits            => { :owner => :contributor, :skip_on_merge => true },
    :announcements              => { :owner => :user_id },
    :attributions               => { :owner => :derived },
    :blobs                      => { :owner => :contributor },
    :blogs                      => { :owner => :contributor },
    :blog_posts                 => { :owner => :derived },
    :bookmarks                  => { :owner => :user_id },
    :citations                  => { :owner => :user_id },
    :client_applications        => { :owner => :user_id },
    :comments                   => { :owner => :user_id },
    :content_blobs              => { :owner => :derived },
    :content_types              => { :owner => :user_id },
    :contributions              => { :owner => :derived },
    :creditations               => { :owner => :derived },
    :curation_events            => { :owner => :user_id },
    :downloads                  => { :owner => :user_id },
    :experiments                => { :owner => :contributor },
    :friendships                => { :owner => :user_id_or_friend_id },
    :group_announcements        => { :owner => :user_id },
    :jobs                       => { :owner => :user_id },
    :key_permissions            => { :owner => :derived },
    :license_attributes         => { :owner => :derived },
    :license_options            => { :owner => :derived },
    :licenses                   => { :owner => :user_id },
    :memberships                => { :owner => :user_id },
    :messages                   => { :owner => :to_or_from },
    :networks                   => { :owner => :user_id },
    :oauth_nonces               => { :owner => :unknown },
    :oauth_tokens               => { :owner => :user_id },
    :pack_contributable_entries => { :owner => :user_id },
    :pack_remote_entries        => { :owner => :user_id },
    :packs                      => { :owner => :contributor },
    :pending_invitations        => { :owner => :requested_by },
    :permissions                => { :owner => :derived },
    :picture_selections         => { :owner => :user_id, :skip_on_merge => true },
    :pictures                   => { :owner => :user_id },
    :plugin_schema_info         => { :ignore =>  true },
    :policies                   => { :owner => :contributor },
    :profiles                   => { :owner => :user_id, :skip_on_merge => true },
    :ratings                    => { :owner => :user_id },
    :relationships              => { :ignore => :true },
    :remote_workflows           => { :owner => :unknown },
    :reviews                    => { :owner => :user_id },
    :schema_info                => { :ignore => :true },
    :sessions                   => { :ignore => :true },
    :taggings                   => { :owner => :user_id },
    :tags                       => { :owner => :unknown },
    :taverna_enactors           => { :owner => :contributor },
    :users                      => { :owner => :unknown, :skip_on_merge => true },
    :viewings                   => { :owner => :user_id },
    :vocabularies               => { :owner => :user_id },
    :workflow_versions          => { :owner => :contributor, :model => 'Workflow::Version' },
    :workflows                  => { :owner => :contributor },
  }
    
  def self.user_resources(user_id)

    resources = {}

    database_tables.each do |k, v|

      next if v[:ignore]

      if v[:model]
        model = Object

        v[:model].split("::").each do |constant|
          model = model.const_get(constant)
        end
      else
        model = Object.const_get(k.to_s.singularize.camelize)
      end
      
      resources[k] = case v[:owner]
        when :user_id
          model.find(:all, :conditions => ['user_id = ?', user_id])
        when :contributor
          model.find(:all, :conditions => ['contributor_type = "User" AND contributor_id = ?', user_id])
        when :user_id_or_friend_id
          model.find(:all, :conditions => ['user_id = ? OR friend_id = ?', user_id, user_id])
        when :requested_by
          model.find(:all, :conditions => ['requested_by = ?', user_id])
        when :to_or_from
          model.find(:all, :conditions => ['`to` = ? OR `from` = ?', user_id, user_id])
      end
    end

    resources
  end

  def self.change_ownership(old_id, new_id)

    begin

      ActiveRecord::Base.record_timestamps = false

      user_resources(old_id).each do |category, records|

        next if database_tables[category][:ignore]
        next if database_tables[category][:skip_on_merge]

        case database_tables[category][:owner]

          when :user_id

            records.each do |record|

              record.update_attribute(:user_id, new_id)
            end

          when :contributor

            records.each do |record|

              record.update_attribute(:contributor_type, 'User')
              record.update_attribute(:contributor_id,   new_id)
            end

          when :user_id_or_friend_id

            records.each do |record|

              if record.user_id == old_id
                record.update_attribute(:user_id, new_id)
              end

              if record.friend_id == old_id
                record.update_attribute(:friend_id, new_id)
              end
            end

          when :requested_by

            records.each do |record|

              record.update_attribute(:requested_by, new_id)
            end

          when :to_or_from

            records.each do |record|

              if record.to == old_id
                record.update_attribute(:to, new_id)
              end

              if record.from == old_id
                record.update_attribute(:from, new_id)
              end
            end
        end
      end

    ensure
      ActiveRecord::Base.record_timestamps = true
    end

    User.find(old_id).destroy
  end

  def self.compare_tables_and_schema

    conn   = ActiveRecord::Base.connection
    tables = conn.tables.map do |table| table.to_sym end

    missing = database_tables.keys - tables
    extra   = tables - database_tables.keys

    missing.each do |table_name|
      logger.warn("Missing table from account management: #{table_name}")
    end

    extra.each do |table_name|
      logger.warn("Extra table in account management: #{table_name}")
    end
  end
end

