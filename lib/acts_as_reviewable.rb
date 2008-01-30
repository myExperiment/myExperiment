# myExperiment: lib/acts_as_reviewable.rb
#
# Copyright (c) 2007 University of Manchester and the University of Southampton.
# See license.txt for details.

# Based heavily on the acts_as_commentable plugin

module Jits
  module Acts #:nodoc:
    module Reviewable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_reviewable
          has_many :reviews, :as => :reviewable, :dependent => :destroy, :order => 'updated_at DESC'
          include Jits::Acts::Reviewable::InstanceMethods
          extend Jits::Acts::Reviewable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Helper method to lookup for reviews for a given object.
        # This method is equivalent to obj.reviews.
        def find_reviews_for(obj)
          reviewable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
         
          Review.find(:all,
            :conditions => ["reviewable_id = ? and reviewable_type = ?", obj.id, reviewable],
            :order => "updated_at DESC"
          )
        end
        
        # Helper class method to lookup reviews for
        # the mixin reviewable type written by a given user.  
        # This method is NOT equivalent to Review.find_reviews_for_user
        def find_reviews_by_user(user) 
          reviewable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Review.find(:all,
            :conditions => ["user_id = ? and reviewable_type = ?", user.id, reviewable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to sort reviews by date
        def reviews_ordered_by_submitted
          Review.find(:all,
            :conditions => ["reviewable_id = ? and reviewable_type = ?", id, self.type.name],
            :order => "created_at DESC"
          )
        end
        
        # Helper method that defaults the submitted time.
        def add_review(review)
          reviews << review
        end
      end
      
    end
  end
end

ActiveRecord::Base.class_eval do
  include Jits::Acts::Reviewable
end
