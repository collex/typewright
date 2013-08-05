class User < ActiveRecord::Base
	attr_accessible :id, :federation, :orig_id, :username
	@@user_cache = {}

	def self.get(id)
		# This provides a cache for the users, since this is called for each line.
		hit = @@user_cache[id]
		return hit if hit.present?
		@@user_cache[id] = User.find_by_id(id)
		return @@user_cache[id]
	end
end
