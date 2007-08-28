module ActiveRecord
  module Acts #:nodoc:
    module Pageable #:nodoc:
      
      def self.included(base)
        base.extend ClassMethods  
      end
      
      module ClassMethods
        def acts_as_pageable
          has_many :pages, :as => :pageable, :dependent => true
          include ActiveRecord::Acts::Pageable::InstanceMethods
          extend ActiveRecord::Acts::Pageable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        
        def find_pages_for(obj)
          pageable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Comment.find(:all,
                       :conditions => ["pageable_id = ? and pageable_type = ?", obj.id, pageable],
          :order => "created_at DESC"
          )
        end
        
        def find_pages_by_user(user, options = {}) 
          pageable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Page.find(:all, {
            :conditions => ["user_id = ? and pageable_type = ?", user.id, pageable],
            :order => "created_at DESC" }.merge(options)
          )
        end
        
      end
      
      # This module contains instance methods
      module InstanceMethods
        def add_page(page)
          pages << page
        end
        
        def find_page_by_name(name)
          Page.find(:first,
            :conditions => ["pageable_id = ? and pageable_type = ? and name = ?", self.id, self.type.name, name]
          )        
        end
 
        def find_pages_by_namespace(namespace)
          Page.find(:all,
            :conditions => ["pageable_id = ? and pageable_type = ? and namespace = ?", self.id, self.type.name, namespace]
          )        
        end

        def find_page_by_namespace_and_name(namespace, name)
          Page.find(:first,
            :conditions => ["pageable_id = ? and pageable_type = ? and namespace = ? and name = ?", self.id, self.type.name, namespace, name]
          )        
        end
      end      
    end
    
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Pageable)
