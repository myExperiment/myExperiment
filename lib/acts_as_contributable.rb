# myExperiment: lib/acts_as_contributable.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Mib
  module Acts #:nodoc:
    module Contributable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_contributable
          belongs_to :contributor, :polymorphic => true
          
          has_one :contribution, 
                  :as => :contributable,
                  :dependent => :destroy
                  
          after_save :save_contributable_record
          after_save :update_contribution_rank
          after_save :update_contribution_rating
          after_save :update_contribution_cache

          class_eval do
            extend Mib::Acts::Contributable::SingletonMethods
          end
          include Mib::Acts::Contributable::InstanceMethods
          
          before_create do |c|

            # If not specified, create a contribution record and / or policy
            # record.

            if c.contribution.nil?
              c.contribution = Contribution.new(
                  :contributor   => c.contributor,
                  :contributable => c)
            end

            c.contribution.contributor ||= c.contributor

            if c.contribution.policy.nil?
              c.contribution.policy = create_default_policy(c.contributor)
            end

          end
        end
      end
      
      module SingletonMethods
        def find_all_by_contributor(contributor, options = {})
          find_all_by_contributor_id_and_contributor_type(contributor.id, contributor.class.to_s, options)
        end
        
        def find_all_by_contributor_id_and_contributor_type(contributor_id, contributor_type, options = {})
          # protect the original sql statement
          options.delete(:select) if options[:select]
          options.delete(:joins) if options[:joins]
          
          select_columns = ""
          columns.each do |c|
            select_columns << ", " unless select_columns.empty?
            select_columns << "#{table_name}.#{c.name}"
          end
          
          find(:all, { :select => select_columns, 
                       :joins => "LEFT OUTER JOIN contributions ON contributions.contributor_id = #{contributor_id} AND contributions.contributor_type = '#{contributor_type}'"}.merge(options))
        end
      end
      
      module InstanceMethods

        # the owner of the contribution record for this contributable
        def owner?(c_utor)
          contribution.owner?(c_utor)
        end
        
        # the last contributor to upload this contributable
        def uploader?(c_utor)
          contributor_id.to_i == c_utor.id.to_i and contributor_type.to_s == c_utor.class.to_s
        end

        def contributor_name
          return nil if contribution.nil?
          return contribution.contributor.name  if contribution.contributor.respond_to?('name')
          return contribution.contributor.title if contribution.contributor.respond_to?('title')
        end
        
        # This is so that the updated_at time on the record tallies up with the
        # contributable
        def save_contributable_record
          if contribution
            inhibit_timestamps do
              contribution.update_attribute(:updated_at, contribution.contributable.updated_at)
            end
          end
        end

        def update_contribution_rank
          if contribution

            if respond_to?(:rank)
              value = rank
            else
              value = 0.0
            end

            inhibit_timestamps do
              contribution.update_attribute(:rank, value)
            end
          end
        end

        def update_contribution_rating
          if contribution

            if respond_to?(:rating)
              value = rating
            else
              value = 0.0
            end

            inhibit_timestamps do
              contribution.update_attribute(:rating, value)
            end
          end
        end

        def update_contribution_cache
          if contribution
            inhibit_timestamps do
              contribution.update_attribute(:label,           respond_to?(:label)           ? label           : nil)
              contribution.update_attribute(:content_type_id, respond_to?(:content_type_id) ? content_type_id : nil)
              contribution.update_attribute(:license_id,      respond_to?(:license_id)      ? license_id      : nil)
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Mib::Acts::Contributable
end
