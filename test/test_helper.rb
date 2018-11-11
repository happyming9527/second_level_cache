# -*- encoding : utf-8 -*-
require 'bundler/setup'
require 'minitest/autorun'
require 'active_support/test_case'
require 'active_record_test_case_helper'
require 'database_cleaner'
require 'active_record'
require 'redis'

ActiveRecord::Base.raise_in_transactional_callbacks = true if ActiveRecord::Base.respond_to?(:raise_in_transactional_callbacks=)
ActiveSupport.test_order = :sorted if ActiveSupport.respond_to?(:test_order=)

require 'second_level_cache'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

require 'model/user'
require 'model/book'
require 'model/image'
require 'model/topic'
require 'model/post'
require 'model/account'
require 'model/animal'

DatabaseCleaner[:active_record].strategy = :truncation

SecondLevelCache.configure do |config|
  config.redis_connect = Redis.new({host: 'localhost', port: 6379, db: 0})
end


SecondLevelCache.logger.level = Logger::ERROR
ActiveRecord::Base.logger = SecondLevelCache::Config.logger

class ActiveSupport::TestCase
  setup do
    SecondLevelCache.cache_store.clear
    DatabaseCleaner.start
  end

  teardown do
    SecondLevelCache.cache_store.clear
    DatabaseCleaner.clean
  end
end
