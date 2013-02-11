class AddBoxToLine < ActiveRecord::Migration
  def change
    add_column :lines, :box, :text
  end
end
