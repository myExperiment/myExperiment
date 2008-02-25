require 'query_cache'

ActionController::Base.send(:include, ActionController::Caching::SqlCache) if defined?(ActiveRecord) 