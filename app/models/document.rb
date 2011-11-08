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

# Document is responsible for knowing the relationship between various bits of information
# and where there are stored. Delegates to XmlReader to actually read data from specific
# XML files

class Document < ActiveRecord::Base

  THUMBNAIL_WIDTH = 300
  SLICE_WIDTH = 800
  SLICE_HEIGHT = 50

  SUPPORTED_OCR_SOURCES = %w(gale gamera)

  def to_xml(options = {})
    puts @attributes
    super
  end
  
	def book_id()
		return self.uri.split('/').last
	end

	def img_folder()
		return File.join('uploaded',self.book_id())
	end

	def img_thumb(page)
		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
    img_cache_path = self.img_folder()
		url_path = File.join(img_cache_path, 'thumbnails')
    url = File.join(url_path,"#{page_name}_thumb.png")
    pub_path = File.join(Rails.root, 'public')
    thumb_file = File.join(pub_path, url)
    unless FileTest.exist?(thumb_file)
      # the thumbnail file doesn't exist, create the image files
      thumb_path = File.join(pub_path, url_path)
      page_path = File.join(pub_path, img_cache_path)
      Document.generate_slices(get_page_image_file(page), page_path, page_name, SLICE_WIDTH, SLICE_HEIGHT)
      Document.generate_thumbnail(get_page_image_file(page), page_path, page_name, THUMBNAIL_WIDTH)
    end
    return url
	end

  def self.generate_slices(master_image, dst_path, file_name, width, height)
    imagemagick = XmlReader.get_path('imagemagick')
    convert = "#{imagemagick}/convert"
    real_dst_path = File.join(dst_path, file_name)
    dst_file = File.join(real_dst_path, "#{file_name}.png")
    FileUtils.mkdir_p(real_dst_path)
    cmd = "#{convert} #{master_image} -scale #{width} -crop #{width}x#{height} -contrast -contrast -density 72 -colors 4 -strip -depth 2 -quality 90 #{dst_file}"
    Document.do_command(cmd)
  end

  def self.generate_thumbnail(master_image, dst_path, file_name, width)
    imagemagick = XmlReader.get_path('imagemagick')
    convert = "#{imagemagick}/convert"
    real_dst_path = File.join(dst_path, 'thumbnails')
    dst_file = File.join(real_dst_path, "#{file_name}_thumb.png")
    FileUtils.mkdir_p(real_dst_path)
    cmd = "#{convert} #{master_image} -scale #{width} -contrast -contrast -density 72 -colors 4 -strip -depth 2 -quality 90 #{dst_file}"
    Document.do_command(cmd)
  end

	def img_full(page)
		page_name = "#{book_id}#{XmlReader.format_page(page)}0"
		return "#{img_folder}/#{page_name}/#{page_name}-*.png"
	end

  def get_page_image_file(page, page_doc = nil)
    page_doc = XmlReader.open_xml_file(get_page_xml_file(page)) if page_doc.nil?
    image_filename = XmlReader.get_page_image_filename(page_doc)
    image_path = File.join(get_image_directory(), image_filename)
    return image_path
  end

	def img_size(page, page_doc = nil)
    image_path = get_page_image_file(page, page_doc)
    image_filename = image_path.split('/').last

    image_size = Rails.cache.fetch("imgsize.#{image_filename}") {
      # not cached, ask imagemagic for the size
      imagemagick = XmlReader.get_path('imagemagick')
      identify = "#{imagemagick}/identify"
      cmd = "#{identify} -format \"%w %h\" #{image_path}"
      Document.do_command(cmd)
    }
    width = image_size.split(' ')[0].to_i
    height = image_size.split(' ')[1].to_i

		return { :width => width, :height => height }
	end

	def thumb()
		return img_thumb(1)
	end

	def get_num_pages(doc = nil)
    doc = XmlReader.open_xml_file(get_primary_xml_file()) if doc.nil?
    num_pages = XmlReader.get_num_pages(doc)
    return num_pages
	end


##############################################

  def process_word_stats(words)
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


  def get_doc_stats(doc_id, include_word_stats, src)
    changes = Line.num_pages_with_changes(doc_id, src)
    total = Line.find_all_by_document_id(doc_id, src)
    if include_word_stats
      doc_word_stats = get_doc_word_stats(src)
    end
    result = { :pages_with_changes => changes, :total_revisions => total.length, :doc_word_stats => doc_word_stats }
    return result
  end

	def get_doc_info()
    doc = XmlReader.open_xml_file(get_primary_xml_file())

		img_thumb = self.thumb()
		num_pages = XmlReader.get_num_pages(doc)

    title = XmlReader.get_full_title(doc)
    title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

    ocr_sources = []
    SUPPORTED_OCR_SOURCES.each { |ocr_src|
      if File.exist?(get_page_xml_file(1, ocr_src))
        ocr_sources << ocr_src
      end
    }

		info = { 'doc_id' => self.id, 'num_pages' => num_pages,
			'img_thumb' => img_thumb, 'title' => title, 'title_abbrev' => title_abbrev,
      'ocr_sources' => ocr_sources
		}
    return info.merge(@attributes)
  end

	def get_page_info(page, include_word_stats, src = :gale )
    doc = XmlReader.open_xml_file(get_primary_xml_file())

		page = (page == nil) ? 1 : page.to_i

    page_doc = XmlReader.open_xml_file(get_page_xml_file(page, :gale))

    img_size = self.img_size(page, page_doc)
		img_thumb = self.img_thumb(page)
		img_full = self.img_full(page)
    num_pages = self.get_num_pages(doc)

    title = XmlReader.get_full_title(doc)
    title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

    # figure out which OCR sources are available for this page
    ocr_sources = []
    SUPPORTED_OCR_SOURCES.each { |ocr_src|
      if File.exist?(get_page_xml_file(page, ocr_src))
        ocr_sources << ocr_src
      end
    }

    # open the source specific page xml document
    unless src == :gale
      page_doc = XmlReader.open_xml_file(get_page_xml_file(page, src))
    end

    # now get the words, line and paragraphs from the page's xml file
    page_src = XmlReader.read_all_lines_from_page(page_doc, src)

    lines = XmlReader.create_lines(page_src, src)
    
    lines.each_with_index {|line,i|
			line[:num] = i+1
		}

    # get the word statistics
    if include_word_stats
      words = {}
      page_src.each {|box|
        words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
      }
      page_word_stats = self.process_word_stats(words)
      doc_word_stats = get_doc_word_stats(src)
    else
      page_word_stats = nil
      doc_word_stats = nil
    end

    # all the original source data is in place

		recs = Line.find_all_by_document_id_and_page_and_src(self.id, page, src)
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
					lines.insert(idx, XmlReader.line_factory(0, 0, 0, 0, line_num.to_f, [[]], [''], line_num.to_f, src))
					found = true
				end
				idx += 1
			end
		}
		Line.merge_changes(lines, changes)

		result = { :doc_id => self.id, :page => page, :num_pages => num_pages, :img_full => img_full,
			:img_thumb => img_thumb, :lines => lines, :title => title, :title_abbrev => title_abbrev,
			:img_size => img_size, :ocr_sources => ocr_sources,
      :word_stats => page_word_stats, :doc_word_stats => doc_word_stats
		}
    return result
  end

  def get_doc_word_stats(src = :gale)
    doc_word_stats = Rails.cache.fetch("doc-stats-#{src}-#{self.book_id()}") {
      words = {}
      num_pages = self.get_num_pages()
      pgs = num_pages < 100 ? num_pages : 100
      pgs.times { |page|
        page_doc = XmlReader.open_xml_file(get_page_xml_file(page+1, src))
        page_src = XmlReader.read_all_lines_from_page(page_doc, src)
        page_src.each {|box|
          words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
        }
      }
      doc_word_stats = self.process_word_stats(words)
      doc_word_stats
    }
    return doc_word_stats
  end

  def get_root_directory()
    return Document.get_book_root_directory(self.book_id())
  end

  def get_xml_directory()
    return Document.get_book_xml_directory(self.book_id())
  end

  def get_image_directory()
    return Document.get_book_image_directory(self.book_id())
  end

  def get_primary_xml_file()
    return Document.get_book_primary_xml_file(self.book_id())
  end

  def get_page_xml_file(page, src = :gale)
    return Document.get_book_page_xml_file(self.book_id(), page, src)
  end

  def save_page_image(upload)
    img_path = get_image_directory()

     # create the file path
    path = File.join(img_path, upload.original_filename)
    # write the file
    File.open(path, "wb") { |f| f.write(upload.read) }
  end

  def import_primary_xml(xml_file)
    doc = Nokogiri::XML(xml_file)

    # first, figure out the URI
    uri = nil
    # look for ECCO documentID
    doc.xpath('//documentID').each { |doc_id|
      uri = 'lib://ECCO/' + doc_id
    }
    if uri.nil?
      # ECCO id not found, check for ESTC ID
      doc.xpath('//ESTCID').each { |doc_id|
        uri = 'lib://ESTC/' + doc_id
      }
    end
    if uri.nil?
      # worst-case, make the URI from the xml filename, with assumption
      # that it is an ECCO id
      name = xml_file.original_filename
      uri = 'lib://ECCO/' + name.split('.')[0]
    end
    self.uri = uri

    # extract all of the page nodes and store them
    # in separate files for efficiency
    count = 0
    doc.xpath('//page').each { |page_node|
      count += 1
      page_doc = Nokogiri::XML('<page/>')
      page_doc.root = page_node
      page_id = page_doc.xpath('//pageInfo/pageID')[0].content
      generated_page_id = XmlReader.format_page(count) + '0'
      if page_id.nil?
        # Error if <pageID> is missing
        raise "#{uri} -- ERROR: for page #{count} expected pageInfo > pageID [#{generated_page_id}] but pageInfo > pageID missing from XML"
      else
        if page_id != generated_page_id
          # Error if <pageID> is not what we would have generated for that page number
          raise "#{uri} -- ERROR: for page #{count} expected pageInfo > pageID [#{generated_page_id}] but got pageInfo > pageID [#{page_id}]"
        end
        page_xml_path = get_page_xml_file(count, :gale)
        File.open(page_xml_path, "w") { |f| f.write(page_doc.to_xml) }
        # replace the existing page nodes with a reference node pointing to the page xml file
        page_xml_filename = page_xml_path.split('/').last
        page_node['fileRef'] = page_xml_filename
        page_node.content = ''
      end
    }

    # save the book xml with page refs rather than full page nodes
    book_xml_path = get_primary_xml_file()
    File.open(book_xml_path, "w") { |f| f.write(doc.to_xml) }
  end

  def import_page(page_num, image_file)

  end

  def import_page_ocr(page_num, xml_file, src = nil)
    xml_doc = XmlReader.open_xml_file(xml_file)
    src = XmlReader.detect_ocr_source(xml_doc)
    page_xml_path = get_page_xml_file(page_num, src)
    File.open(page_xml_path, "w") { |f| f.write(xml_doc.to_xml) }
  end

  def get_corrected_text()
    doc = XmlReader.open_xml_file(get_primary_xml_file())
    title = XmlReader.get_full_title(doc)
    num_pages = XmlReader.get_num_pages(doc)
    output = title + "\n\n"
    num_pages.times { | page |
      page_text = self.get_corrected_page_text(page + 1)
      output += "Page #{page + 1}\n\n"
      output += page_text unless page_text.nil?
      output += "(empty page)" if page_text.nil? || page_text.empty?
      output += "\n\n"
    }
    return output
  end

  def get_corrected_gale_xml()
    doc = XmlReader.open_xml_file(get_primary_xml_file())
    page_num = 0
    doc.xpath('//page').each { |page_node|
      page_num += 1
      page_xml = get_corrected_page_gale_xml(page_num)
      page_node.replace(page_xml)
    }
    return doc.to_xml
  end

  def get_corrected_tei_a()

  end

  def get_corrected_page_text(page_num, src = :gale)
    page_info = get_page_info(page_num, false, src)
    page_text = ''
    page_info[:lines].each { | line |
      the_text = line[:text]
      page_text += the_text[the_text.length - 1] + "\n"
    }
    return page_text
  end

  def get_corrected_page_gale_xml(page_num, src = :gale)
    page_xml_path = get_page_xml_file(page_num, src)
    page_doc = XmlReader.open_xml_file(page_xml_path)
    page_node = page_doc.xpath('//page')
    page_content_node = page_node.xpath('//pageContent').first()
    page_paragraph_nodes = page_node.xpath('//pageContent/p')
    page_paragraph_nodes.each { |paragraph_node|
      paragraph_node.unlink
    }
    page_content_node.content = nil

    page_info = get_page_info(page_num, false, src)
    page_text = ''
    page_info[:lines].each { | line |
      p_node = Nokogiri::XML::Node.new('p', page_doc)
      page_content_node << p_node
      line[:words].last.each { | word |
        wd_node = Nokogiri::XML::Node.new('wd', page_doc)
        wd_node.content = word[:word]
        pos_str = "#{word[:l]},#{word[:t]},#{word[:r]},#{word[:b]}"
        wd_node['pos'] = pos_str
        p_node << wd_node
      }
    }

    return page_node
  end

  # return a string representing the page in TEI-A
  def get_corrected_page_tei_a(page_num, src = :gale)

  end

  def self.do_command(cmd)
    Rails.logger.info(cmd)
    # this also redirects stderr into resp
    resp = `#{cmd} 2>&1`
    Rails.logger.error( resp ) if resp && resp.length > 0 && resp != "\n"
    return resp
  end

  def self.get_book_root_directory(book_id)
    directory = XmlReader.get_path('xml')
    (0..4).each { | i |
      directory = File.join(directory, book_id[i])
    }
    book_path = File.join(directory, book_id)
    FileUtils.mkdir_p(book_path) unless FileTest.directory?(book_path)
    return book_path
  end

  def self.get_book_xml_directory(book_id)
    path = get_book_root_directory(book_id) + '/xml'
    Dir::mkdir(path) unless FileTest.directory?(path)
    return path
  end

  def self.get_book_image_directory(book_id)
    path = get_book_root_directory(book_id) + '/img'
    Dir::mkdir(path) unless FileTest.directory?(path)
    return path
  end

  def self.get_book_primary_xml_file(book_id)
    name = "#{book_id}.xml"
    path = File.join(get_book_xml_directory(book_id), name)
    return path
  end

  def self.get_book_page_xml_file(book_id, page, src = :gale)
    page_id = XmlReader.format_page(page) + '0'
    name = "#{book_id}_#{page_id}.xml"
    book_xml_path = get_book_xml_directory(book_id)
    book_xml_path = File.join(book_xml_path, "#{src}")
    Dir::mkdir(book_xml_path) unless FileTest.directory?(book_xml_path)
    path = File.join(book_xml_path, name)
    return path
  end


end
