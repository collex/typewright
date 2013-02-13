class AddTitleToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :title, :text
  end
end
