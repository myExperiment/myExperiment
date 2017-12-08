module Acts #:nodoc:
  module Bookmarkable #:nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_bookmarkable
        has_many :bookmarks, :as => :bookmarkable, :dependent => :destroy
        include Acts::Bookmarkable::BookmarkableInstanceMethods
      end
    end

    module BookmarkableInstanceMethods
      def bookmarked_by_user?(user)
        user && bookmarks.where(user_id: user.id).any?
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::Bookmarkable
end
