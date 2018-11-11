# -*- encoding : utf-8 -*-
ActiveRecord::Base.connection.create_table(:posts, :force => true) do |t|
  t.text  :body
  t.string :slug
  t.integer :topic_id
end

class Post < ActiveRecord::Base
  acts_as_cached unique_key_column_names: [[:topic_id, :slug]]
  belongs_to :topic, :touch => true
end
