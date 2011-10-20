class CreatePageReports < ActiveRecord::Migration
  def self.up
    create_table :page_reports do |t|
      t.text :reportText
      t.integer :document_id
      t.integer :page

      t.timestamps
    end
  end

  def self.down
    drop_table :page_reports
  end
end
