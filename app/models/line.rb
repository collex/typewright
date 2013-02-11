class Line < ActiveRecord::Base
	attr_accessible :user_id, :document_id, :page, :line, :status, :words, :src, :box
	serialize :box, Hash

	def self.num_pages_with_changes(doc_id, src)
		pages = Line.find_all_by_document_id_and_src(doc_id, src, { :group => 'page' })
		return pages.length
	end
#	def self.words_to_db(words)
#		return nil if words == nil
#		w = ""
#		words.each {|word|
#			w += "#{word[:l]}\t#{word[:t]}\t#{word[:r]}\t#{word[:b]}\t#{word[:line]}\t#{word[:word]}\n"
#		}
#		return w
#	end
#
	def self.db_to_words(db)
		w = []
		words = db ? db.split("\n") : []
		words.each {|word|
			items = word.split("\t")
			w.push({ :l => items[0], :t => items[1], :r => items[2], :b => items[3], :line => items[4], :word => items[5] })
		}
		return w
	end

	def self.words_to_text(words)
		str = ""
		words.each {|word|
			str += ' ' if str != ''
			str += word[:word]
		}
		return str
	end

#	def self.get_undoable_record(book, page, line, user)
#		corrections = Line.find_all_by_document_and_page_and_line(book, page, line)
#		return nil if corrections.length == 0
#		return nil if corrections.last[:user_id] != user
#		return corrections.last
#	end

	def self.merge_changes(lines, changes)
		lines.each {|line|
			line_num = "#{0.0 + line[:num]}"
			if changes[line_num]
				line[:authors] = [ :federation  => nil, :orig_id => 'Original' ]
				line[:dates] = [ '' ]
				line[:actions] = [ '' ]
				changes[line_num].each { |lin|
					user = ::User.get(lin.user_id)
          author = { :federation  => user.federation, :orig_id => user.orig_id }
					words = self.db_to_words(lin[:words])
					line[:authors].push(author)
					line[:dates].push(lin[:updated_at].getlocal.strftime("%b %e, %Y %I:%M%P"))
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
				}
				changes.delete(line_num)
			end
		}
	end
end

