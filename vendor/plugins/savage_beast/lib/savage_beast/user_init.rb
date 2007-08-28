module SavageBeast
  module UserInit
    def self.included(base)
      base.class_eval do

        has_many :moderatorships, :dependent => :destroy
        has_many :forums, :through => :moderatorships, :order => 'forums.name'

        has_many :posts
        has_many :topics
        has_many :monitorships
        has_many :monitored_topics, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :order => 'topics.replied_at desc', :source => :topic

        def moderator_of?(forum)
          moderatorships.count(:all, :conditions => ['forum_id = ?', (forum.is_a?(Forum) ? forum.id : forum)]) == 1
        end

        def to_xml(options = {})
          options[:except] ||= []
          super
        end
  
        def password_required?
          true
        end
            
      end
      base.extend(ClassMethods)
    end

    module ClassMethods
      def currently_online
        User.find(:all, :conditions => ["last_seen_at > ?", Time.now.utc-5.minutes])
      end
    
      def search(query, options = {})
        with_scope :find => { :conditions => build_search_conditions(query) } do
          find :all, options
        end
      end

      #implmement to build search coondtitions
      def build_search_conditions(query)
        # query && ['LOWER(display_name) LIKE :q OR LOWER(login) LIKE :q', {:q => "%#{query}%"}]
        query
      end
    
    end
    
    #implement in your user model 
    def display_name
      "implement display_name in your user model"
    end
    
    #implement in your user model 
    def email
      "implement email in your user model"
    end
    
    #implement in your user model 
    def admin?
      false
    end

    #implement in your user model 
    def logged_in?
      false
    end   
  end
end