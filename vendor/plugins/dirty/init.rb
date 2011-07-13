# init.rb

if Rails::VERSION::MAJOR == 1

  Object.class_eval do
    # Get object's meta (ghost, eigenclass, singleton) class
    def metaclass
      class << self
        self
      end
    end
  end

  require 'active_record/dirty.rb'

  ActiveRecord::Base.class_eval do
    include ActiveRecord::Dirty
  end

end

