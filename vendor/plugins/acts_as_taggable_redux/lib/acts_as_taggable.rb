module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_taggable(options = {})
          has_many :taggings, :as => :taggable, :dependent => :destroy, :include => :tag
          has_many :tags, :through => :taggings
          
          #after_save :update_tags
          
          extend ActiveRecord::Acts::Taggable::SingletonMethods          
          include ActiveRecord::Acts::Taggable::InstanceMethods
        end
      end
      
      module SingletonMethods
        # Pass a tag string, returns taggables that match the tag string.
        # 
        # Options:
        #   :match - Match taggables matching :all or :any of the tags, defaults to :any
        #   :user  - Limits results to those owned by a particular user
        def find_tagged_with(tags, options = {})
          options.assert_valid_keys([:match, :user])
          
          tags = Tag.parse(tags)
          return [] if tags.empty?
          
          group = "#{table_name}_taggings.taggable_id HAVING COUNT(#{table_name}_taggings.taggable_id) = #{tags.size}" if options[:match] == :all
          conditions = sanitize_sql(["#{table_name}_tags.name IN (?)", tags])
          conditions += sanitize_sql([" AND #{table_name}_taggings.user_id = ?", options[:user]]) if options[:user]
          
          find(:all, 
            { 
              :select =>  "DISTINCT #{table_name}.*",
              :joins  =>  "LEFT OUTER JOIN taggings #{table_name}_taggings ON #{table_name}_taggings.taggable_id = #{table_name}.#{primary_key} AND #{table_name}_taggings.taggable_type = '#{name}' " +
                          "LEFT OUTER JOIN tags #{table_name}_tags ON #{table_name}_tags.id = #{table_name}_taggings.tag_id",
              :conditions => conditions,
              :group  =>  group
            })
        end
        
        # Pass a tag string, returns taggables that match the tag string for a particular user.
        # 
        # Options:
        #   :match - Match taggables matching :all or :any of the tags, defaults to :any
        def find_tagged_with_by_user(tags, user, options = {})
          options.assert_valid_keys([:match])
          find_tagged_with(tags, {:match => options[:match], :user => user})
        end
      end
      
      module InstanceMethods
        def tag_list=(new_tag_list)
          unless tag_list == new_tag_list
            @new_tag_list = new_tag_list
          end
        end
        
        def tags_user_id=(new_user_id)
          @new_user_id = User.find(new_user_id).id
        end
        
        def tag_list(user = nil)
          unless user
            tags.collect { |tag| tag.name.include?(" ") ? %("#{tag.name}") : tag.name }.join(" ")
          else
            tags.delete_if { |tag| !user.tags.include?(tag) }.collect { |tag| tag.name.include?(" ") ? %("#{tag.name}") : tag.name }.join(" ")
          end
        end

        def add_tag(tag, tagger)
          Tag.find_or_create_by_name(tag).tag(self, tagger.id)
        end

        def remove_tag(name)

          return unless tag = Tag.find_by_name(name)

          return unless tagging = Tagging.find_by_tag_id_and_taggable_type_and_taggable_id(tag.id,
              self.contribution.contributable_type, self.contribution.contributable_id)

          tagging.destroy
          tag = Tag.find_by_name(name)
          tag.destroy if tag.taggings_count == 0
        end

        def refresh_tags(tag_list, tagger)

          Tag.transaction do

            old_tags = tags.map do |tag| tag.name end
            new_tags = Tag.parse(tag_list).map do |t| t.strip end

            (old_tags - new_tags).each do |name| remove_tag(name)      end
            (new_tags - old_tags).each do |name| add_tag(name, tagger) end
          end
        end

        def update_tags
          if @new_tag_list
            Tag.transaction do
              #unless @new_user_id
                #taggings.destroy_all
              #else
                #taggings.find(:all, :conditions => "user_id = #{@new_user_id}").each do |tagging|
                  #tagging.destroy
                #end
              #end
            
              #Tag.parse(@new_tag_list).each do |name|
                #Tag.find_or_create_by_name(name).tag(self, @new_user_id)
              #end

              #tags.reset
              #taggings.reset
              #@new_tag_list = nil
              
              old_tag_ids = self.tags.collect { |t| t.id }
              Tag.parse(@new_tag_list).each do |new_tag_name|
                found = Tag.find_or_create_by_name(new_tag_name)
                
                unless old_tag_ids.include? found.id
                  found.tag(self, @new_user_id)
                end
              end
              
              tags.reset
              taggings.reset
              @new_tag_list = nil
            end
          end
        end
      end
    end
  end
end
