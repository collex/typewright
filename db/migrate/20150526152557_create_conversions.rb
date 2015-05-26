class CreateConversions < ActiveRecord::Migration
   def change
      create_table :conversions do |t|
         t.string :from_format
         t.string :to_format
         t.text :xslt
         t.timestamps
      end
   end
end
