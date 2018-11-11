# -*- encoding : utf-8 -*-
require 'active_support/all'
require 'second_level_cache/config'
require 'second_level_cache/record_marshal'

module SecondLevelCache
  def self.configure
    block_given? ? yield(Config) : Config
  end

  class << self
    delegate :logger, :cache_store, :cache_key_prefix, :to => Config
  end

  module Mixin
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :second_level_cache_options

      def acts_as_cached(options = {})
        @second_level_cache_enabled = true
        @second_level_cache_options = options
        @second_level_cache_options[:expires_in] ||= 1.week
        @second_level_cache_options[:version] ||= 0
        @second_level_cache_options[:unique_key_column_names] ||= []
        @second_level_cache_options[:unique_key_column_names] = @second_level_cache_options[:unique_key_column_names].map{|i| i.map(&:to_s)}
        relation.class.send :include, SecondLevelCache::ActiveRecord::FinderMethods
        include SecondLevelCache::ActiveRecord::Core if /^4\.2\./.match(::ActiveRecord.version.version)
      end

      def second_level_cache_enabled?
        !!@second_level_cache_enabled
      end

      def set_second_level_cache_unique_key(*column_arrays)
        @second_level_cache_options[:unique_key_column_names]= column_arrays.map{|i| i.map(&:to_s)}
      end

      def flatten_unique_key_column_names
        @second_level_cache_options[:unique_key_column_names].flatten
      end

      def unique_key_column_names
        @second_level_cache_options[:unique_key_column_names]
      end

      def without_second_level_cache
        old, @second_level_cache_enabled = @second_level_cache_enabled, false

        yield if block_given?
      ensure
        @second_level_cache_enabled = old
      end

      def cache_store
        Config.cache_store
      end

      def logger
        Config.logger
      end

      def cache_key_prefix
        Config.cache_key_prefix
      end

      def cache_version
        second_level_cache_options[:version]
      end

      def second_level_cache_key(id)
        "#{cache_key_prefix}/#{table_name.downcase}/#{id}/#{cache_version}"
      end

      def read_second_level_cache(id)
        RecordMarshal.load(SecondLevelCache.cache_store.read(second_level_cache_key(id))) if self.second_level_cache_enabled?
      end

      def expire_second_level_cache(id)
        SecondLevelCache.cache_store.delete(second_level_cache_key(id)) if self.second_level_cache_enabled?
      end
    end

    def second_level_cache_key
      self.class.second_level_cache_key(id)
    end

    def destroy_unique_key_cache
      self.class.unique_key_column_names.each do |i|
        hash = {}
        i.each do |key|
          hash[key] = self[key]
        end
        SecondLevelCache.cache_store.delete self.class.get_second_level_cache_unique_key(hash) if hash.present?
      end
    end

    def expire_unique_key_cache
      changed_keys = previous_changes.keys
      self.class.unique_key_column_names.each do |i|
        insect_keys = (i & changed_keys)
        next unless insect_keys.present?
        hash = {}
        i.each do |key|
          if insect_keys.include?(key)
            hash[key] = previous_changes[key][0]
          else
            hash[key] = self[key]
          end
        end
        SecondLevelCache.cache_store.delete self.class.get_second_level_cache_unique_key(hash) if hash.present?
      end
    end

    def expire_second_level_cache
      SecondLevelCache.cache_store.delete(second_level_cache_key) if self.class.second_level_cache_enabled?
    end

    def write_second_level_cache
      if self.class.second_level_cache_enabled?
        SecondLevelCache.cache_store.write(second_level_cache_key, RecordMarshal.dump(self), :expires_in => self.class.second_level_cache_options[:expires_in])
      end
    end

    alias update_second_level_cache write_second_level_cache
  end
end

require 'second_level_cache/active_record' if defined?(ActiveRecord)
