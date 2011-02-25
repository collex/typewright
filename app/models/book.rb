# ------------------------------------------------------------------------
#     Copyright 2011 Applied Research in Patacriticism and the University of Virginia
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

class Book
	def self.get_all_books
		books = []
		Dir.foreach(XmlReader.base_folder()) { |f|
			if f.match(/\d{10}/)
				books.push(f)
			end
		}
		return books
	end

	def self.get_interesting_books
		return [
			{ :num => '0042000900' , :desc => 'Three column, hand written' },
			{ :num => '0077500200' , :desc => 'Two column' },
			{ :num => '0109300900' , :desc => 'Ornate initial drop cap' },
			{ :num => '0111901400' , :desc => 'Margin headers, one column' },
			{ :num => '0135203600' , :desc => 'Three columns' },
			{ :num => '0143001400' , :desc => 'First page two column and one column; some handwritten' },
			{ :num => '0158201300' , :desc => 'Footnotes are two column' },
			{ :num => '0227700700' , :desc => 'A few hebrew chars on first page' },
			{ :num => '0239200301' , :desc => 'Two columns; some skew at edge' },
			{ :num => '0247600500' , :desc => 'Some skew at edge' },
			{ :num => '0290802600' , :desc => 'Names are expressed "W--m"' },
			{ :num => '0308400200' , :desc => 'Verse numbers in different font, registered lower' },
			{ :num => '0322000100' , :desc => 'More illegible that usual; smudges and skewing' },
			{ :num => '0330900300' , :desc => 'Some pages scanned very light' },
			{ :num => '0340001700' , :desc => 'Drop cap is legible, many lines; catchword' },
			{ :num => '0353100200' , :desc => 'Rx symbol' },
			{ :num => '0365800102' , :desc => 'In Italian; pages skewed' },
			{ :num => '0387301300' , :desc => 'Lots of italic; some lines combined with }' },
			{ :num => '0392200102' , :desc => 'Two columns' },
			{ :num => '0398600300' , :desc => 'Line numbers on right' },
			{ :num => '0408200204' , :desc => 'Lots of fonts, some skewed pages, Latin, Greek (in Greek letters)' },
			{ :num => '0484000100' , :desc => 'All Latin' },
			{ :num => '0495500102' , :desc => 'Every other page is cut off at the left edge' },
			{ :num => '0537000600' , :desc => 'French' },
			{ :num => '0583400201' , :desc => 'Latin, lots of hyphenated words at end of line' },
			{ :num => '0587600101' , :desc => 'Fancy font, German, two columns, some cut off at left edge from scan.' },
			{ :num => '0616600300' , :desc => 'Two columns; mediocre quality, but readable' },
			{ :num => '0637500600' , :desc => 'Four columns; some columns have } going to fewer columns' },
			{ :num => '0676200500' , :desc => 'Small text; margin headers' },
			{ :num => '0822400100' , :desc => 'A paragraph was crossed out in pen: is that significant?' },
			{ :num => '0840500700' , :desc => 'Footnotes in odd places, not exactly two columns, but sort of. Some Latin and Greek.' },
			{ :num => '0841500302' , :desc => 'New quote mark on every continuation line.' },
			{ :num => '0874003200' , :desc => 'Two columns; small font; Latin on left, English on right' },
			{ :num => '0885500301' , :desc => 'Two columns' },
			{ :num => '0922300400' , :desc => 'Four columns, small' },
			{ :num => '1088700100' , :desc => 'Two columns sometimes; contains a few multi-column tables' },
			{ :num => '1095301400' , :desc => 'A little bit of handwriting.' },
			{ :num => '1145500600' , :desc => 'Two pages of the same thing, neither is a great scan' },
			{ :num => '1248102500' , :desc => 'Some old English font; margin headers' },
			{ :num => '1257000400' , :desc => 'Names are expressed "W--m"' },
			{ :num => '1276900100' , :desc => 'Old English font' },
			{ :num => '1292703600' , :desc => 'Two columns; not very legible; names expressed "W--m" but the name is written in' },
			{ :num => '1299705900' , :desc => 'Very smudgy' },
			{ :num => '1300001800' , :desc => 'Pg 7 diagonal; penultimate blank pg' },
			{ :num => '1405400600' , :desc => 'Lots of tables' },
			{ :num => '1474000100' , :desc => 'Pg 12 obscured text' },
			{ :num => '1487400200' , :desc => 'Vertical text; tables' },
			{ :num => '1496402100' , :desc => 'Lines close together and somewhat wavy' },
			{ :num => '1500500900' , :desc => 'Inventive spelling' },
			{ :num => '1519400101' , :desc => 'Badly skewed, to the point of cutting off image' },
			{ :num => '1563300700' , :desc => 'French and English on facing pages' },
			{ :num => '1668600800' , :desc => 'Wavy lines' },
			{ :num => '1775900400' , :desc => 'Same page: one and two column; some skewing; some smudging' }
		]
	end

	def self.get_num_pages(book)
		path = "#{XmlReader.base_folder()}/#{book}/images"
		count = 0
		Dir.foreach(path) { |f|
			if f.match(/\.png$/)
				count += 1
			end
		}
		return count
	end

	def self.process_word_stats(words)
		word_stats = [[], [], [], [], []]
		words.each { |k,v|
			if k == nil
				k = "nil (#{v})"
				v = 0
			elsif k.length == 1 && k != 'A' && k != 'a' && k != 'I'	# There are only a couple of acceptable one-char words
				k = "#{k} (#{v})"
				v = 0
			elsif k.match(/[^a-zA-Z][^a-zA-Z]/) != nil	# if it has two non-alphas in a row
				k = "#{k} (#{v})"
				v = 0
			elsif k.match(/^[^a-zA-Z"']/) != nil	# if starts with something other than alpha, quote or apos
				k = "#{k} (#{v})"
				v = 0
			elsif k.match(/[a-zA-Z][^-a-zA-Z'][a-zA-Z]/) != nil	# if the interior of the word contains punctuation besides the dash and apos
				k = "#{k} (#{v})"
				v = 0
			elsif k.match(/[^-a-zA-Z'".,';:?!']/) != nil	# if there exists anything other than alpha, and a few punctuation symbols.
				k = "#{k} (#{v})"
				v = 0
			end
			if v >= 4
				k = "#{k} (#{v})"
				v = 4
			end
			word_stats[v].push(k)
		}
		word_stats.each { |arr|
			arr.sort!
		}
		return word_stats
	end

	def self.setup_page(book, page)
		page = (page == nil) ? 1 : page.to_i

		num_pages = Book.get_num_pages(book)

		img_folder = "#{book}"
		img_name = "#{book}#{XmlReader.format_page(page)}0"
		img_thumb = "http://ocr.performantsoftware.com/data/#{img_folder}/images/#{img_name}.png"
		img_full = "http://ocr.performantsoftware.com/data/#{img_folder}/images_800/#{img_name}.png"

		src = XmlReader.read_gale(book, page)
		lines = XmlReader.create_lines(XmlReader.gale_create_lines(src))

		lines.each_with_index {|line,i|
			line[:num] = i+1
		}
		title = XmlReader.read_metadata(book)
		title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

		words = {}
		src.each {|box|
			words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
		}
		word_stats = Book.process_word_stats(words)

		words = {}
		pgs = num_pages < 100 ? num_pages : 100
		pgs.times { |pg|
			src = XmlReader.read_gale(book, pg+1)
			src.each {|box|
				words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
			}
		}
		doc_word_stats = Book.process_word_stats(words)

		recs = Line.find_all_by_document_and_page(book, page)
		changes = {}
		recs.each {|rec|
			key = "#{rec[:line]}"
			if changes[key]
				changes[key].push(rec)
			else
				changes[key] = [rec]
			end
		}
		Line.merge_changes(lines, changes)

		# Now, all the items in changes that were not used must be inserted lines. Insert them now.
		changes.each { |line_num, change|
			found = false
			idx = 0
			while idx < lines.length && !found
				if line_num.to_f < lines[idx][:num]
					lines.insert(idx, XmlReader.line_factory(0, 0, 0, 0, line_num.to_f, [[]], [''], line_num.to_f))
					found = true
				end
				idx += 1
			end
		}
		Line.merge_changes(lines, changes)

		return { :book => book, :page => page, :num_pages => num_pages, :img_full => img_full,
			:img_thumb => img_thumb, :lines => lines, :title => title, :title_abbrev => title_abbrev,
			:word_stats => word_stats, :doc_word_stats => doc_word_stats
		}
	end
end
