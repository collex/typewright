class Document < ActiveRecord::Base
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

	def img_full(page)
		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
		return "#{img_folder}/#{page_name}/#{page_name}_*.png"
	end

	def img_size(page)
		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
		size_file = "#{Rails.root}/public/#{img_folder}/sizes.csv"
		f = File.open(size_file, "r")
		lines = f.readlines
		lines.each do|line|
			arr = line.split('.')
			if arr[0] == page_name
				arr = arr[1].split(',')
				return { :width => arr[1].to_i, :height => arr[1].to_i }
			end
		end
		return { :width => 0, :height => 0 }
	end

	def thumb()
		return img_thumb(1)
	end

#	def title_abbrev()
#		t = self.title
#		return t if t.length < 32
#		return t.slice(0..30)+'...'
#	end

	def get_num_pages()
		size_file = "#{Rails.root}/public/#{img_folder}/sizes.csv"
		f = File.open(size_file, "r")
		lines = f.readlines
		return lines.length
	end
end
