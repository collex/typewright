# encoding: UTF-8
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

class XmlReader
	require 'nokogiri'

	def self.format_page(page)
    "0000#{page}"[-4, 4]
	end

  def self.open_xml_file(filename, mode = 'r')
    f = File.open(filename, mode)
    doc = Nokogiri::XML(f)
    return doc
  end

  def self.get_page_image_filename(page_doc)
    image_filename = page_doc.xpath('//pageInfo/imageLink')[0].content
    return image_filename
  end

  def self.get_num_pages(doc)
    num_pages = doc.xpath('//page').size
    return num_pages
  end

  def self.get_full_title(doc)
    title_path = doc.xpath('//fullTitle')[0]
    title = title_path.content unless title_path.nil?
    return title
  end

  def self.get_ecco_id(doc)
    ecco_path = doc.xpath('//book/bookInfo/documentID')[0]
    ecco_id = ecco_path.content unless ecco_path.nil?
    return ecco_id
  end

  def self.read_all_lines_from_page(page_doc, src)
    cmd = "XmlReader.read_all_lines_from_#{src}_page(page_doc)"
    result = eval(cmd)
    return result
  end

  def self.read_all_lines_from_gale_page(page_doc)
    page_src = []
    paragraph_num = 0

    # read the page data from gale's xml
    page_doc.xpath('//pageContent/p').each do |ps|
      ps.xpath('wd').each do |wd|
        pos = wd.attribute('pos')
        arr = pos.to_s.split(',')
        # initially treat a line and paragraph as the same thing
        page_src.push({ :l => arr[0].to_i, :t => arr[1].to_i, :r => arr[2].to_i, :b => arr[3].to_i, :word => wd.text, :line => paragraph_num, :paragraph=>paragraph_num})
      end
      paragraph_num += 1
    end

    # now split the paragraph into lines based on y positions
    page_src = XmlReader.gale_create_lines(page_src)
    return page_src
  end

  def self.read_all_lines_from_gamera_page(page_doc)
    page_src = []
    num_lines = 0
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
    return page_src
  end

  def self.read_all_lines_from_alto_page(page_doc)
    page_src = []
    num_lines = 0
    paragraph_num = 0
    # read the page data from alto's xml
    page_doc.xpath('//ns:Page', 'ns' => 'http://schema.ccs-gmbh.com/ALTO').each { |pg|
      pg.xpath('TextBlock').each { |tb|
        paragraph_num += 1
        tb.xpath('TextLine').each { |ln|
          ln.xpath('String').each { |wd|
            width = wd.attributes['WIDTH']
            height = wd.attributes['HEIGHT']
            hpos = wd.attributes['HPOS']
            vpos = wd.attributes['VPOS']
            word = wd.attributes['CONTENT']
            page_src.push({ :l => hpos.to_i, :t => vpos.to_i, :r => hpos.to_i + width.to_1, :b => vpos.to_i + height.to_i, :word => word, :line => num_lines, :paragraph=>paragraph_num })
          }
          num_lines += 1
        }
      }
    }
    return page_src
  end

  def self.detect_ocr_source(xml_doc)

    if !xml_doc.xpath('//ns:TextBlock', 'ns' => 'http://schema.ccs-gmbh.com/ALTO').empty?
      return :alto # alto page
    end

    has_page_info = !xml_doc.xpath('//page/pageInfo').empty?
    has_book_info = !xml_doc.xpath('//book/bookInfo').empty?
    has_page_line = !xml_doc.xpath('//page/line').empty?
    if has_book_info && has_page_info
      return :gale # gale master xml with pages included
    elsif has_page_line && !has_page_info
      return :gamera # gamera page
    elsif has_page_info && !has_page_line
      return :gale # gale page
    end
    return :unknown
  end


   ## USED
	def self.line_factory(l, t, r, b, line, paragraph, words, text, num, src)
		return { :l => l, :t => t, :r => r, :b => b, :words => words, :text => text, :paragraph=>paragraph, :line => line, :num => num, :src => src }
	end

   ## USED
	def self.create_lines(gamera_arr, src)
		ret = []
		gamera_arr.each_with_index { |wd, i|
			if !ret[wd[:line]]
				ret[wd[:line]] = { :l => wd[:l], :t => wd[:t], :r => wd[:r], :b => wd[:b], :words => [[wd]], :text => [wd[:word]], :line => wd[:line], :paragraph=>wd[:paragraph], :src => src }
			else
				line = ret[wd[:line]]
				line[:words][0].push(wd)
				begin
				  line[:text][0] += ' ' +wd[:word]
				rescue
					puts "Failed on entry:#{i}"
				end
				line[:l] = wd[:l] if line[:l] > wd[:l]
				line[:t] = wd[:t] if line[:t] > wd[:t]
				line[:r] = wd[:r] if line[:r] < wd[:r]
				line[:b] = wd[:b] if line[:b] < wd[:b]
				line[:line] = wd[:line]
				line[:paragraph] = wd[:paragraph]
            line[:src] = src
			end
		}
		return ret
	end

   def self.gale_create_lines_p(gale_arr)
      ret = []
      # this is an array of the paragraphs. We never want to join words across paragraphs, but we also want
      # to split the paragraphs into lines by starting a new line whenever the word doesn't overlap the last one.
      last_y = -1
      last_h = -1
      last_x = 200000
      last_line = -1
      line_num = -1
      gale_arr.each do |p|
         para = []
         p.each do |wd|
            if last_y > wd[:b] || last_h < wd[:t] || last_x > wd[:l] || last_line != wd[:line]
               line_num += 1
            end
            para.push({ :l => wd[:l], :t => wd[:t], :r => wd[:r], :b => wd[:b], :word => wd[:word], :line => line_num, :src => wd[:src] })
            last_y = wd[:t]
            last_h = wd[:b]
            last_x = wd[:l]
            last_line = wd[:line]
         end
         ret << para
      end
      return ret
  end

	def self.gale_create_lines(gale_arr)
		ret = []
		# this is an array of the paragraphs. We never want to join words across paragraphs, but we also want
		# to split the paragraphs into lines by starting a new line whenever the word doesn't overlap the last one.
		last_y = -1
		last_h = -1
		last_x = 200000
		last_line = -1
		line_num = -1
		gale_arr.each { |wd|
			if last_y > wd[:b] || last_h < wd[:t] || last_x > wd[:l] || last_line != wd[:line]
				line_num += 1
			end
			ret.push({ :l => wd[:l], :t => wd[:t], :r => wd[:r], :b => wd[:b], :word => wd[:word], :line => line_num, :paragraph=>wd[:paragraph], :src => wd[:src] })
			last_y = wd[:t]
			last_h = wd[:b]
			last_x = wd[:l]
			last_line = wd[:line]
		}
		return ret
  end

  def self.get_path(which)
    config_file = File.join("config", "site.yml")
    if File.exists?(config_file)
      site_specific = YAML.load_file(config_file)
      return site_specific['paths'][which]
    end
  end

end
