# myExperiment: lib/acts_as_runnable.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

module Jits
  module Acts #:nodoc:
    module Runnable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_runnable
          has_many :jobs,
                   :as => :runnable,
                   :order => "updated_at DESC"

          class_eval do
            extend Jits::Acts::Runnable::SingletonMethods
          end
          include Jits::Acts::Runnable::InstanceMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
        # TODO: abstract out the set of methods that define a contract for a runnable and declare them here.
        # To be overridden in the specialised model object.
        
        def get_input_ports
          nil
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Jits::Acts::Runnable
end