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

class Document < ActiveRecord::Base


  def to_xml(options = {})
    puts @attributes
    super
  end
  
	def book_id()
		return self.uri.split('/').last
	end

	def img_folder()
		return "/uploaded/#{book_id}"
	end

	def img_thumb(page)
		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
		return "#{img_folder}/thumbnails/#{page_name}_thumb.png"
	end
#
#	def img_full(page)
#		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
#		return "#{img_folder}/#{page_name}/#{page_name}_*.png"
#	end
#
#	def img_size(page)
#		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
#		size_file = "#{Rails.root}/public/#{img_folder}/sizes.csv"
#		f = File.open(size_file, "r")
#		lines = f.readlines
#		lines.each do|line|
#			arr = line.split('.')
#			if arr[0] == page_name
#				arr = arr[1].split(',')
#				return { :width => arr[1].to_i, :height => arr[2].to_i }
#			end
#		end
#		return { :width => 0, :height => 0 }
#	end
#
	def thumb()
		return img_thumb(1)
	end

	def get_num_pages()
		size_file = "#{Rails.root}/public/#{img_folder}/sizes.csv"
		if File.exists?(size_file)
			f = File.open(size_file, "r")
			lines = f.readlines
			return lines.length
		else
			return 0
		end
	end
#
#	##############################################
#
#	def process_word_stats(words)
#		word_stats = [[], [], [], [], []]
#		words.each { |k,v|
#			if k == nil
#				k = "nil (#{v})"
#				v = 0
#			elsif k.length == 1 && k != 'A' && k != 'a' && k != 'I'	# There are only a couple of acceptable one-char words
#				k = "#{k} (#{v})"
#				v = 0
#			elsif k.match(/[^a-zA-Z][^a-zA-Z]/) != nil	# if it has two non-alphas in a row
#				k = "#{k} (#{v})"
#				v = 0
#			elsif k.match(/^[^a-zA-Z"']/) != nil	# if starts with something other than alpha, quote or apos
#				k = "#{k} (#{v})"
#				v = 0
#			elsif k.match(/[a-zA-Z][^-a-zA-Z'][a-zA-Z]/) != nil	# if the interior of the word contains punctuation besides the dash and apos
#				k = "#{k} (#{v})"
#				v = 0
#			elsif k.match(/[^-a-zA-Z'".,';:?!']/) != nil	# if there exists anything other than alpha, and a few punctuation symbols.
#				k = "#{k} (#{v})"
#				v = 0
#			end
#			if v >= 4
#				k = "#{k} (#{v})"
#				v = 4
#			end
#			word_stats[v].push(k)
#		}
#		word_stats.each { |arr|
#			arr.sort!
#		}
#		return word_stats
#	end
#
	def setup_doc()
		img_thumb = self.thumb()
		num_pages = self.get_num_pages()

		title = XmlReader.read_metadata(self.book_id())
		title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

		info = { 'doc_id' => self.id, 'num_pages' => num_pages,
			'img_thumb' => img_thumb, 'title' => title, 'title_abbrev' => title_abbrev
		}
    return info.merge(@attributes)
  end
#
#	def setup_page(page)
#		page = (page == nil) ? 1 : page.to_i
#
#		img_thumb = self.img_thumb(page)
#		img_full = self.img_full(page)
#		img_size = self.img_size(page)
#		num_pages = self.get_num_pages()
#
#		src = XmlReader.read_gale(self.book_id(), page)
#		lines = XmlReader.create_lines(XmlReader.gale_create_lines(src))
#
#		lines.each_with_index {|line,i|
#			line[:num] = i+1
#		}
#		title = XmlReader.read_metadata(self.book_id())
#		title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title
#
#		words = {}
#		src.each {|box|
#			words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
#		}
#		word_stats = self.process_word_stats(words)
#
#		words = {}
#		pgs = num_pages < 100 ? num_pages : 100
#		pgs.times { |pg|
#			src = XmlReader.read_gale(self.book_id(), pg+1)
#			src.each {|box|
#				words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
#			}
#		}
#		doc_word_stats = self.process_word_stats(words)
#
#		recs = Line.find_all_by_document_id_and_page(self.id, page)
#		changes = {}
#		recs.each {|rec|
#			key = "#{rec[:line]}"
#			if changes[key]
#				changes[key].push(rec)
#			else
#				changes[key] = [rec]
#			end
#		}
#		Line.merge_changes(lines, changes)
#
#		# Now, all the items in changes that were not used must be inserted lines. Insert them now.
#		changes.each { |line_num, change|
#			found = false
#			idx = 0
#			while idx < lines.length && !found
#				if line_num.to_f < lines[idx][:num]
#					lines.insert(idx, XmlReader.line_factory(0, 0, 0, 0, line_num.to_f, [[]], [''], line_num.to_f))
#					found = true
#				end
#				idx += 1
#			end
#		}
#		Line.merge_changes(lines, changes)
#
#		return { :doc_id => self.id, :page => page, :num_pages => num_pages, :img_full => img_full,
#			:img_thumb => img_thumb, :lines => lines, :title => title, :title_abbrev => title_abbrev,
#			:word_stats => word_stats, :doc_word_stats => doc_word_stats, :img_size => img_size
#		}
#	end
end
