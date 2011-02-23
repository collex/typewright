
desc "Deploy on production"
task :deploy do
	puts "Get latest files from repository..."
	puts `svn up`
	puts "Check for needed migrations..."
	puts `rake db:migrate`
	#puts "Compress CSS and JS..."
	#puts `rake jslint:compress_css_js`
	puts `sudo /sbin/service httpd restart`
end
