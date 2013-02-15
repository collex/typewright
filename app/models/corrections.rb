# ------------------------------------------------------------------------
#     Copyright 2013 Applied Research in Patacriticism and the University of Virginia
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
# ----------------------------------------------------------------------------

class Corrections
	def self.docs(page, page_size, sort, filter)
		page = page.to_i # guard against injection attacks by making sure only an int is passed.
		page_size = page_size.to_i
		page = (page-1)*page_size
		# get all documents that have a correction
		sort_by = 'uri'
		sort_by = 'title' if sort == 'title'
		#sort_by = 'most_recent' if sort == 'recent'
		#sort_by = 'percent_completed' if sort == 'percent'

		filter_phrase = filter.blank? ? "" : "and (title LIKE '%#{filter}%' or uri LIKE '%#{filter}%')"
		#resp = Line.find_by_sql("select DISTINCT document_id from `lines` #{filter_phrase} ORDER BY document_id ASC LIMIT #{page} , #{page_size};")
		#select DISTINCT d.id,uri,title from documents d, `lines` l where d.id = l.document_id and (title LIKE '%30%' or uri LIKE '%30%') ORDER BY title ASC limit 3,20
		resp = Line.find_by_sql("select DISTINCT d.id,uri,title,total_pages from documents d, `lines` l where d.id = l.document_id #{filter_phrase} ORDER BY #{sort_by} ASC LIMIT #{page} , #{page_size};")
		total = Line.find_by_sql("select COUNT(DISTINCT d.id,uri,title,total_pages) from documents d, `lines` l where d.id = l.document_id #{filter_phrase};")

		total = total[0]['COUNT(DISTINCT d.id,uri,title,total_pages)']
		resp = resp.map { |doc|
			doc_id = doc.id
			#URI	Title	Correctors (Lines Corrected)	Most Recent Correction	Percent Corrected
			#doc = Document.find_by_id(doc_id)
			# Get all users that corrected at least one line
			user_ids = Line.find_by_sql("select DISTINCT user_id from `lines` where document_id = #{doc_id};")
			users = []
			user_ids.each { |id|
				id = id.user_id
				u = User.find_by_id(id)
				# Get the number of corrections a user has made
				count = Line.find_by_sql("select COUNT(DISTINCT page,line) from `lines` where document_id = #{doc_id} and user_id = #{id};")
				count = count[0]['COUNT(DISTINCT page,line)']
				users.push({ federation: u.federation, id: u.orig_id, count: count })
			}
			most_recent_correction = Line.find_by_sql("select updated_at from `lines`where document_id = #{doc_id} ORDER BY updated_at DESC LIMIT 1;")
			most_recent_correction = most_recent_correction[0].updated_at
			pages_with_changes = Line.num_pages_with_changes(doc_id, :gale)

			# This is the return value: what we are mapping the response to
			{ uri: doc.uri, most_recent_correction: most_recent_correction, pages_with_changes: pages_with_changes,
				total_pages: doc.total_pages, users: users }
		}
		return { total: total, results: resp }
	end

	def self.users(page, page_size, sort_by, filter)
		page = page.to_i # guard against injection attacks by making sure only an int is passed.
		page_size = page_size.to_i
		page = (page-1)*page_size
		# get all documents that have a correction
		sort_by = 'uri'
		sort_by = 'most_recent' if sort_by == 'recent'
		sort_by = 'percent_completed' if sort_by == 'percent'
		filter_phrase = filter.blank? ? "" : "WHERE ???"
		resp = Line.find_by_sql("select DISTINCT user_id from `lines` #{filter_phrase} ORDER BY user_id ASC LIMIT #{page} , #{page_size};")
		total = Line.find_by_sql("select COUNT(DISTINCT user_id) from `lines`;")
		total = total[0]['COUNT(DISTINCT user_id)']
		resp = resp.map { |user_id|
			user_id = user_id.user_id
			self.user(user_id)
		}
		return { total: total, results: resp }
	end

	def self.user(user_id)
		user = User.find_by_id(user_id)
		# Get all documents that the user corrected at least one line
		document_ids = Line.find_by_sql("select DISTINCT document_id from `lines` where user_id = #{user_id};")
		documents = []
		document_ids.each { |id|
			id = id.document_id
			d = Document.find_by_id(id)
			# Get the number of corrections a user has made
			count = Line.find_by_sql("select COUNT(*) from `lines` where document_id = #{id} and user_id = #{user_id};")
			count = count[0]['COUNT(*)']
			most_recent_correction = Line.find_by_sql("select updated_at from `lines`where document_id = #{id} and user_id = #{user_id} ORDER BY updated_at DESC LIMIT 1;")
			most_recent_correction = most_recent_correction[0].updated_at
			documents.push({ id: d.uri, count: count, most_recent_correction: most_recent_correction })
		}
		most_recent_correction = Line.find_by_sql("select updated_at from `lines`where user_id = #{user_id} ORDER BY updated_at DESC LIMIT 1;")
		most_recent_correction = most_recent_correction[0].updated_at
		#			pages_with_changes = Line.num_pages_with_changes(doc_id, :gale)
		#			total_pages = doc.get_num_pages()

		# This is the return value: what we are mapping the response to
		return { federation: user.federation, id: user.orig_id, most_recent_correction: most_recent_correction, documents: documents }
	end
end
