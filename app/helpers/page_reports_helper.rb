module PageReportsHelper
	def format_user(fullname, email)
		return raw "#{h fullname}<br/>#{h email}"
	end
end
