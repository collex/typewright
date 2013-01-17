namespace :backup do
	desc "Backup the SQL database to the git repository"
	task :sql do
		database_file = File.join("config", "database.yml")
		settings = YAML.load_file(database_file)
		database = settings['production']['database']
		username = settings['production']['username']
		password = settings['production']['password']

		`mysqldump -T ~/typewright_sql_backup -u #{username} -p#{password} #{database} --skip-dump-date`
		`git add .`
		`git commit -m"Backup #{Time.now.strftime('%b %-d, %Y')}"`
		`git push`
	end
end
