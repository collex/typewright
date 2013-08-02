require 'csv'

namespace :db do
  def cmd_line(str)
    puts str
    puts `#{str}`
  end
  
  desc "Add/Update usernames from prod 18th_connect to typewright (param: dump=csv_users)"
  task :add_prod_usernames => :environment do
    csv_file_name = ENV['dump']
    if csv_file_name == nil || csv_file_name.blank?
      puts "Usage: call with dump=csv_file"
    else
      CSV.foreach(csv_file_name) do |row|
        user_id, user_name = row
        user = User.where(:orig_id=>user_id, :federation=>"18thConnect").first
        if !user.nil?
          user.username = user_name
          user.save!
        end
      end
    end  
  end
end