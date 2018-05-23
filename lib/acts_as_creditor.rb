# myExperiment: lib/acts_as_creditor.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Dgc
  module Acts #:nodoc:
    module Creditor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_creditor
          has_many :creditations,
                   :as => :creditor,
                   :order => "creditable_type ASC, created_at DESC"

          class_eval do
            extend Dgc::Acts::Creditor::SingletonMethods
          end
          include Dgc::Acts::Creditor::InstanceMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
        def hidden?
          respond_to?(:hidden) ? hidden : false
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Dgc::Acts::Creditor
end
