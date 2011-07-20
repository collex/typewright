THUMBNAIL_WIDTH = 150
IMAGE_WIDTH = 800
SLICE_HEIGHT = 50

desc "Import a document from the ECCO HD (ecco_index=0123456789 folder=/path/to/input/data)"
task :import do
	start_time = Time.now
	ecco_index = ENV['ecco_index']
	folder = ENV['folder']
	out_xml = get_path('xml')
	if ecco_index == nil || folder == nil
		puts "Usage: call with ecco_index=0123456789 folder=/path/to/input/data"
		puts "The folder specified should contain the following structure:"
		puts "/path/to/input/data"
		puts "	0123456789"
		puts "		images"
		puts "			012345678900010.TIF"
		puts "			etc... (for each page)"
		puts "		xml"
		puts "			0123456789.xml (the gale data for the entire doc)"
		puts ""
		puts "The output is placed in #{out_xml}/ and Rails.root/public/uploaded/"
		puts "See #{Rails.root}/config/site.yml for path info."
	else
		imagemagick = get_path('imagemagick')
		convert = "#{imagemagick}/convert"
		identify = "#{imagemagick}/identify"

		src_folder = "#{folder}/#{ecco_index}"
		dst_folder = "#{out_xml}/#{ecco_index}"
		src_img_folder = "#{src_folder}/images"
		src_xml = "#{src_folder}/xml/#{ecco_index}.xml"
		dst_xml = "#{dst_folder}/#{ecco_index}.xml"
		dst_img_folder = "#{Rails.root}/public/uploaded/#{ecco_index}"

		# copy the xml file
		do_command("mkdir #{dst_folder}")
		do_command("cp #{src_xml} #{dst_xml}")
		create_metadata("#{dst_xml}")
		read_all_gale("#{dst_xml}")

		# create the images
		do_command("mkdir #{dst_img_folder}")
		do_command("mkdir #{dst_img_folder}/thumbnails")
		sizes_file = "#{dst_img_folder}/sizes.csv"
		do_command("rm #{sizes_file}")

		page = 1
		page_str = create_page(ecco_index, page)
		src_img = "#{src_img_folder}/#{page_str}.TIF"
		dst_img_subfolder = "#{dst_img_folder}/#{page_str}"

		while File.exists?(src_img)
			do_command("mkdir #{dst_img_subfolder}")
			# do the slices in two steps: first create a temporary png file reduced to the correct width, then slice that up.
			tmp_png = "#{dst_img_subfolder}/#{page_str}.png"
			do_command("#{convert} #{src_img} -resize #{IMAGE_WIDTH} #{tmp_png}")
			#now create the slices
			do_command("#{convert} #{tmp_png} -crop #{IMAGE_WIDTH}x#{SLICE_HEIGHT} #{dst_img_subfolder}/#{page_str}_TMP%03d.png")
			# unfortunately, the convert program numbers the slices as base-0, so change that to base-1
			slice = 0
			resp = ""
			while resp.length == 0
				in_num = "%03d" % slice
				out_num = "%03d" % (slice+1)
				slice_out = "#{dst_img_subfolder}/#{page_str}_#{out_num}.png"
				resp = do_command("mv #{dst_img_subfolder}/#{page_str}_TMP#{in_num}.png #{slice_out}")
				slice += 1
			end
			# create the thumbnail
			thumb = "#{dst_img_folder}/thumbnails/#{page_str}_thumb.png"
			do_command("#{convert} #{src_img} -resize #{THUMBNAIL_WIDTH} #{thumb}")

			# remove the original file since that was just created to make the slices from
			do_command("rm #{dst_img_subfolder}/#{page_str}.png")

			# create the sizes.csv file that contains the original size of all the images.
			size_arr = do_command("#{identify} #{src_img}")
			# size_arr contains something like: 045660030500010.TIF TIFF 1216x2144 etc...
			size_arr = size_arr.split(' ')
			size_arr = size_arr[2].split('x')
			open(sizes_file, 'a') { |f| f.puts "#{page_str}.TIF,#{size_arr[0]},#{size_arr[1]}" }

			page += 1
			page_str = create_page(ecco_index, page)
			src_img = "#{src_img_folder}/#{page_str}.TIF"
			dst_img_subfolder = "#{dst_img_folder}/#{page_str}"
		end

		finish_line(start_time)
	end
end

def create_page(ecco_index, page)
	return "#{ecco_index}#{"%04d" % page}0"
end

def create_metadata(fname)
  fl = File.new(fname, "r:UTF-8")
	doc = Nokogiri::XML(fl)
	doc.xpath('//fullTitle').each { |node|
		title = { :title => node.text }
		arr = fname.split('.')
		fname = "#{arr[0]}_meta.yml"
		puts title[:title]
		File.open( fname, 'w:UTF-8' ) do |out|
			YAML.dump( title, out )
		end
	}
end

def do_command(cmd)
	puts cmd
	# this also redirects stderr into resp
	resp = `#{cmd} 2>&1`
	puts resp if resp && resp.length > 0 && resp != "\n"
	return resp
end

def finish_line(start_time)
	duration = Time.now-start_time
	if duration >= 60
		str = "Finished in #{"%.2f" % (duration/60)} minutes."
	else
		str = "Finished in #{"%.2f" % duration} seconds."
	end
	puts(str)
end

def get_path(which)
	config_file = File.join("config", "site.yml")
	if File.exists?(config_file)
		site_specific = YAML.load_file(config_file)
		return site_specific['paths'][which]
	end
end

desc "Create the yml version of the XML data for a document (ecco_index=0123456789)"
task :create_yml do
	start_time = Time.now
	ecco_index = ENV['ecco_index']
	if ecco_index == nil
		puts "Usage: call with ecco_index=0123456789"
	else
		out_xml = get_path('xml')
		xml_path = "#{out_xml}/#{ecco_index}/#{ecco_index}.xml"
		read_all_gale(xml_path)
	end
end

def read_all_gale(fname)
	doc = Nokogiri::XML(File.new(fname))
	#doc = REXML::Document.new( File.new(fname) )

	doc.xpath('//imageLink').each { |image|
	#REXML::XPath.each( doc, "//imageLink" ){ |image|
		print '.'
		arr = image.text.split('.')
		number = arr[0]
		slash = fname.rindex('/')
		cache_name = fname[0..slash] + number
		ret = read_gale_page(image, cache_name)
		write_cache(cache_name, "gale", ret)
	}
end

def read_gale_page(image, cache_name)
	page = image.parent.parent
	#content = page.elements['pageContent']
	ret = []
	lines = 0
	page.xpath('pageContent/p').each { |ps|
	#content.elements.each('p') { |ps|
		ps.xpath('wd').each { |wd|
		#ps.elements.each('wd') { |wd|
			pos = wd.attribute('pos')
			#pos = wd.attributes['pos']
			arr = pos.to_s.split(',')

			ret.push({ :line => lines, :h => arr[3].to_i, :x => arr[0].to_i, :word => wd.text, :y => arr[1].to_i, :w => arr[2].to_i })
		}
		lines += 1
	}
	#write_cache(cache_name, "gale", ret)
	return ret
end

def write_cache(xml_fname, prefix, words)
	arr = xml_fname.split('.')
	fname = "#{arr[0]}_#{prefix}.yml"
	File.open( fname, 'w' ) do |out|
		YAML.dump( words, out )
	end
end


