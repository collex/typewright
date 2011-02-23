class CreateUserDocs < ActiveRecord::Migration
  def self.up
    create_table :user_docs do |t|
      t.integer :user_id
      t.integer :document_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_docs
  end
end
