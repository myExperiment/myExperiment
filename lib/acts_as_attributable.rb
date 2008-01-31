# myExperiment: lib/acts_as_attributable.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Dgc
  module Acts #:nodoc:
    module Attributable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_attributable
          belongs_to :attributor, :polymorphic => true
          
          class_eval do
            extend Dgc::Acts::Attributable::SingletonMethods
          end
          include Dgc::Acts::Attributable::InstanceMethods
          
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods

        def attributors
          return Attribution.find_all_by_attributable_id_and_attributable_type(self.id, self.class.to_s);
        end

      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Dgc::Acts::Attributable
end
