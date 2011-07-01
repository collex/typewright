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
		puts "			0123456789.xml"
		puts ""
		puts "The output is placed in #{out_xml}/ and Rails.root/public/uploaded/"
	else
		imagemagick = get_path('imagemagick')

		# copy the xml file
		do_command("mkdir #{out_xml}/#{ecco_index}")
		do_command("cp #{folder}/#{ecco_index}/xml/#{ecco_index}.xml #{out_xml}/#{ecco_index}/#{ecco_index}.xml")
		create_metadata("#{out_xml}/#{ecco_index}/#{ecco_index}.xml")
		read_all_gale("#{out_xml}/#{ecco_index}/#{ecco_index}.xml")

		# create the images
		base_img = "#{folder}/#{ecco_index}/images"
		page = 1
		in_img = "#{base_img}/#{create_page(ecco_index, page)}.TIF"
		base_out = "#{Rails.root}/public/uploaded/#{ecco_index}"
		do_command("mkdir #{base_out}")
		do_command("mkdir #{base_out}/thumbnails")
		sizes_file = "#{base_out}/sizes.csv"
		do_command("rm #{sizes_file}")
		while File.exists?(in_img)
			out_img = "#{base_out}/#{create_page(ecco_index, page)}"
			do_command("mkdir #{out_img}")
			do_command("#{imagemagick}/convert #{in_img} -resize 800 #{out_img}/#{create_page(ecco_index, page)}.png")
			#now create the slices
			do_command("#{imagemagick}/convert #{out_img}/#{create_page(ecco_index, page)}.png -crop 800x60 #{out_img}/#{create_page(ecco_index, page)}_TMP%03d.png")
			slice = 0
			resp = ""
			while resp.length == 0
				in_num = "%03d" % slice
				out_num = "%03d" % (slice+1)
				slice_out = "#{out_img}/#{create_page(ecco_index, page)}_#{out_num}.png"
				resp = do_command("mv #{out_img}/#{create_page(ecco_index, page)}_TMP#{in_num}.png #{slice_out}")
				slice += 1
			end
			# create the thumbnail
			thumb = "#{base_out}/thumbnails/#{create_page(ecco_index, page)}_thumb.png"
			do_command("#{imagemagick}/convert #{in_img} -resize 150 #{thumb}")

			# remove the original file since that was just created to make the slices from
			do_command("rm #{out_img}/#{create_page(ecco_index, page)}.png")

			size_arr = do_command("#{imagemagick}/identify #{in_img}")
			# size_arr contains something like: 045660030500010.TIF TIFF 1216x2144 etc...
			size_arr = size_arr.split(' ')
			size_arr = size_arr[2].split('x')
			open(sizes_file, 'a') { |f| f.puts "#{create_page(ecco_index, page)}.TIF,#{size_arr[0]},#{size_arr[1]}" }

			page += 1
			in_img = "#{base_img}/#{create_page(ecco_index, page)}.TIF"
		end

		finish_line(start_time)
	end
end

def create_page(ecco_index, page)
	return "#{ecco_index}#{"%04d" % page}0"
end

def create_metadata(fname)
	doc = Nokogiri::XML(File.new(fname))
	doc.xpath('//fullTitle').each { |node|
		title = { :title => node.text }
		arr = fname.split('.')
		fname = "#{arr[0]}_meta.yml"
		puts title[:title]
		File.open( fname, 'w' ) do |out|
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


