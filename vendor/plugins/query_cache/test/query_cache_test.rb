RAILS_ENV = 'test'

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../vendor/rails/activerecord/test")
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../../../../vendor/rails/activerecord/test/connections/native_mysql")

require "#{File.dirname(__FILE__)}/../../../../config/boot.rb"
require "#{File.dirname(__FILE__)}/../../../../config/environment.rb"

require 'active_record'
require 'active_record/fixtures'
require 'test/unit'
require "#{File.dirname(__FILE__)}/abstract_unit.rb"
require 'rubygems'
require 'mocha'

Test::Unit::TestCase.fixture_path = "#{File.dirname(__FILE__)}/../../../../vendor/rails/activerecord/test/fixtures/"


require 'fixtures/topic'
require 'fixtures/reply'
require 'fixtures/task'
require 'fixtures/course'
require 'fixtures/developer'

class QueryCacheTest < Test::Unit::TestCase
  
  fixtures :tasks, :topics
  
  def test_find_queries
    assert_queries(2) {  Task.find(1); Task.find(1) }
  end

  def test_find_queries_with_cache
    Task.cache do
      assert_queries(1) {  Task.find(1); Task.find(1) }
    end
  end
  
  def test_query_cache_returned
    assert_not_equal ActiveRecord::QueryCache, Task.connection.class
    Task.cache do
      assert_equal ActiveRecord::QueryCache, Task.connection.class
    end    
  end

  def test_query_cache_dups_results_correctly
    Task.cache do
      now  = Time.now.utc
      task = Task.find 1
      assert_not_equal now, task.starting
      task.starting = now
      task.reload
      assert_not_equal now, task.starting
    end
  end

  def test_cache_is_scoped_on_actual_class_only
    Task.cache do
      Topic.columns # don't count this query
      assert_queries(2) {  Topic.find(1); Topic.find(1); }
    end
  end
  
  def test_cache_is_scoped_on_all_descending_classes
    ActiveRecord::Base.cache do
      assert_queries(1) {  Task.find(1); Task.find(1) }
    end
  end
  
  def test_cache_does_not_blow_up_other_connections
    assert_not_equal Course.connection.object_id, Task.connection.object_id, 
        "Connections should be different, Course connects to a different database"
    
    ActiveRecord::Base.cache do
      assert_not_equal Course.connection.object_id, Task.connection.object_id, 
          "Connections should be different, Course connects to a different database"
    end
  end
  
  def test_type_cast
    assert Task.count.is_a?(Integer)
    Task.cache do
      assert Task.count.is_a?(Integer)
    end
  end
  
end



class QueryCacheExpiryTest < Test::Unit::TestCase
  fixtures :tasks

  def test_find
    ActiveRecord::QueryCache.any_instance.expects(:clear_query_cache).times(0)
    
    Task.cache do 
      Task.find(1)
    end
  end

  def test_save
    ActiveRecord::QueryCache.any_instance.expects(:clear_query_cache).times(1)
    
    Task.cache do 
      Task.find(1).save
    end
  end

  def test_destroy
    ActiveRecord::QueryCache.any_instance.expects(:clear_query_cache).at_least_once
    
    Task.cache do 
      Task.find(1).destroy
    end
  end

  def test_create
    ActiveRecord::QueryCache.any_instance.expects(:clear_query_cache).times(1)
    
    Task.cache do 
      Task.create!
    end
  end

  def test_new_save
    ActiveRecord::QueryCache.any_instance.expects(:clear_query_cache).times(1)
    
    Task.cache do 
      Task.new.save
    end
  end
end
