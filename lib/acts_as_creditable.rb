# myExperiment: lib/acts_as_creditable.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Dgc
  module Acts #:nodoc:
    module Creditable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_creditable
          has_many :creditations,
                   :as => :creditable,
                   :order => "creditable_type ASC, created_at DESC",
                   :dependent => :destroy

          class_eval do
            extend Dgc::Acts::Creditable::SingletonMethods
          end
          include Dgc::Acts::Creditable::InstanceMethods
          
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods

        def creditors
          return Creditation.find_all_by_creditable_id_and_creditable_type(self.id, self.class.to_s);
        end

      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Dgc::Acts::Creditable
end
