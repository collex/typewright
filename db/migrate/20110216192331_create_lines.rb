class CreateLines < ActiveRecord::Migration
  def self.up
    create_table :lines do |t|
      t.integer :user_id
      t.string :document
      t.integer :page
      t.decimal :line, :precision => 10, :scale => 4
      t.string :status
      t.text :words

      t.timestamps
    end
  end

  def self.down
    drop_table :lines
  end
end
