# -*- encoding : utf-8 -*-
require 'test_helper'

class PersistenceTest < ActiveSupport::TestCase
  def setup
    @user = User.create :name => 'csdn', :email => 'test@csdn.com'
    @topic = Topic.create :title => "csdn"
  end

  def test_should_reload_object
    User.where(id: @user.id).update_all(email: 'different@csdn.com')
    assert_equal 'different@csdn.com', @user.reload.email
  end

  def test_should_reload_object_associations
    User.increment_counter :books_count, @user.id
    assert_equal 0, @user.books_count
    assert_equal 1, @user.reload.books_count
  end

  def test_should_return_true_if_touch_ok
    assert @topic.touch == true
  end
end
