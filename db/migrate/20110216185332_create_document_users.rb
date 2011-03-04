class CreateDocumentUsers < ActiveRecord::Migration
  def self.up
    create_table :document_users do |t|
      t.integer :document_id
	  t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :document_users
  end
end
