class AddTotalPagesToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :total_pages, :integer
  end
end
