class AddStatusToDocument < ActiveRecord::Migration
  def change
    add_column :documents, :status, "ENUM('not_complete', 'user_complete', 'complete')", :default => :not_complete
  end
end
