# config/initializers/setup_mail.rb

ActionMailer::Base.smtp_settings = {
	:address => SITE_SPECIFIC['smtp_settings']['address'],
	:port => SITE_SPECIFIC['smtp_settings']['port'],
	:domain => SITE_SPECIFIC['smtp_settings']['domain'],
	:user_name => SITE_SPECIFIC['smtp_settings']['user_name'],
	:password => SITE_SPECIFIC['smtp_settings']['password'],
	:authentication => SITE_SPECIFIC['smtp_settings']['authentication'],
	:enable_starttls_auto => SITE_SPECIFIC['smtp_settings']['enable_starttls_auto']
}

ActionMailer::Base.default_url_options[:host] = SITE_SPECIFIC['smtp_settings']['return_path']
#Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?
