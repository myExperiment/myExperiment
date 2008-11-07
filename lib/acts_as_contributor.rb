# myExperiment: lib/acts_as_contributor.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Mib
  module Acts #:nodoc:
    module Contributor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_contributor
          has_many :contributions,
                   :as => :contributor,
                   :order => "contributable_type ASC, created_at DESC",
                   :dependent => :destroy

          has_many :policies,
                   :as => :contributor,
                   :order => "created_at DESC",
                   :dependent => :destroy

          has_many :permissions,
                   :as => :contributor,
                   :dependent => :destroy

          # before_destroy do |c|
          #   c.contributables.each do |contributable|
          #     # ABSOLUTLY NOTHING!!
          #     # it is important that contributables are left in the database.
          #     # that way, the dba can always retrieve them at a later date!
          #   end
          # end

          class_eval do
            extend Mib::Acts::Contributor::SingletonMethods
          end
          include Mib::Acts::Contributor::InstanceMethods
        end
        
        # returns groups that are most credited
        # the maximum number of results is set by #limit#
        def most_credited(limit=10)
          type = self.to_s
          title_or_name = (type.downcase == "user" ? "name" : "title")
          self.find_by_sql("SELECT n.* FROM #{type.downcase.pluralize} n JOIN creditations c ON c.creditor_id = n.id AND c.creditor_type = '#{type}' GROUP BY n.id ORDER BY COUNT(n.id) DESC, n.#{title_or_name} LIMIT #{limit}")
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
        def contributables
          rtn = []
          
          Contribution.find_all_by_contributor_id_and_contributor_type(self.id, self.class.to_s, { :order => "contributable_type ASC, contributable_id ASC" }).each do |c|
            # rtn << c.contributable_type.classify.constantize.find(c.contributable_id)
            rtn << c.contributable
          end

          return rtn
        end

        # this method is called by the Policy instance when authorizing protected attributes.
        def protected?(other)
          # extend in instance class
          false
        end
        
        # first method in the authorization chain
        # Mib::Acts::Contributor.authorized? --> Mib::Acts::Contributable.authorized? --> Contribution.authorized? --> Policy.authorized? --> Permission[s].authorized? --> true / false
        def authorized?(action_name, contributable)
          if contributable.kind_of? Mib::Acts::Contributable
            return contributable.authorized?(action_name, self)
          else
            return false
          end
        end
  
        def contribution_tags
          tags = contribution_tags!
          
          rtn = []
          
          tags.each { |key, value|
            rtn << value
          }
          
          return rtn
        end
        
        def collection_contribution_tags(collection)
          tags = collection_contribution_tags!(collection)
          
          rtn = []
          
          tags.each { |key, value|
            rtn << value
          }
          
          return rtn
        end
        
        def tag_list
          rtn = StringIO.new
          
          self.contribution_tags.each do |t|
            rtn << t.name
            rtn << " "
          end
          
          return rtn.string
        end
        
        def contributor_label
          return name  if self.respond_to?('name')
          return title if self.respond_to?('title')
        end

protected
        
        def collection_contribution_tags!(collection)
          tags = { }
          
          collection.each do |contributor|
            contributor.contribution_tags!.each { |key, value|
              if tags.key? key
                tags[key].taggings_count = tags[key].taggings_count.to_i + value.taggings_count.to_i
              else
                tags[key] = Tag.new(:name => key, :taggings_count => value.taggings_count)
              end
            }
          end
          
          return tags
        end
  
        def contribution_tags!
          tags = {}
          
          self.contributions.each do |c|
            c.contributable.tags.each do |t|
              if tags.key? t.name
                tags[t.name].taggings_count = tags[t.name].taggings_count.to_i + 1
              else
                tags[t.name] = Tag.new(:name => t.name, :taggings_count => 1)
              end
            end
          end
          
          return tags
        end
      
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Contributor
end
