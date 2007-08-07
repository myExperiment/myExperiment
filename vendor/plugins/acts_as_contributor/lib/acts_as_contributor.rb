module Mib
  module Acts #:nodoc:
  
    module Contributor #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_contributor
          has_many :contributions, :as => :contributor
          has_many :policies, :as => :contributor
          has_many :permissions, :as => :contributor
          
          class_eval do
            extend Mib::Acts::Contributor::SingletonMethods
          end
          include Mib::Acts::Contributor::InstanceMethods
        end
      end
      
      module SingletonMethods
      end
      
      module InstanceMethods
        # extend in instance class
        def related?(other)
          false
        end
      end
    end
    
    module Contributable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_contributable
          has_one :contribution, :as => :contributable
          
          class_eval do
            extend Mib::Acts::Contributable::SingletonMethods
          end
          include Mib::Acts::Contributable::InstanceMethods
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
  include Mib::Acts::Contributor
  include Mib::Acts::Contributable
end