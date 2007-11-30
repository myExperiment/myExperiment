# myExperiment: lib/acts_as_attributor.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Dgc
  module Acts #:nodoc:
    module Attributor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_attributor
          has_many :attributions,
                   :as => :attributor,
                   :order => "attributable_type ASC, created_at DESC",
                   :dependent => :destroy

          class_eval do
            extend Dgc::Acts::Attributor::SingletonMethods
          end
          include Dgc::Acts::Attributor::InstanceMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Dgc::Acts::Attributor
end
