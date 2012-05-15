class User < ActiveRecord::Base
	attr_accessible :id, :federation, :orig_id
	@@user_cache = {}

	def self.get(id)
		# This provides a cache for the users, since this is called for each line.
		hit = @@user_cache[id]
		return hit if hit.present?
		@@user_cache[id] = User.find_by_id(id)
		return @@user_cache[id]
	end

#	def self.get_user(federation, orig_id)
#		user = User.find_by_federation_and_orig_id(federation, orig_id)
#		return user
#	end
#
#	def self.get_or_create_user(federation, orig_id)
#		user = self.get_user(federation, orig_id)
#		if user == nil
#			user = User.create({ :federation => federation, :orig_id => orig_id })
#		end
#		return user
#	end
end
