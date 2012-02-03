# myExperiment: lib/acts_as_site_entity.rb
#
# Copyright (c) 2009 University of Manchester and the University of Southampton.
# See license.txt for details.

module MyExperiment
  module Acts #:nodoc:
    module SiteEntity #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_site_entity(args = {})

          class_eval do
            extend MyExperiment::Acts::SiteEntity::SingletonMethods
          end
          include MyExperiment::Acts::SiteEntity::InstanceMethods
          
          self.owner_text = args[:owner_text] ? args[:owner_text] : ''
        end
      end
      
      module SingletonMethods

        def owner_text=(new_value)
          @owner_text = new_value
        end

        def owner_text
          @owner_text
        end
      end
      
      module InstanceMethods

        def label
          return name  if respond_to?('name')
          return title if respond_to?('title')
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include MyExperiment::Acts::SiteEntity
end

