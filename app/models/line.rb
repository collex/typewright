class Line < ActiveRecord::Base
   attr_accessible :user_id, :document_id, :page, :line, :status, :words, :src, :box
   serialize :box, Hash

   def self.num_pages_with_changes( doc_id )
      pages = Line.find_all_by_document_id(doc_id, { :group => 'page' })
      return pages.length
   end

   def self.num_changes_for_page( doc_id, page_num )
      lines = Line.where("document_id = ? AND page = ?", doc_id, page_num )
      return lines.length
   end

   def self.merge_changes(lines, changes)
      lines.each do |line|
         line_num = "#{0.0 + line[:num]}"
         if changes[line_num]
            line[:authors] = [ :federation  => nil, :orig_id => 'Original' ]
            line[:dates] = [ '' ]
            line[:exact_times] = [ '' ]
            line[:actions] = [ '' ]
            changes[line_num].each do |lin|
               user = ::User.get(lin.user_id)
               author = { :federation  => user.federation, :orig_id => user.orig_id }
               words = self.db_to_words(lin[:words], line[:paragraph] )
               line[:authors].push(author)
               line[:dates].push(lin[:updated_at].getlocal.strftime("%b %e, %Y %I:%M%P"))
               line[:exact_times].push(lin[:updated_at].getlocal.strftime("%s"))
               line[:words].push(words)
               line[:actions].push(lin[:status])
               if lin[:status] == 'correct'
                  line[:text].push(line[:text].last)
               else
                  line[:text].push(self.words_to_text(words))
               end
               if lin[:box].present?
                  line[:l] = lin[:box]['l']
                  line[:t] = lin[:box]['t']
                  line[:r] = lin[:box]['r']
                  line[:b] = lin[:box]['b']
               end
            end
            changes.delete(line_num)
         end
      end
   end

   def self.since(document_id, page, since)
	   return Line.where("document_id = ? AND page = ? AND updated_at > ?", document_id, page, since)
   end

   private

   def self.db_to_words(db, paragraph)
      w = []
      words = db ? db.split("\n") : []
      words.each do |word|
         items = word.split("\t")
         w.push({ :l => items[0], :t => items[1], :r => items[2], :b => items[3], :line => items[4], :paragraph=>paragraph, :word => items[5] })
      end
      return w
   end

   private

   def self.words_to_text(words)
      str = ""
      words.each do |word|
         str += ' ' if str != ''
         str += word[:word]
      end
      return str
   end

end

