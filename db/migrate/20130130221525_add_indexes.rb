class AddIndexes < ActiveRecord::Migration
  def change
	  add_index 'documents', 'uri'
	  add_index 'document_users', 'document_id'
	  add_index 'document_users', 'user_id'
	  add_index 'lines', 'document_id'
	  add_index 'lines', 'user_id'
	  add_index 'users', 'federation'
	  add_index 'users', 'orig_id'
	  add_index 'page_reports', 'document_id'
	  add_index 'page_reports', 'user_id'
  end
end
