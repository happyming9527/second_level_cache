# -*- encoding : utf-8 -*-
require 'test_helper'

class HasOneAssociationTest < ActiveSupport::TestCase
  def setup
    @user    = User.create :name => 'hooopo', :email => 'hoooopo@gmail.com'
    @account = @user.create_account
  end

  def test_should_fetch_account_from_cache
    clean_user = @user.reload
    assert_queries 1 do
      account = clean_user.account
      assert_equal @account, account
    end

    begin
      Account.set_second_level_cache_unique_key([:user_id])
      clean_user = @user.reload
      assert_queries 1 do
        account = clean_user.account
        assert_equal @account, account
      end
      clean_user = @user.reload
      assert_no_queries do
        account = clean_user.account
        assert_equal @account, account
      end
    ensure
      Account.set_second_level_cache_unique_key
    end

    clean_user = @user.reload
    assert_queries 1 do
      account = clean_user.account
      assert_equal @account, account
    end
  end

  def test_should_fetch_has_one_as
    @image = @user.create_image

    # 没有设置cache_unique_key的时候，每次查询都不会查缓存
    clean_user = @user.reload
    assert_queries 1 do
      image = clean_user.image
      assert_equal @image, image
    end

    clean_user = @user.reload
    assert_queries 1 do
      image = clean_user.image
      assert_equal @image, image
    end

    begin
      Image.set_second_level_cache_unique_key([:imagable_type, :imagable_id])
      # SecondLevelCache.cache_store.clear
      clean_user = @user.reload
      assert_queries 1 do
        image = clean_user.image
        assert_equal @image, image
      end

      clean_user = @user.reload
      assert_no_queries do
        image = clean_user.image
        assert_equal @image, image
      end
    ensure
      Image.set_second_level_cache_unique_key
    end

    clean_user = @user.reload
    assert_queries 1 do
      image = clean_user.image
      assert_equal @image, image
    end
  end

  def test_should_fetch_has_one_through
    user       = User.create :name => 'hooopo', :email => 'hoooopo@gmail.com', forked_from_user: @user
    clean_user = user.reload
    assert_equal User, clean_user.forked_from_user.class
    assert_equal @user.id, user.forked_from_user.id
    # clean_user = user.reload
    # assert_no_queries do
    #   clean_user.forked_from_user
    # end
  end

  def test_has_one_with_conditions
    user             = User.create name: 'hooopo', email: 'hoooopo@gmail.com'
    group_namespace1 = Namespace.create(user_id: user.id, name: 'ruby-china', kind: 'group')
    user.create_namespace(name: 'hooopo')
    group_namespace2 = Namespace.create(user_id: user.id, name: 'rails', kind: 'group')
    assert_not_equal user.namespace, nil
    clear_user = User.find(user.id)
    assert_equal clear_user.namespace.name, 'hooopo'
  end
end
