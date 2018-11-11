# -*- encoding : utf-8 -*-
require 'test_helper'

class BaseTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => 'csdn', :email => 'test@csdn.com'
  end

  def test_should_update_cache_when_update_has_one_attributes
    User.fetch_by_uniq_keys(name: 'csdn')
    key = User.get_second_level_cache_unique_key(name: 'csdn')
    assert SecondLevelCache::Config.redis_connect.exists(key)
    @user.update_attributes :name => 'change'
    assert_not SecondLevelCache::Config.redis_connect.exists(key)
    assert_equal @user.name, User.read_second_level_cache(@user.id).name
  end

  def test_should_delete_cache_when_destroy_has_one_object
    @user_1  = User.create :name => 'w3c', :email => 'test@w3c.com'
    @user_2  = User.create :name => 'ofo', :email => 'test@ofo.com'
    @image_1 = @user_1.create_image(url: 'http://www.baidu.com')
    @image   = @user.create_image(url: 'http://www.sina.com')

    begin
      Image.set_second_level_cache_unique_key([:imagable_type, :imagable_id], [:url])
      Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user.id)
      Image.fetch_by_uniq_keys(url: @image_1.url)
      Image.fetch_by_uniq_keys(imagable_type: @user_1.class.name, imagable_id: @user_1.id)
      Image.fetch_by_uniq_keys(url: @image.url)
      key = Image.get_second_level_cache_unique_key(imagable_type: @user.class.name, imagable_id: @user.id)
      key_1 = Image.get_second_level_cache_unique_key(imagable_type: @user_1.class.name, imagable_id: @user_1.id)
      url_key = Image.get_second_level_cache_unique_key(url: @image.url)
      url_key_1 = Image.get_second_level_cache_unique_key(url: @image_1.url)
      assert SecondLevelCache::Config.redis_connect.exists(key)
      assert SecondLevelCache::Config.redis_connect.exists(key_1)
      assert SecondLevelCache::Config.redis_connect.exists(url_key)
      assert SecondLevelCache::Config.redis_connect.exists(url_key_1)
      @image.destroy
      assert_not SecondLevelCache::Config.redis_connect.exists(key)
      assert_not SecondLevelCache::Config.redis_connect.exists(url_key)
      assert SecondLevelCache::Config.redis_connect.exists(key_1)
      assert SecondLevelCache::Config.redis_connect.exists(url_key_1)
    ensure
      Image.set_second_level_cache_unique_key
    end
  end

  def test_should_update_cache_when_update_has_one_as_attributes
    @user_1  = User.create :name => 'w3c', :email => 'test@w3c.com'
    @user_2  = User.create :name => 'ofo', :email => 'test@ofo.com'
    @image_1 = @user_1.create_image(url: 'http://www.sina.com')
    @image   = @user.create_image(url: 'http://www.baidu.com')

    assert_raise RuntimeError do
      Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user.id)
    end

    begin
      Image.set_second_level_cache_unique_key([:imagable_type, :imagable_id], ['url'])
      assert_queries 1 do
        Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user.id)
      end

      assert_no_queries do
        @cached_image = Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user.id)
      end
      assert_equal @user.class.name, @cached_image.imagable_type
      assert_equal @user.id, @cached_image.imagable_id

      Image.fetch_by_uniq_keys(url: @image.url)
      Image.fetch_by_uniq_keys(imagable_type: @user_1.class.name, imagable_id: @user_1.id)

      key = Image.get_second_level_cache_unique_key(imagable_type: @user.class.name, imagable_id: @user.id)
      key_1 = Image.get_second_level_cache_unique_key(imagable_type: @user_1.class.name, imagable_id: @user_1.id)
      url_key = Image.get_second_level_cache_unique_key(url: @image.url)
      assert SecondLevelCache::Config.redis_connect.exists(key)
      assert SecondLevelCache::Config.redis_connect.exists(key_1)
      assert SecondLevelCache::Config.redis_connect.exists(url_key)
      @image.update_attributes :imagable_id => @user_2.id
      assert_not SecondLevelCache::Config.redis_connect.exists(key)
      # 更新@image的字段，不会影响到 @image_1的相关缓存
      assert SecondLevelCache::Config.redis_connect.exists(key_1)
      # 更新@image的字段，不会影响到 @image_1其他唯一字段的相关缓存
      assert SecondLevelCache::Config.redis_connect.exists(url_key)


      assert_queries 1 do
        Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user_2.id)
      end

      assert_no_queries do
        @cached_image_1 = Image.fetch_by_uniq_keys(imagable_type: @user.class.name, imagable_id: @user_2.id)
      end

      assert_equal @user_2.class.name, @cached_image_1.imagable_type
      assert_equal @user_2.id, @cached_image_1.imagable_id
    ensure
      Image.set_second_level_cache_unique_key
    end
  end

  def test_should_update_cache_when_update_attribute
    @user.update_attribute :name, 'change'
    assert_equal @user.name, User.read_second_level_cache(@user.id).name
  end

  def test_should_expire_cache_when_destroy
    @user.destroy
    assert_nil User.read_second_level_cache(@user.id)
  end

  def test_should_expire_cache_when_update_counters
    assert_equal 0, @user.books_count
    @user.books.create
    assert_nil User.read_second_level_cache(@user.id)
    user = User.find(@user.id)
    assert_equal 1, user.books_count
  end

  def test_common_model_create_or_update_or_destroy_should_ok
    assert_nothing_raised do
      puts 'hello'
      big_post = @user.big_posts.create(content: 'hello,world')
      big_post_1 = @user.big_posts.create(content: 'test')
      comment = @user.big_comments.create(content: 'test', big_post: big_post)
      big_post = BigPost.find big_post.id
      big_comment = big_post.big_comment
      big_comment.update(big_post_id: big_post_1.id)
      big_comment.destroy
    end
  end
end
