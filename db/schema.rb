# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130131165616) do

  create_table "document_users", :force => true do |t|
    t.integer  "document_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "document_users", ["document_id"], :name => "index_document_users_on_document_id"
  add_index "document_users", ["user_id"], :name => "index_document_users_on_user_id"

  create_table "documents", :force => true do |t|
    t.string   "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_pages"
  end

  add_index "documents", ["uri"], :name => "index_documents_on_uri"

  create_table "lines", :force => true do |t|
    t.integer  "user_id"
    t.string   "document_id"
    t.integer  "page"
    t.decimal  "line",        :precision => 10, :scale => 4
    t.string   "status"
    t.text     "words"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "src"
  end

  add_index "lines", ["document_id"], :name => "index_lines_on_document_id"
  add_index "lines", ["user_id"], :name => "index_lines_on_user_id"

  create_table "page_reports", :force => true do |t|
    t.text     "reportText"
    t.integer  "document_id"
    t.integer  "page"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "fullname"
    t.string   "email"
  end

  add_index "page_reports", ["document_id"], :name => "index_page_reports_on_document_id"
  add_index "page_reports", ["user_id"], :name => "index_page_reports_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "federation"
    t.integer  "orig_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["federation"], :name => "index_users_on_federation"
  add_index "users", ["orig_id"], :name => "index_users_on_orig_id"

end
