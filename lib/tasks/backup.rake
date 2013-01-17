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
end
