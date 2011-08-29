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

  THUMBNAIL_WIDTH = 300
  SLICE_WIDTH = 800
  SLICE_HEIGHT = 50

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
    page_doc = Nokogiri::XML(File.open(get_page_xml_file(page), 'r')) if page_doc.nil?
    image_filename = page_doc.xpath('//pageInfo/imageLink')[0].content
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
    doc = Nokogiri::XML(File.open(get_primary_xml_file(),'r')) if doc.nil?
    num_pages = doc.xpath('//page').size
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


  def get_doc_stats(doc_id, src)
    changes = Line.num_pages_with_changes(doc_id, src)
    total = Line.find_all_by_document_id(doc_id, src)
    result = { :pages_with_changes => changes, :total_revisions => total.length }
    return result
  end

	def get_doc_info()
    f = File.open(get_primary_xml_file(),'r')
    doc = Nokogiri::XML(f)

		img_thumb = self.thumb()
		num_pages = self.get_num_pages(doc)

    title = doc.xpath('//fullTitle')[0].content
    title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

		info = { 'doc_id' => self.id, 'num_pages' => num_pages,
			'img_thumb' => img_thumb, 'title' => title, 'title_abbrev' => title_abbrev
		}
    return info.merge(@attributes)
  end

	def get_page_info(page, src = :gale )
    f = File.open(get_primary_xml_file(),'r')
    doc = Nokogiri::XML(f)

		page = (page == nil) ? 1 : page.to_i

    pf = File.open(get_page_xml_file(page, :gale), 'r')   # get gale page xml file for image info
    page_doc = Nokogiri::XML(pf)

    img_size = self.img_size(page, page_doc)
		img_thumb = self.img_thumb(page)
		img_full = self.img_full(page)
    num_pages = self.get_num_pages(doc)

    title = doc.xpath('//fullTitle')[0].content
    title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

    # now get the words, line and paragraphs from the page's xml file
    page_src = []
    num_lines = 0
    if src == :gale
      # read the page data from gale's xml
      page_doc.xpath('//pageContent/p').each { |ps|
        ps.xpath('wd').each { |wd|
          pos = wd.attribute('pos')
          arr = pos.to_s.split(',')
          page_src.push({ :l => arr[0].to_i, :t => arr[1].to_i, :r => arr[2].to_i, :b => arr[3].to_i, :word => wd.text, :line => num_lines })
        }
        num_lines += 1
      }
      page_src = XmlReader.gale_create_lines(page_src)

    elsif src = :gamera

      # we need to open the source specific XML
      pf = File.open(get_page_xml_file(page, src), 'r')
      page_doc = Nokogiri::XML(pf)

      # read the page data from gamera's xml
      page_doc.xpath('//page').each { |pg|
        pg.xpath('line').each { |ln|
          ln.xpath('wd').each { |wd|
            pos = wd.attributes['pos']
            arr = pos.to_s.split(',')
            page_src.push({ :l => arr[0].to_i, :t => arr[1].to_i, :r => arr[2].to_i, :b => arr[3].to_i, :word => wd.text, :line => num_lines })
          }
          num_lines += 1
        }
      }

    end

    lines = XmlReader.create_lines(page_src, src)
    
    lines.each_with_index {|line,i|
			line[:num] = i+1
		}
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
			:img_size => img_size
		}
    return result
  end

  def get_page_word_stats(page, src = :gale)
    page = (page == nil) ? 1 : page.to_i
    words = {}
    #TODO: replace this call
    src = XmlReader.read_gale(self.book_id(), page)
    src.each {|box|
      words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
    }
    word_stats = self.process_word_stats(words)

    result = { :word_stats => word_stats }
    return result
  end

  def get_doc_word_stats(src = :gale)
    words = {}
    num_pages = self.get_num_pages()
    pgs = num_pages < 100 ? num_pages : 100
    pgs.times { |pg|
      src = XmlReader.read_gale(self.book_id(), pg+1)
      src.each {|box|
        words[box[:word]] = words[box[:word]] == nil ? 1 : words[box[:word]] + 1
      }
    }
    doc_word_stats = self.process_word_stats(words)
    result = { :doc_word_stats => doc_word_stats }
    return result
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
      uri = 'lib://ecco/' + doc_id
    }
    if uri.nil?
      # ECCO id not found, check for ESTC ID
      doc.xpath('//ESTCID').each { |doc_id|
        uri = 'lib://estc/' + doc_id
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
        page_xml_path = get_page_xml_file(count)
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

  def self.do_command(cmd)
    Rails.logger.info(cmd)
    # this also redirects stderr into resp
    resp = `#{cmd} 2>&1`
    Rails.logger.error( resp ) if resp && resp.length > 0 && resp != "\n"
    return resp
  end

  def self.get_book_root_directory(book_id)
    directory = XmlReader.get_path('xml')
    book_path = File.join(directory, book_id)
    Dir::mkdir(book_path) unless FileTest.directory?(book_path)
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
    if src == :gamera
      book_xml_path = File.join(book_xml_path, 'gamera')
    end
    path = File.join(book_xml_path, name)
    return path
  end


end
