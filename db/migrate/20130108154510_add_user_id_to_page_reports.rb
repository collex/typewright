class AddUserIdToPageReports < ActiveRecord::Migration
  def change
    add_column :page_reports, :user_id, :integer
    add_column :page_reports, :fullname, :string
    add_column :page_reports, :email, :string
  end
end
