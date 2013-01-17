
#desc "Deploy on production"
#task :deploy do
#	puts "Get latest files from repository..."
#	puts `git pull`
#	run_bundler()
#	puts "Check for needed migrations..."
#	puts `rake db:migrate`
#	puts "Precompiling assets..."
#	puts `rake assets:precompile`
#	puts "Restarting server"
#	puts `sudo /sbin/service httpd restart`
#end
#
#def run_bundler()
#	gemfile = "#{Rails.root}/Gemfile"
#	lock = "#{Rails.root}/Gemfile.lock"
#	if is_out_of_date(gemfile, lock)
#		puts "Updating gems..."
#		puts `bundle update`
#		`touch #{lock}`	# If there were no changes, the file isn't changed, so it will appear out of date every time this is run.
#	end
#end
#
#def get_file_list(folder, ext)
#	list = []
#	Dir.foreach(folder) { |f|
#		if f.index(ext) == f.length - ext.length
#			fname = f.slice(0, f.length - ext.length)
#			if fname.index('-min') != fname.length - 4
#				list.push(fname)
#			end
#		end
#	}
#	return list
#end
#
#def is_out_of_date(src, dst)
#	src_time = File.stat(src).mtime
#	begin
#		dst_time = File.stat(dst).mtime
#	rescue
#		# It's ok if the file doesn't exist; that means that we should definitely recreate it.
#		return true
#	end
#	return src_time > dst_time
#end

#def compress_folder(folder, ext)
#	list = get_file_list("#{Rails.root}/public/#{folder}", ext)
#	list.each {|fname|
#		src_path = "#{Rails.root}/public/#{folder}/#{fname}#{ext}"
#		dst_path = "#{Rails.root}/tmp/#{fname}-min#{ext}"
#		if is_out_of_date(src_path, dst_path)
#			puts "Compressing #{fname}#{ext}..."
#			system("java -jar #{Rails.root}/lib/tasks/yuicompressor-2.4.2.jar --line-break 7000 -o #{dst_path} #{src_path}")
#		end
#	}
#end
#
#def concatenate_folder(dest, folder, ext)
#	list = get_file_list("#{Rails.root}/public/#{folder}", ext)
#	files = ""
#	list.each {|fname|
#		files += " #{Rails.root}/tmp/#{fname}-min#{ext}"
#	}
#	puts "Creating #{dest}..."
#	system("cat #{files} > #{Rails.root}/public/#{folder}/#{dest}-min#{ext}")
#end
#
#def compress()
#	# The purpose of this is to roll all our css and js files into one minimized file so that load time on the server is as short as
#	# possible.
#	compress_folder('javascripts', '.js')
#	compress_folder('stylesheets', '.css')
#
#	concatenate_folder('all', 'javascripts', '.js')
#	concatenate_folder('all', 'stylesheets', '.css')
#end
#
#desc "Compress all css and js files"
#task :compress => :environment do
#	compress()
#end
