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

ActiveRecord::Schema.define(:version => 20110221202638) do

  create_table "documents", :force => true do |t|
    t.string   "uri"
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lines", :force => true do |t|
    t.integer  "user_id"
    t.string   "document"
    t.integer  "page"
    t.decimal  "line",       :precision => 10, :scale => 4
    t.string   "status"
    t.text     "words"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_docs", :force => true do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "federation"
    t.integer  "orig_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
