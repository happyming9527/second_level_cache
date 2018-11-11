# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:users, :force => true) do |t|
  t.text    :options
  t.text    :json_options
  t.string  :name, :unique => true
  t.string  :email
  t.integer :books_count, :default => 0
  t.integer :images_count, :default => 0
  t.timestamps null: false
end

ActiveRecord::Base.connection.create_table(:forked_user_links, :force => true) do |t|
  t.integer :forked_to_user_id
  t.integer :forked_from_user_id
  t.timestamps null: false
end

ActiveRecord::Base.connection.create_table(:namespaces, :force => true) do |t|
  t.integer :user_id
  t.string  :kind
  t.string  :name
  t.timestamps null: false
end

ActiveRecord::Base.connection.create_table(:big_posts, :force => true) do |t|
  t.integer :user_id
  t.text  :content
  t.timestamps null: false
end

ActiveRecord::Base.connection.create_table(:big_comments, :force => true) do |t|
  t.integer :user_id
  t.integer :big_post_id
  t.text  :content
  t.timestamps null: false
end

class User < ActiveRecord::Base
  CacheVersion = 3
  serialize :options, Array
  if ::ActiveRecord::VERSION::STRING >= '4.1.0'
    serialize :json_options, JSON
  end
  acts_as_cached(:version => CacheVersion, :expires_in => 3.day, unique_key_column_names: [[:name]])
  has_one  :account
  has_one  :forked_user_link, foreign_key: 'forked_to_user_id'
  has_one  :forked_from_user, through: :forked_user_link
  has_many :namespaces
  has_many :big_posts
  has_many :big_comments
  has_one  :namespace, -> { where(kind: nil) }
  has_many :books
  has_many :images, :as => :imagable
  has_one :image, :as => :imagable
end

class Namespace < ActiveRecord::Base
  acts_as_cached(:version => 1, :expires_in => 3.day)

  belongs_to :user
end

class ForkedUserLink < ActiveRecord::Base
  belongs_to :forked_from_user, class_name: User
  belongs_to :forked_to_user, class_name: User
end

class BigPost < ActiveRecord::Base
  belongs_to :user
  has_one :big_comment
end

class BigComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :big_post
end