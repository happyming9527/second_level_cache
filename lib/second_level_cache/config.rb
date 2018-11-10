# -*- encoding : utf-8 -*-
module SecondLevelCache
  module Config
    extend self

    attr_accessor :logger, :cache_key_prefix, :redis_connect

    def cache_store
      RedisCacheStore
    end

    def logger
      @logger ||= Rails.logger if defined?(Rails)
      @logger ||= Logger.new(STDOUT)
    end

    def cache_key_prefix
      @cache_key_prefix ||= 'slc'
    end
  end
end
