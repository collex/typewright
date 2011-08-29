class AddSourceToLines < ActiveRecord::Migration
  def self.up
    add_column :lines, :src, :string
  end

  def self.down
    remove_column :lines, :src
  end
end
