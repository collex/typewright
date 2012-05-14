EXCEPTION_PREFIX = SITE_SPECIFIC['exception_notifier']['email_prefix']
EXCEPTION_RECIPIENTS = SITE_SPECIFIC['exception_notifier']['exception_recipients']
EXCEPTION_SENDER = SITE_SPECIFIC['exception_notifier']['sender_address']

if Rails.env.to_s != 'development'
	Typewright::Application.config.middleware.use ExceptionNotifier,
		:email_prefix => EXCEPTION_PREFIX,
		:sender_address => EXCEPTION_SENDER,
		:exception_recipients => EXCEPTION_RECIPIENTS.split(' ')
end
