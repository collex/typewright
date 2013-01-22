namespace :backup do
	desc "Backup the SQL database to the git repository"
	task :sql do
		database_file = File.join("config", "database.yml")
		settings = YAML.load_file(database_file)
		database = settings['production']['database']
		username = settings['production']['username']
		password = settings['production']['password']

		`mysqldump -T ~/typewright_sql_backup -u #{username} -p#{password} #{database} --skip-dump-date`
		`cd ~/typewright_sql_backup && git add .`
		`cd ~/typewright_sql_backup && git commit -m"Backup #{Time.now.strftime('%b %-d, %Y')}"`
		`cd ~/typewright_sql_backup && git push`
	end

	# Just started writing this before finding rsync_in_sections.sh
	#desc "Backup all the full images"
	#task :images do
	#	database_file = File.join("config", "site.yml")
	#	settings = YAML.load_file(database_file)
	#	base_path = settings['paths']['xml']
	#	# do the rsync in pieces so that it is a managable size; we will go 5 levels deep to the 10-digit number
	#	paths1 = Dir["#{base_path}/*"]
	#	paths1.each { |path1|
	#		paths2 = Dir["#{path1}/*"]
	#		paths2.each { |path2|
	#			paths3 = Dir["#{path2}/*"]
	#			paths3.each { |path3|
	#				paths4 = Dir["#{path3}/*"]
	#				paths4.each { |path4|
	#					paths5 = Dir["#{path4}/*"]
	#					paths5.each { |path|
	#						puts path
	#						`rsync --verbose  --progress --stats --compress --recursive --times --perms --links -e "/usr/bin/ssh -i $KEY" $BASE_PATH/$level1/$level2/$level3/* $RUSER@$RHOST:$RPATH/$level1/$level2/$level3`
	#					}
	#				}
	#			}
	#		}
	#	}
	#end
	#
	#desc "Backup all of the processed slices (these could be recreated, slowly)"
	#task :slices do
	#
	#end
end
