class User < ActiveRecord::Base
	def self.get_user(federation, orig_id)
		user = User.find_by_federation_and_orig_id(federation, orig_id)
		return user
	end

	def self.get_or_create_user(federation, orig_id)
		user = self.get_user(federation, orig_id)
		if user == nil
			user = User.create({ :federation => federation, :orig_id => orig_id })
		end
		return user
	end
end
