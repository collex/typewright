namespace :xslt do
   desc "Add initial set of XSLT conversions to the DB"
   task :seed => :environment do
      ActiveRecord::Base.connection.execute("truncate table conversions")

      File.open("#{Rails.root}/lib/saxon/convert.txt", "rb").each_line do |line|
         # Format: from,to,xslt
         bits = line.split(",")
         file_name = bits[2].strip
         puts "Adding #{file_name}..."

         c = Conversion.new()
         c.from_format = bits[0]
         c.to_format = bits[1]
         xsl_file = "#{Rails.root}/lib/saxon/#{file_name}"
         file = File.open(xsl_file, "rb")
         c.xslt = file.read
         c.save!
      end
   end

   desc "Add/Update XSLT conversion, Params: from=[alto|gale], to=[alto|txt|tei], file=path_to_xsl"
   task :update => :environment do
      from = ENV['from']
      to = ENV['to']
      xsl_file = ENV['file']

      c = Conversion.where(from_format: from, to_format: to).first   #mjc: 9/24/15, fixing TW ingestion of ALTO
      if c.nil?
         puts "Adding new conversion from #{from} to #{to} with [#{xsl_file}]"
         c = Conversion.new()
         c.from_format = from
         c.to_format = to
         file = File.open(xsl_file, "rb")
         c.xslt = file.read
         c.save!
      else
         puts "Updating conversion from #{from} to #{to} with [#{xsl_file}]"
         file = File.open(xsl_file, "rb")
         c.xslt = file.read
         c.save!
      end

   end
end