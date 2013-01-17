# To deploy:
# cap production

require 'rvm/capistrano'
set :rvm_ruby_string, 'ruby-1.9.3-p194'
#set :rvm_type, :system

require 'bundler/capistrano'
#require "delayed/recipes"
#require "whenever/capistrano"

set :repository, "git://github.com/collex/typewright.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache

set :user, "typewright"
set :use_sudo, false

set :normalize_asset_timestamps, false

set :rails_env, "production"

#set :whenever_command, "bundle exec whenever"

desc "Run tasks in production environment."
task :production do
	set :application, "typewright.sl.performantsoftware.com"
	set :deploy_to, "/home/typewright/www/typewright"

	role :web, "#{application}"                          # Your HTTP server, Apache/etc
	role :app, "#{application}"                          # This may be the same as your `Web` server
	role :db,  "#{application}", :primary => true 		# This is where Rails migrations will run
end

namespace :passenger do
	desc "Restart Application"
	task :restart do
		run "touch #{current_path}/tmp/restart.txt"
	end
end

namespace :config do
	desc "Config Symlinks"
	task :symlinks do
		run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
		run "ln -nfs #{shared_path}/config/site.yml #{release_path}/config/site.yml"
		run "ln -fs /raid/converted_images #{release_path}/uploaded"
	end
end

#namespace :copy_files do
#	desc "Copy all xsd files to the public path"
#	task :xsd do
#		puts "Updating xsd files..."
#		source_dir = "#{release_path}/features/xsd"
#		dest_dir = "#{release_path}/public/xsd"
#		run "cp -R #{source_dir} #{dest_dir}"
#	end
#end

after :staging, 'deploy'
after :deploy, "deploy:migrate"

#after "deploy:stop",    "delayed_job:stop"
#after "deploy:start",   "delayed_job:start"
#after "deploy:restart", "delayed_job:restart"
after "deploy:finalize_update", "config:symlinks"
#after "deploy:finalize_update", "copy_files:xsd"
after :deploy, "passenger:restart"
