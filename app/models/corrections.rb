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
   # Get the typewright admin documents overview
   #
   def self.docs(page, page_size, sort, order, filter, status_filter)
      # paging setup
      page = page.to_i # guard against injection attacks by making sure only an int is passed.
      page_size = page_size.to_i
      page = (page-1)*page_size

      # set up sorting criteria
      sort_by = 'uri'
      sort_by = 'title' if sort == 'title'
      sort_by = 'percent' if sort == 'percent'
      sort_by = 'latest_update' if sort == 'modified'
      sort_order = "ASC"
      sort_order = "DESC" if order == "desc"

      # filter by title / uri / status
      filter_phrase = filter.blank? ? "" : "and (title LIKE '%#{filter}%' or uri LIKE '%#{filter}%')"
      if !status_filter.nil? && !status_filter.blank? && status_filter != 'all'
        filter_phrase = filter_phrase << " and d.status = '#{status_filter}'"
      end

      # query for paged results
      # Note the special case in the COUNT. When a user marks a document
      # as complete, but has not made any corections, the document will not
      # show up in the reports. TO solve this, an auto correction from a system
      # user is recorded for the document. The system user has id of 0. Don't count any
      # of these edits as progess.
      sql = "select d.id, uri, title, d.status as status, "
      sql = sql << " max(l.updated_at) as latest_update, "
      sql = sql << "(COUNT(DISTINCT case when user_id > 0 then `page` end) / total_pages)*100 as percent  "
      sql = sql << " from documents d inner join `lines` l on d.id = l.document_id "
      sql = sql << " where l.src = 'gale' #{filter_phrase} group by d.id ORDER BY #{sort_by} #{sort_order} LIMIT #{page} , #{page_size};"
      resp = Line.find_by_sql(sql)

      # get a count of ALL available results
      total = Line.find_by_sql("select COUNT(DISTINCT d.id) as cnt from documents d, `lines` l where d.id = l.document_id #{filter_phrase};").first.cnt

      resp = resp.map { |doc|
         # Get all users that corrected at least one line
         user_sql = "select u.id, u.orig_id, u.federation, u.username from users u inner join `lines` l on u.id = l.user_id where l.document_id = ? group by u.id"
         user_resp = User.find_by_sql([user_sql, doc.id])
         users = []
         user_resp.each { |user|
            # Get the number of corrections a user has made
            count = Line.find_by_sql("select COUNT(DISTINCT page,line) from `lines` where document_id = #{doc.id} and user_id = #{user.id};")
            count = count[0]['COUNT(DISTINCT page,line)']
            users.push({ id: user.orig_id, federation: user.federation, username: user.username, count: count })
         }

         # This is the return value: what we are mapping the response to
         { id: doc.id, uri: doc.uri, title: doc.title, most_recent_correction: doc.latest_update, percent: doc.percent, status: doc.status, users: users }
      }
      return { total: total, results: resp }
   end

   # Get the typewright admin users overview
   #
   def self.users(page, page_size, sort, order, filter)
      # paging setup
      page = page.to_i # guard against injection attacks by making sure only an int is passed.
      page_size = page_size.to_i
      page = (page-1)*page_size

      # filter by user name. The filter is a comma separated list of user ids matching the filter
      # text entered on the admin UI. Only pull data for these users
      filter_phrase = filter.blank? ? "" : "where u.username LIKE '%#{filter}%'"

      # set up sorting criteria
      sort_by = 'u.username'
      sort_by = 'edited' if sort == 'edited'
      sort_by = 'latest_update' if sort == 'modified'
      sort_order = "ASC"
      sort_order = "DESC" if order == "desc"

      sql = "select u.id, u.orig_id, u.username, u.federation, count(distinct l.document_id) as edited, max(l.updated_at) as latest_update"
      sql = sql << " from users u inner join `lines` l on u.id = user_id"
      sql = sql << " #{filter_phrase} group by u.id ORDER BY #{sort_by} #{sort_order} LIMIT #{page}, #{page_size}"
      resp = Line.find_by_sql(sql)
      total = Line.find_by_sql("select COUNT(DISTINCT user_id) from `lines`;")
      total = total[0]['COUNT(DISTINCT user_id)']
      resp = resp.map { |user|
         self.user_documents( user )
      }
      return { total: total, results: resp }
   end
   
   # get a summary of all corrections made by the spacified user
   #
   def self.user_corrections(federation, orig_id)
      user = User.where(:orig_id=>orig_id, :federation=>federation).first
      sql = "select d.uri, d.title, count(distinct page,line) as cnt, max(l.updated_at) as latest_update"
      sql = sql << " from documents d inner join `lines` l on l.document_id = d.id where l.user_id = ? group by d.id"
      res = Document.find_by_sql([sql, user.id])
      documents = []
      res.each do | d |
        documents.push({ id: d.uri, title: d.title, count: d.cnt, most_recent_correction: d.latest_update })   
      end

      # This is the return value: what we are mapping the response to
      return { id: user.orig_id, username: user.username, federation: user.federation, documents: documents }
   end

   private
   def self.user_documents( user )      
      sql = "select d.uri, d.title, count(distinct page,line) as cnt"
      sql = sql << " from documents d inner join `lines` l on l.document_id = d.id where l.user_id = ? group by d.id"
      res = Document.find_by_sql([sql, user.id])
      documents = []
      res.each do | d |
        documents.push({ id: d.uri, title: d.title, count: d.cnt })   
      end

      # This is the return value: what we are mapping the response to
      return { id: user.orig_id, username: user.username, federation: user.federation, most_recent_correction: user.latest_update, documents: documents }
   end
end
