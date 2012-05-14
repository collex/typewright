namespace :export do
	def get_path(which)
		config_file = File.join("config", "site.yml")
		if File.exists?(config_file)
			site_specific = YAML.load_file(config_file)
			return site_specific['paths'][which]
		end
	end

	desc "Zip typewright files on the server for download (id=0123456789-0123456789-...)"
	task :zip, :id do |t, args|
		ids = args[:id]
		if ids == nil
			puts "Usage: call with export:zip[0123456789-0123456789-...]"
		else
			image_path = get_path('xml')
			out_path = "~"
			ids = ids.split('-')
			ids.each {|id|
				if id.length != 10
					puts "Bad id: #{id}"
				else
					doc_path = "#{id[0]}/#{id[1]}/#{id[2]}/#{id[3]}/#{id[4]}/#{id}"
					path = File.join(image_path, doc_path)
					cmd = "nohup tar cvfz #{out_path}/#{id}.tar.gz #{path} &"
					puts cmd
					puts `#{cmd}`
				end
			}
		end
	end
end
