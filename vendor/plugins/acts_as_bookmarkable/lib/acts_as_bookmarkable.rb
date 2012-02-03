# ActsAsBookmarkable
module Juixe
  module Acts #:nodoc:
    module Bookmarkable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_bookmarkable
          has_many :bookmarks, :as => :bookmarkable, :dependent => :destroy
          include Juixe::Acts::Bookmarkable::BookmarkableInstanceMethods
          extend Juixe::Acts::Bookmarkable::BookmarkableSingletonMethods
        end

        def acts_as_bookmarker
          has_many :bookmarks, :order => "created_at DESC", :dependent => :destroy
          include Juixe::Acts::Bookmarkable::BookmarkerInstanceMethods
        end
      end
      
      # This module contains class methods for bookmarkables
      module BookmarkableSingletonMethods
        # Helper class method to lookup comments for
        # the mixin commentable type written by a given user.  
        # This method is NOT equivalent to Bookmark.find_bookmarks_for_user
        def find_bookmarks_by_user(user) 
          bookmarkable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Bookmark.find(:all,
            :conditions => ["user_id = ? and bookmarkable_type = ?", user.id, bookmarkable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods for bookmarkables
      module BookmarkableInstanceMethods
        # Check to see if a user already bookmaked this bookmarkable
        def bookmarked_by_user?(user)
          rtn = false
          if user
            self.bookmarks.each { |b|
              rtn = true if user.id == b.user_id
            }
          end
          rtn
        end
      end
      
      # This module contains instance methods for bookmarkers
      module BookmarkerInstanceMethods
        # Get all the bookmarked items for this user
        def bookmarked_items
          Bookmark.find(:all, :conditions => ["user_id = ?", self.id]).map do |b|
            b.bookmarkable
          end
        end
      end
    end
  end
end
