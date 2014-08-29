class CurrentEditor < ActiveRecord::Base
	attr_accessible :document_id, :last_contact_time, :open_time, :page, :user_id, :token

	def self.editors(token, doc_id, page)
		# this returns all the other editors on a page.
		recs_page = CurrentEditor.where("document_id = ? AND page = ? AND token <> ?", doc_id, page, token)
		recs_doc = CurrentEditor.where("document_id = ? AND page <> ? AND token <> ?", doc_id, page, token)
		now = Time.now
		recs_page = recs_page.map { |rec|
			user = User.find(rec.user_id)
			{ user_id: rec.user_id, last_contact_time: rec.last_contact_time, idle_time: now - rec.last_contact_time, username: user.username, federation: user.federation, federation_user_id: user.orig_id, page: rec.page }
		}
		recs_doc = recs_doc.map { |rec|
			user = User.find(rec.user_id)
			{ user_id: rec.user_id, last_contact_time: rec.last_contact_time, idle_time: now - rec.last_contact_time, username: user.username, federation: user.federation, federation_user_id: user.orig_id, page: rec.page }
		}
		recs_page.delete_if {|rec| rec[:idle_time] > 5*60 }
		recs_doc.delete_if {|rec| rec[:idle_time] > 5*60 }
		return { page: recs_page, doc: recs_doc }
	end

	def self.unload(token)
		rec = CurrentEditor.where({token: token}).first
		rec.destroy if rec.present?
	end

  # Return the last time that this user asked for changes.
  # This routine updates that value, so calling it twice will give different answers.
	def self.since(token, doc_id, page, user_id, load_time)
		rec = CurrentEditor.where({ token: token }).first
		if rec.blank?
			rec = self.page_touched(token, doc_id, page, user_id)
			# Since we don't know what data we have, we need to send all the data.
			return load_time.present? ? load_time : Time.at(0)
		else
			ret = rec.last_contact_time
			self.page_touched(token, doc_id, page, user_id)
			return ret
		end
	end

	private
	def self.page_touched(token, doc_id, page, user_id)
		rec = CurrentEditor.where({ token: token }).first
		now = Time.now()
		if rec
			# In the normal flow, this record won't be created twice. It will, though, if the user is editing in two browsers,
			# or there was a network problem that prevented the last "close" event from being received.
			# It's ok, we'll just reuse that record.
			rec.update_attributes!({ last_contact_time: now })
		else
			rec = CurrentEditor.create!({ token: token, document_id: doc_id, page: page, user_id: user_id, open_time: now, last_contact_time: now })
		end
		return rec
	end

end
