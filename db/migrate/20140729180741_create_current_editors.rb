class CreateCurrentEditors < ActiveRecord::Migration
  def change
    create_table :current_editors do |t|
      t.integer :user_id
      t.integer :document_id
      t.integer :page
	  t.string :token

      t.datetime :open_time
      t.datetime :last_contact_time

      t.timestamps
	end
	add_index :current_editors, :user_id
	add_index :current_editors, :token
	add_index :current_editors, [:document_id, :page]
	add_index :current_editors, [:user_id, :document_id, :page]
  end
end
