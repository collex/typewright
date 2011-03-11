class Line < ActiveRecord::Base
	def self.num_pages_with_changes(doc_id)
		pages = Line.find_all_by_document_id(doc_id, { :group => 'page' })
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
#	def self.db_to_words(db)
#		w = []
#		words = db ? db.split("\n") : []
#		words.each {|word|
#			items = word.split("\t")
#			w.push({ :l => items[0], :t => items[1], :r => items[2], :b => items[3], :line => items[4], :word => items[5] })
#		}
#		return w
#	end
#
#	def self.words_to_text(words)
#		str = ""
#		words.each {|word|
#			str += ' ' if str != ''
#			str += word[:word]
#		}
#		return str
#	end
#
#	def self.get_undoable_record(book, page, line, user)
#		corrections = Line.find_all_by_document_and_page_and_line(book, page, line)
#		return nil if corrections.length == 0
#		return nil if corrections.last[:user_id] != user
#		return corrections.last
#	end
#
#	def self.merge_changes(lines, changes)
#		lines.each {|line|
#			line_num = "#{0.0 + line[:num]}"
#			if changes[line_num]
#				line[:authors] = [ 'Original' ]
#				line[:dates] = [ '' ]
#				line[:actions] = [ '' ]
#				changes[line_num].each { |lin|
#					user_id = lin[:user_id]
#					# TODO-PER: stub until we hook this into the User table
#					users = [ '', 'Adam', 'Beth', 'Charles', 'Diana' ]
#					author = users[user_id]
#
#					words = Line.db_to_words(lin[:words])
#					line[:authors].push(author)
#					line[:dates].push(lin[:updated_at].getlocal.strftime("%b %e, %Y %I:%M%P"))
#					line[:words].push(words)
#					line[:actions].push(lin[:status])
#					if lin[:status] == 'correct'
#						line[:text].push(line[:text].last)
#					else
#						line[:text].push(Line.words_to_text(words))
#					end
#				}
#				changes.delete(line_num)
#			end
#		}
#	end
end

