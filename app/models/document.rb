# ------------------------------------------------------------------------
#     Copyright 2011 Applied Research in Patacriticism and the University of
# Virginia
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

# Document is responsible for knowing the relationship between various bits of
# information
# and where there are stored. Delegates to XmlReader to actually read data from
# specific
# XML files
class Document < ActiveRecord::Base
   validates_inclusion_of :status, :in => ['not_complete', 'user_complete', 'complete', :not_complete, :user_complete, :complete]
   attr_accessible :uri, :total_pages

   THUMBNAIL_WIDTH = 300
   SLICE_WIDTH = 800
   SLICE_HEIGHT = 50

   SUPPORTED_OCR_SOURCES = %w(alto gale)

   def to_xml(options = {})
      puts @attributes
      super
   end

   def document_id()
      return self.uri.split('/').last
   end

   def document_uri_path()
      return self.uri.split(/(lib:)|\//i).reject{ |e| e.empty? }
   end

   def uri_root()
      return "" if is_ecco? || is_eebo?
      return self.uri.split(/lib:|\//i).reject{ |e| e.empty? }.first
   end

   def is_ecco?
      return !self.uri.match(/\/\/ecco\//i).nil?
   end

   def is_eebo?
     return !self.uri.match(/\/\/eebo\//i).nil?
   end

   # we have decided to split the eebo documents up differently...
   def root_directory_path

     directory = ""
     eebo = is_eebo?
     id = document_id
     (0..4).each { |i|
       if eebo
         directory = File.join(directory, "#{id[i * 2]}#{id[(i * 2)+1]}")
       else
         directory = File.join(directory, id[i])
       end
     }
     return directory
   end

   def img_folder()
      directory = 'uploaded'
      directory = File.join(directory, self.uri_root())
      directory = File.join(directory, root_directory_path)
      img_cache_path = File.join(directory, document_id)
      return img_cache_path
   end

   def img_thumb(page, src)
      page_name = "#{document_id}#{XmlReader.format_page(page)}0"
      img_cache_path = self.img_folder()
      url_path = File.join(img_cache_path, 'thumbnails')
      url = File.join(url_path,"#{page_name}_thumb.png")
      pub_path = File.join(Rails.root, 'public')
      thumb_file = File.join(pub_path, url)
      unless FileTest.exist?(thumb_file)
         # the thumbnail file doesn't exist, create the image files
         # thumb_path = File.join(pub_path, url_path)
         page_path = File.join(pub_path, img_cache_path)
         Document.generate_slices(self.get_page_image_file(page, nil, src, self.uri_root()), page_path, page_name, SLICE_WIDTH, SLICE_HEIGHT)
         Document.generate_thumbnail(self.get_page_image_file(page, nil, src, self.uri_root()), page_path, page_name, THUMBNAIL_WIDTH)
      end
      return url
   end

   # get the prefered OCR source
   def get_ocr_source( page )
      SUPPORTED_OCR_SOURCES.each do |ocr_src|
         xml_file = get_page_xml_file(page, ocr_src, self.uri_root())
         logger.info
         if File.exist?(xml_file)
            logger.info "file #{xml_file}  SRC #{ocr_src}"
            return ocr_src.to_sym
         end
      end
      nil
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

   def img_full(page, src)
      page_name = "#{document_id}#{XmlReader.format_page(page)}0"
      return "#{self.img_folder}/#{page_name}/#{page_name}-*.png"
   end

   def get_page_image_file(page, page_doc, src, uri_root = "")
      page_doc = XmlReader.open_xml_file(get_page_xml_file(page, src, uri_root)) if page_doc.nil?

      # get the image file name and strip of the directory (which appears in ALTO files)
      image_filename = XmlReader.get_page_image_filename(page_doc,src)
      image_filename = File.basename( image_filename ) unless image_filename.nil?

      image_path = File.join(self.get_image_directory(), image_filename)
      return image_path
   end

   def img_size(page, page_doc, src)
      image_path = self.get_page_image_file(page, page_doc, src)
      image_filename = image_path.split('/').last

      image_size = Rails.cache.fetch("imgsize.#{image_filename}") {
      # not cached, ask imagemagic for the size
         imagemagick = XmlReader.get_path('imagemagick')
         identify = "#{imagemagick}/identify"
         cmd = "#{identify} -format \"%w %h\" #{image_path}"
         Document.do_command(cmd)
      }
      image_size = image_size.split("\n")
      image_size = image_size.last
      width = image_size.split(' ')[0].to_i
      height = image_size.split(' ')[1].to_i

      return { :width => width, :height => height }
   end

   def thumb(src)
      return self.img_thumb( 1, src )
   end

   def get_num_pages(doc = nil)
      return self.total_pages if self.total_pages.present?
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
         elsif k.length == 1 && k != 'A' && k != 'a' && k != 'I'# There are only
            # a couple of acceptable one-char words
            k = "#{k} (#{v})"
         v = 0
         elsif k.match(/[^a-zA-Z][^a-zA-Z]/) != nil# if it has two non-alphas in
            # a row
            k = "#{k} (#{v})"
         v = 0
         elsif k.match(/^[^a-zA-Z"']/) != nil# if starts with something other
            # than alpha, quote or apos
            k = "#{k} (#{v})"
         v = 0
         elsif k.match(/[a-zA-Z][^-a-zA-Z'][a-zA-Z]/) != nil# if the interior of
            # the word contains punctuation besides the dash and apos
            k = "#{k} (#{v})"
         v = 0
         elsif k.match(/[^-a-zA-Z'".,';:?!']/) != nil# if there exists anything
            # other than alpha, and a few punctuation symbols.
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

   def get_doc_stats( doc_id, include_word_stats )

      changes = Line.num_pages_with_changes( doc_id )
      total = Line.find_all_by_document_id( doc_id )
      total_lines_revised = {}
      last_revision = {}
      total.each { |rec|
         total_lines_revised["#{rec['page']},#{rec['line']}"] = true
         id = "user_#{rec.user_id}"
         if last_revision[id].blank?
            last_revision[id] = { 'page' => rec['page'], 'line' => rec['line'] }
         else
            is_newer = last_revision[id]['page'].to_i < rec['page'].to_i || (last_revision[id]['page'].to_i == rec['page'].to_i && last_revision[id]['line'].to_i < rec['line'].to_i)
            last_revision[id] = { 'page' => rec['page'], 'line' => rec['line'] } if is_newer
         end
      }

      if include_word_stats
         doc_word_stats = get_doc_word_stats( :gale )   # TODO
      end

      result = { :pages_with_changes => changes, :total_revisions => total.length, :doc_word_stats => doc_word_stats,
         :lines_with_changes => total_lines_revised.length, :last_revision => last_revision }
      return result
   end

   def get_gale_title()
      doc = XmlReader.open_xml_file(get_primary_xml_file())
      title = XmlReader.get_full_title(doc)
      return title
   end

   def get_doc_info( )
      doc = XmlReader.open_xml_file(get_primary_xml_file())

      src = :gale              # most documents have gale OCR (some have replaced alto pages but still mainly gale)
      src = :alto if is_eebo?  # all EEBO documents have only alto OCR

      img_thumb = self.thumb( src )
      num_pages = XmlReader.get_num_pages( doc )

      title = XmlReader.get_full_title(doc)
      title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

      info = { 'doc_id' => self.id, 'num_pages' => num_pages,
         'img_thumb' => img_thumb, 'title' => title, 'title_abbrev' => title_abbrev
      }
      return info.merge(@attributes)
   end

   def get_page_info(page, include_word_stats, include_image_info = true )

      # figure out the best available OCR source for this page
      src = self.get_ocr_source( page )

      # if we have an alto doc but we have gail corrections, use the gale source
      src = :gale if src == :alto && corrections_exist?( self.id, page, :gale ) == true

      doc = XmlReader.open_xml_file(get_primary_xml_file())

      logger.info("Get #{src} page #{page} for #{self.uri_root()}")
      page = (page.nil?) ? 1 : page.to_i
      page_doc = XmlReader.open_xml_file(get_page_xml_file(page, src, self.uri_root()))

      if include_image_info
         img_size = self.img_size(page, page_doc, src )
         img_thumb = self.img_thumb(page, src )
         img_full = self.img_full(page, src )
      end

      num_pages = self.get_num_pages(doc)

      title = XmlReader.get_full_title(doc)
      title_abbrev = title.length > 32 ? title.slice(0..30)+'...' : title

      # open the source specific page xml document
      if src != :gale
         page_doc = XmlReader.open_xml_file(get_page_xml_file(page, src, self.uri_root()))
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
         doc_word_stats = get_doc_word_stats( src )
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

      # Now, all the items in changes that were not used must be inserted lines.
      # Insert them now.
      changes.each { |line_num, change|
         found = false
         idx = 0
         last_para = -1
         while idx < lines.length && !found
            last_para = lines[idx][:paragraph]
            if line_num.to_f < lines[idx][:num]
               inserted_line = XmlReader.line_factory(0, 0, 0, 0, line_num.to_f, last_para, [[]], [''], line_num.to_f, src)
               lines.insert(idx, inserted_line)
               found = true
            end
            idx += 1
         end
         if !found
            # the item wasn't less than any of the current lines, so it
            # must be at the end
            inserted_line = XmlReader.line_factory(0, 0, 0, 0, line_num.to_f, last_para, [[]], [''], line_num.to_f, src)
            lines.insert(idx, inserted_line)
         end
      }
      Line.merge_changes(lines, changes)

      if include_image_info
         result = { :doc_id => self.id, :src=> src.to_s, :page => page, :num_pages => num_pages, :img_full => img_full,
            :img_thumb => img_thumb, :lines => lines, :title => title, :title_abbrev => title_abbrev,
            :img_size => img_size,
            :word_stats => page_word_stats, :doc_word_stats => doc_word_stats
         }
      else
         result = { :doc_id => self.id, :src=> src.to_s, :page => page, :num_pages => num_pages, :lines => lines, :title => title,
            :title_abbrev => title_abbrev, :word_stats => page_word_stats, :doc_word_stats => doc_word_stats
         }
      end
      return result
   end

   def get_doc_word_stats( src )
      doc_word_stats = Rails.cache.fetch("doc-stats-#{src}-#{self.document_id()}") {
         words = {}
         num_pages = self.get_num_pages()
         pgs = num_pages < 100 ? num_pages : 100
         pgs.times { |page|
            src = self.get_ocr_source( page + 1 )
            page_doc = XmlReader.open_xml_file(get_page_xml_file(page+1, src, self.uri_root()))
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
      return self.get_document_root_directory(self.document_id(), self.uri_root())
   end

   def get_xml_directory()
      return get_document_xml_directory(self.document_id(), self.uri_root())
   end

   def get_gale_xml_directory()
      return File.join(self.get_xml_directory(), 'gale')
   end

   def get_alto_xml_directory()
     return File.join(self.get_xml_directory(), 'alto')
   end

   def get_image_directory()
      return get_document_image_directory(self.document_id(), self.uri_root())
   end

   def get_primary_xml_file()
      return self.get_document_primary_xml_file(self.document_id(), self.uri_root())
   end

   def get_page_xml_file(page, src, uri_root = "")
      return self.get_document_page_xml_file(self.document_id(), page, src, uri_root)
   end

   def save_page_image(upload)
      img_path = self.get_image_directory()

      # create the file path
      path = File.join(img_path, upload.original_filename)
      path = path.gsub(".tif", ".TIF")
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

      # if ECCO id not found, check for ESTC ID
      if uri.nil?
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

      if self.uri.nil?
         self.uri = uri  # left over from ECCO-only days
      end

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
               # Error if <pageID> is not what we would have generated for that
               # page number
               raise "#{uri} -- ERROR: for page #{count} expected pageInfo > pageID [#{generated_page_id}] but got pageInfo > pageID [#{page_id}]"
            end
            page_xml_path = get_page_xml_file(count, :gale, self.uri_root())
            File.open(page_xml_path, "w") { |f| f.write(page_doc.to_xml) }
            # replace the existing page nodes with a reference node pointing to
            # the page xml file
            page_xml_filename = page_xml_path.split('/').last
            page_node['fileRef'] = page_xml_filename
            page_node.content = ''
         end
      }

      # save the document xml with page refs rather than full page nodes
      document_xml_path = get_primary_xml_file()
      File.open(document_xml_path, "w") { |f| f.write(doc.to_xml) }

      return count
   end

   def generate_primary_xml( title, num_pages )

     @pages = []
     (1..num_pages).each { | num |
        @pages << File.basename( self.get_document_page_xml_file( self.document_id, num ) )
     }

     doc = Nokogiri::XML::Builder.new do |xml|
        xml.doc.create_internal_subset( 'book', nil, 'book.dtd' )
        xml.book {
           xml.bookInfo {
              xml.documentId "#{document_id}"
           }
           xml.citation {
             xml.titleGroup {
                xml.fullTitle "#{title}"
             }
           }
           xml.text_ {
             @pages.each { |pg|
                xml.page( :fileRef => pg )
             }
           }
        }
     end
     xml_file = get_primary_xml_file()
     File.open( xml_file, "w" ) { |f| f.write( doc.to_xml ) }

     self.title = title
     self.total_pages = num_pages

   end

   def import_page(page_num, image_file)
     # do nothing...
   end

   def import_page_ocr(page_num, xml_file, uri_root = "")
      xml_doc = XmlReader.open_xml_file(xml_file)
      src = XmlReader.detect_ocr_source(xml_doc)
      page_xml_path = get_page_xml_file(page_num, src, uri_root)
      logger.info "SOURCE #{src}, PATH #{page_xml_path}"
      File.open(page_xml_path, "w") { |f| f.write(xml_doc.to_xml) }
   end

   # get the corrected document in text format (nothing to do with the source of the OCR)
   def get_corrected_text()
      doc = XmlReader.open_xml_file(get_primary_xml_file())
      title = XmlReader.get_full_title(doc)
      num_pages = XmlReader.get_num_pages(doc)
      output = title + "\n\n"
      num_pages.times { | page |
         src = self.get_ocr_source( page + 1 )
         page_text = self.get_corrected_page_text(page + 1, src)
         output += "Page #{page + 1}\n\n"
         output += page_text unless page_text.nil?
         output += "(empty page)" if page_text.nil? || page_text.empty?
         output += "\n\n"
      }
      return output
   end

   # get the corrected document in gale format (nothing to do with the source of the OCR)
   def get_corrected_gale_xml()
      primary_file = get_primary_xml_file()
      doc = XmlReader.open_xml_file( primary_file )
      page_num = 0
      doc.xpath('//page').each { |page_node|
         page_num += 1
         page_xml = get_corrected_page_gale_xml(page_num)
         page_node.replace(page_xml)
      }
      return doc.to_xml
   end

   # get the corrected document in alto format (nothing to do with the source of the OCR)
   def get_corrected_alto_xml( )
     primary_file = get_primary_xml_file()
     doc = XmlReader.open_xml_file( primary_file )
     page_num = 0
     doc.xpath('//page').each { |page_node|
       page_num += 1
       page_xml = get_corrected_page_alto_xml(page_num)
       page_node.replace(page_xml)
     }
     return doc.to_xml
   end

   def get_original_gale_text()
      doc = XmlReader.open_xml_file(get_primary_xml_file())

      title = XmlReader.get_full_title(doc)
      output = title + "\n\n"

      gale_dir = self.get_gale_xml_directory()

      doc.xpath('//page').each { |page_node|
         page_file = File.join(gale_dir, page_node['fileRef'])
         page_doc = XmlReader.open_xml_file(page_file)
         page_doc.xpath('//p').each { |p_node|
            output += p_node.content
         }
         output += "\n\n"
      }
      return output
   end

   # get the original gale pages
   def get_original_gale_xml()
     doc = XmlReader.open_xml_file(get_primary_xml_file())
     gale_dir = self.get_gale_xml_directory()

     doc.xpath('//page').each { |page_node|
       page_file = File.join(gale_dir, page_node['fileRef'])
       page_doc = XmlReader.open_xml_file(page_file)
       page_doc_els = page_doc.xpath('//page')
       if page_doc_els.length > 0
         page_node.replace(page_doc_els[0])
       end
     }
     return doc.to_xml
   end

   # get the original alto pages
   def get_original_alto_xml()

     # use the gale metadata to get a possible set of pages
     doc = XmlReader.open_xml_file(get_primary_xml_file())

     namespace = XmlReader.alto_namespace

     # for each page, attempt to get an alto page
     xml_pages = []
     page_num = 0
     doc.xpath('//page').each { |page_node|
       page_num += 1

       # if we have an alto page, add it to the alto document
       src = self.get_ocr_source( page_num )
       if src == :alto
          page_xml_path = get_page_xml_file(page_num, src, uri_root)
          xml_doc = XmlReader.open_xml_file(page_xml_path)
          xml_pages.push( xml_doc )
       end
     }

     root = nil
     peer = nil
     xml_pages.each_with_index { |pg, ix|
        if ix == 0
          root = pg
          peer = pg.xpath( '//ns:Layout', 'ns' => namespace ).first
        else
          description = pg.xpath( '//ns:Description', 'ns' => namespace ).first
          layout = pg.xpath( '//ns:Layout', 'ns' => namespace ).first
          peer.add_next_sibling( description )
          description.add_next_sibling( layout )
          peer = layout
        end
     }

     return root.to_xml
   end

   # attempt to create an ALTO page from gale page xml
   def gale_xml_to_alto_page( xml_doc )
     page = Nokogiri::XML::Node.new('page', xml_doc )
     info_xml = xml_doc.xpath( '//pageInfo' ).first
     page_xml = xml_doc.xpath( '//pageContent' ).first
     page.add_child( gale_xml_to_alto_description( info_xml ) )
     page.add_child( gale_xml_to_alto_page_content( page_xml ) )
     return( page )
   end

   # attempt to create an ALTO page from ALTO page xml   NOT USED NOW
   #def alto_xml_to_alto_page( xml_doc, page_num )
   #  namespace = XmlReader.alto_namespace
   #  page = Nokogiri::XML::Node.new('page', xml_doc )
   #  description_xml = xml_doc.xpath( '//ns:Description', 'ns' => namespace ).first
   #  page_xml = xml_doc.xpath( '//ns:Page', 'ns' => namespace ).first
   #  page_xml[ 'ID' ] = "page_#{page_num}"
   #  page.add_child( description_xml )
   #  page.add_child( page_xml )
   #  return( page )
   #end

   def gale_xml_to_alto_description( xml_doc )
     description = Nokogiri::XML::Node.new('Description', xml_doc )
     filename_xml = Nokogiri::XML::Node.new('filename', xml_doc )
     filename_xml.content = xml_doc.xpath( '//imageLink').first.content
     description.add_child( filename_xml )
     return( description )
   end

   def gale_xml_to_alto_page_content( xml_doc )
     layout = Nokogiri::XML::Node.new('Layout', xml_doc )
     page = new_alto_page( xml_doc, 1 )
     layout.add_child( page )

     page_words = XmlReader.read_all_lines_from_gale_page( xml_doc )
     current_paragraph = -1   # placeholder...
     line = nil
     word_num = 0
     page_words.each { | wd |

       # time for a new paragraph
       if wd[ :paragraph ] != current_paragraph
         current_paragraph = wd[ :paragraph ]
         para = self.new_alto_paragraph( xml_doc, current_paragraph + 1 )   # gale paragraph #'s are 0 indexed
         line = self.new_alto_line( xml_doc, 1 )                            # only 1 line per paragraph because gale documents do not have line information

         para.add_child( line )
         page.add_child( para )
       end

       word_num += 1
       w = self.new_alto_word( xml_doc, word_num, wd )
       line.add_child( w ) unless line.nil?
     }

     return( layout )
   end

   def get_corrected_tei_a(include_words)
      document_dtd = "#{Rails.root}/tmp/book.dtd"
      found = File.exist?(document_dtd)
      if !found
         File.open(document_dtd, "w") { |f| f.write("") }
      end

      xml_txt = get_corrected_gale_xml()
      xml_file = "#{Rails.root}/tmp/orig-#{self.id}-#{Time.now.to_i}.xml"
      File.open(xml_file, "w") { |f| f.write(xml_txt) }

      saxon = "#{Rails.root}/lib/saxon"
      tmp_file = "#{Rails.root}/tmp/#{self.id}-#{Time.now.to_i}.xml"
      xsl_file = "#{saxon}/GaleToTeiA.xsl"
      xsl_param = "showW='n'"
      xsl_param = "showW='y'"if include_words

      saxon_jar = "#{saxon}/Saxon-HE-9.5.1-1.jar"
      cmd = "java -jar #{saxon_jar}  #{xml_file} #{xsl_file} #{xsl_param} > #{tmp_file}"
      Document.do_command(cmd)
      file = File.open(tmp_file)
      out = file.read
      File.delete(xml_file)
      File.delete(tmp_file)
      return out
   end

   def get_corrected_page_text(page_num, src)
      page_info = get_page_info(page_num, false, false)
      page_text = ''
      page_info[:lines].each do | line |
         the_text = line[:text]
         # the_text is an array listing all the changes.
         # We want the last one, if it wasn't deleted.
         page_text += the_text.last + "\n" if the_text.last.present?
	  end
	  page_text = page_text.gsub(/<del>.+<\/del>/, '')
	  page_text = ActionView::Base.full_sanitizer.sanitize(page_text)
    return page_text
   end

   # get the corrected page in gale format (nothing to do with the source of the OCR)
   def get_corrected_page_gale_xml(page_num, uri_root = "")

      page_xml_path = get_page_xml_file(page_num, :gale, uri_root)          # use the gale source material and amend as appropriate

      page_doc = XmlReader.open_xml_file(page_xml_path)
      page_node = page_doc.xpath('//page')
      page_content_node = page_node.xpath('//pageContent').first()
      page_content_node.content = nil

      p_node = nil
      curr_p_num = 0
      page_info = get_page_info(page_num, false, false)
      page_info[:lines].each do | line |

         output_item = apply_line_edits( line )
         if output_item.present?

            # if there is no paragrah node - or the first word of the
            # current object has a different paragraph number - add the
            # content to the main body and generate a new paragraph node
            if p_node.nil? || curr_p_num != output_item[0][:paragraph]
               page_content_node << p_node if !p_node.nil?
               p_node = Nokogiri::XML::Node.new('p', page_doc)
               curr_p_num = output_item[0][:paragraph]
            end

            ab_node = Nokogiri::XML::Node.new('ab', page_doc)
            p_node << ab_node
            output_item.each do |word|
               wd_node = Nokogiri::XML::Node.new('wd', page_doc)
               wd_node.content = word[:word]
               pos_str = "#{word[:l]},#{word[:t]},#{word[:r]},#{word[:b]}"
               wd_node['pos'] = pos_str
               ab_node << wd_node
            end
         end
      end

      # dump out the last paragraph
      page_content_node << p_node if !p_node.nil?
      return page_node
   end

   # get the corrected page in alto format (nothing to do with the source of the OCR)
   def get_corrected_page_alto_xml(page_num, uri_root = "")

     # use the gale metadata
     doc = XmlReader.open_xml_file(get_primary_xml_file())
     page = new_alto_page( doc, page_num )

     current_paragraph = -1    # placeholder
     word_num = 0
     line = nil
     page_info = get_page_info( page_num, false, false )
     page_info[:lines].each do | ln |

       output_item = apply_line_edits( ln )
       if output_item.present?
          if current_paragraph != output_item[0][:paragraph]
            current_paragraph = output_item[0][ :paragraph ]
            para = new_alto_paragraph( doc, current_paragraph )
            line = new_alto_line( doc, 1 )                            # only 1 line per paragraph because gale documents do not have line information

            para.add_child( line )
            page.add_child( para )

          end

          output_item.each do |word|
             word_num += 1
             wd = self.new_alto_word( doc, word_num, word )
             line.add_child( wd ) unless line.nil?
          end
       end
     end

     return( page )
   end

   def apply_line_edits( line )

     # get the last entry that is not "correct", since they don't affect the output
     # (They are just confirmation that the line was looked at.) We'll just loop through to find it.
     output_item = line[:words].first
     if line[:actions].present?
       line[:actions].each_with_index do |action, i|
         if action == 'change'
           output_item = line[:words][i]
         elsif action == 'delete'
           output_item = nil
         end
       end
     end
     return( output_item )
   end

   # create a new alto page node; really just a placeholder
   def new_alto_page( xml_doc, page_num )
     page = Nokogiri::XML::Node.new('Page', xml_doc )
     page[ 'ID' ] = "page_#{page_num}"
     return( page )
   end

   # create a new alto paragraph node; really just a placeholder
   def new_alto_paragraph( xml_doc, paragraph_num )
     para = Nokogiri::XML::Node.new('TextBlock', xml_doc )
     para['ID'] = "par_#{paragraph_num}"
     para['WIDTH'] = ''                # we dont get any of this information from gale documents
     para['HEIGHT'] = ''
     para['HPOS'] = ''
     para['VPOS'] = ''
     return( para )
   end

   # create a new alto line node; really just a placeholder
   def new_alto_line( xml_doc, line_num )
     line = Nokogiri::XML::Node.new('TextLine', xml_doc )
     line['ID'] = "line_#{line_num}"
     line['WIDTH'] = ''                # we dont get any of this information from gale documents
     line['HEIGHT'] = ''
     line['HPOS'] = ''
     line['VPOS'] = ''
     return( line )
   end

   # create a new alto word node
   def new_alto_word( xml_doc, word_num, wd )
     word = Nokogiri::XML::Node.new('String', xml_doc )
     word['ID'] = "word_#{word_num}"
     word['WIDTH'] = wd[:r].to_i - wd[:l].to_i
     word['HEIGHT'] = wd[:b].to_i - wd[:t].to_i
     word['HPOS'] = wd[:t]
     word['VPOS'] = wd[:l]
     word['CONTENT'] = wd[:word]
     return( word )
   end

   # do any corrections exist for the specified page and document
   def corrections_exist?( doc_id, page_num, src )
     return Line.num_changes_for_page( doc_id, page_num, src ) != 0
   end

   # delete any corrections for the specified page, document and source
   def delete_corrections( doc_id, page_num, src )
      Line.delete_changes( doc_id, page_num, src )
   end

   def self.do_command(cmd)
      Rails.logger.info(cmd)
      # this also redirects stderr into resp
      resp = `#{cmd} 2>&1`
      Rails.logger.error( resp ) if resp && resp.length > 0 && resp != "\n"
      return resp
   end

   def get_document_root_directory(document_id, uri_root = "")
      directory = XmlReader.get_path('xml')
      directory = File.join(directory, uri_root)
      directory = File.join(directory, root_directory_path)
      document_path = File.join(directory, document_id)

      FileUtils.mkdir_p(document_path) unless FileTest.directory?(document_path)
      return document_path
   end

   def get_document_xml_directory(document_id, uri_root = "")
      path = get_document_root_directory(document_id, uri_root) + '/xml'
      Dir::mkdir(path) unless FileTest.directory?(path)
      return path
   end

   def get_document_image_directory(document_id, uri_root = "")
      path = get_document_root_directory(document_id, uri_root) + '/img'
      Dir::mkdir(path) unless FileTest.directory?(path)
      return path
   end

   def get_document_primary_xml_file(document_id, uri_root = "")
      name = "#{document_id}.xml"

      path = File.join(get_document_xml_directory(document_id, uri_root), name)
      return path
   end

   def get_document_page_xml_file(document_id, page, src = :gale, uri_root = "")
      page_id = XmlReader.format_page(page) + '0'

      name = "#{document_id}_#{page_id}.xml"

      document_xml_path = get_document_xml_directory(document_id, uri_root)
      document_xml_path = File.join(document_xml_path, "#{src}")
      Dir::mkdir(document_xml_path) unless FileTest.directory?(document_xml_path)
      path = File.join(document_xml_path, name)
      return path
   end

   def self.ecco_install(uri, xml_file, path_to_images)
      # example params: ('lib://ECCO/0011223300',
      # '/raw/path/GenRef/XML/0011223300.xml',
      # '/raw/path/GenRef/Images/0011223300')
      document = Document.find_by_uri(uri)
      document = Document.create!({ uri: uri }) if document.blank?

      # uploading xml_file for entire volume
      page_count = document.import_primary_xml(File.new(xml_file))

      id = document.document_id()
      img_path = document.get_image_directory()
      page_count.times { |page_num|
      # Copy each page into the typewright area
         fname = "#{id}#{XmlReader.format_page(page_num+1)}0.TIF"
         image_file = "#{path_to_images}#{fname}"
         if !File.exists?(image_file)
            # try with a lowercase extension. Some tif files where named like
            # that.
            image_file = image_file.gsub(".TIF", '.tif')
         end

         if !File.exists?(image_file)
            puts "Missing Image file #{image_file}"
         else
            dest_path = File.join(img_path, fname)
            dest_path = dest_path.gsub(".tif", ".TIF")
            FileUtils.cp(image_file, dest_path)

         document.import_page(page_num+1, image_file)
         end
      }
   end

   def self.eebo_install( uri, title, path_to_xml, path_to_images )
     # example params: ('lib://EEBO/0011223300-0005567893',
     # 'something very interesting',
     # '/data/shared/text-xml/IDHMC-ocr/0/0/153',
     # '/data/eebo/e0014/40093')

     #puts "URI: #{uri}"
     #puts "XML: #{path_to_xml}"
     #puts "IMG: #{path_to_images}"

     original_dir = Dir.pwd
     Dir.chdir( path_to_xml )
     xml_list = []
     Dir.glob("*") { |f|
       xml_list << f if f.end_with?( "_ALTO.XML", "_alto.xml", "_ALTO.xml", "_alto.XML" )
     }

     Dir.chdir( original_dir )
     Dir.chdir( path_to_images )
     image_list = []
     Dir.glob("*") { |f|
       image_list << f if f.end_with?( ".tif", ".TIF" )
     }

     Dir.chdir( original_dir )

     # make sure we have some images...
     if image_list.length != 0
       if image_list.length >= xml_list.length

         #puts "Found #{image_list.length} images, #{xml_list.length} XML files"

         #puts "Creating #{uri} ..."
         document = Document.find_by_uri(uri)
         document = Document.create!({ uri: uri }) if document.blank?

         dest_img_path = document.get_image_directory()

         page_num = 1
         while true

           # get the image for this page... if not, we are done
           image_file = Document.get_image_filename_for_page( image_list, page_num )
           break if image_file.empty?

           source_img = "#{path_to_images}/#{image_file}"
           dest_img = dest_img_path
           dest_img = File.join( dest_img, sprintf( "%s%05d0.tif", document.document_id, page_num) )
           FileUtils.rm( dest_img, { :force => true } ) if FileTest.file?( dest_img )
           FileUtils.cp(source_img, dest_img )

           xml_file = Document.get_xml_filename_for_page( xml_list, page_num )

           # we have a file for this page, use it, else create a placeholder
           if xml_file.blank? == false
              source_xml = "#{path_to_xml}/#{xml_file}"
              xml_doc = XmlReader.open_xml_file( source_xml )
           else
              # use the placeholder file
              source_xml = "#{Rails.root}/data/empty_alto.xml"
              xml_doc = XmlReader.open_xml_file( source_xml )
              page_block = xml_doc.xpath( '//ns:Page', 'ns' => XmlReader.alto_namespace ).first
              page_block[ "ID" ] = "page_#{page_num}"
           end

           img_block = xml_doc.xpath( '//ns:filename', 'ns' => XmlReader.alto_namespace ).first
           img_block.content = File.basename( dest_img )

           dest_xml = document.get_document_page_xml_file( document.document_id, page_num, :alto )
           FileUtils.rm( dest_xml, { :force => true } ) if FileTest.file?( dest_xml )
           File.open( dest_xml, "w") { |f| f.write(xml_doc.to_xml) }

           document.import_page( page_num, source_img )
           page_num += 1
         end
         document.generate_primary_xml( title, page_num - 1 )
         document.save!
       else
         puts "Cannot match images with pages (too many pages) for #{uri}"
       end
     else
       puts "No images available in #{path_to_images} for #{uri}"
     end
   end

   def self.get_image_filename_for_page( image_list, page_num )

     image_list.each { |name|
        # the EEBO image names have the form
        # nnnnn.xxx.xxx.tif where nnnnn is the page number
        tokens = name.split( "." )
        return name if tokens.length == 4 && tokens[ 0 ].to_i == page_num
     }

     # could not find an image for this page so there are no more pages
     return ""
   end

   def self.get_xml_filename_for_page( xml_list, page_num )
     xml_list.each { |name|
       tokens = name.split( "." )
       return name if tokens.length == 2 && tokens[ 0 ].to_i == page_num
     }

     # we could not find a file for this page, return empty
     return ""
   end
end
