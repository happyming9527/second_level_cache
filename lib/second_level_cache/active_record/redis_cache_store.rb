module RedisCacheStore
  module_function
  def read(key)
    value = SecondLevelCache::Config.redis_connect.get(key)
    if value.present?
      value = JSON.parse(value)
    end
    value
  end

  def write(key, value, options)
    value = value.to_json
    if options[:expires_in].present?
      expires_in = options[:expires_in].to_i
      SecondLevelCache::Config.redis_connect.setex(key, expires_in, value)
    else
      SecondLevelCache::Config.redis_connect.set(key, value)
    end
  end

  def write_multi(keys, values, options)
    if options[:expires_in].present?
      expires_in = options[:expires_in].to_i
      SecondLevelCache::Config.redis_connect.pipelined do
        keys.each_with_index do |key, index|
          value = values[index].to_json
          SecondLevelCache::Config.redis_connect.setex(key, expires_in, value)
        end
      end
    else
      SecondLevelCache::Config.redis_connect.pipelined do
        keys.each_with_index do |key, index|
          value = values[index].to_json
          SecondLevelCache::Config.redis_connect.set(key, value)
        end
      end
    end
  end

  def read_multi(*keys)
    hash = {}
    values = SecondLevelCache::Config.redis_connect.mget(*keys)
    keys.each_with_index do |key, index|
      value = values[index]
      next if value.blank?
      value = JSON.parse(values[index])
      hash[key] = value
    end
    hash
  end
end