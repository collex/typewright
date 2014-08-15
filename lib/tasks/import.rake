THUMBNAIL_WIDTH = 150
IMAGE_WIDTH = 800
SLICE_HEIGHT = 50

namespace :upload do
	# This assumes that the ECCO disks are mounted and there is a symbolic link to them something like this:
	#ln -s /Volumes/18th\ C\ Collections\ Online\ 1of2/ECCO_1of2/ /Users/USERNAME/ecco1
	#ln -s /Volumes/18th\ C\ Collections\ Online\ 2of2/ECCO_2of2/ /Users/USERNAME/ecco2
	#ln -s /Volumes/18th\ C\ Collections\ Online\ 2of2/RelAndPhil/ /Users/USERNAME/ecco2b
	#ln -s /Volumes/ECHOII/ /Users/USERNAME/ecco3

	desc "Upload typewright files (gale format) to the server (id=0123456789-0123456789-...)"
	task :gale_document, :id do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.

		ids = args[:id] #ENV['id']
		if ids == nil
			puts "Usage: call with id=0123456789-0123456789-..."
		else
			ids = ids.split('-')
			ids.each {|id|
				full_path = find_file(id)
				if full_path.present?
					upload_gale(full_path)
				else
					puts "NOT FOUND: #{id}"
				end
			}
		end
	end

  desc "Upload typewright files (ALTO format) to the server (id=0123456789-0123456789-...)"
  task :alto_document, :id do |t, args|
    # It will search for a document in all the possible places for it, and stop when it finds it.

    ids = args[:id] #ENV['id']
    if ids == nil
      puts "Usage: call with id=0123456789-0123456789-..."
    else
      ids = ids.split('-')
      ids.each {|id|
        full_path = find_file(id)
        if full_path.present?
          upload_alto(full_path)
        else
          puts "NOT FOUND: #{id}"
        end
      }
    end
  end

	desc "Install ECCO documents that are on the same server as typewright (file=path$path) [one 10-digit number per line]"
	task :install, [:file] => :environment do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.

		fnames = args[:file]
		fnames = fnames.split("$")
		puts fnames.map { |str| ">>> #{str} <<<"}
		fnames.each { |fname|
			ids = File.open(fname, 'r') { |f| f.read }
			ids = ids.split("\n")
			if ids == nil
				puts "Usage: call with a filename. The file contains one 10-digit number per line"
			else
				puts "Attempting to import #{ids.length} documents"
				ids.each_with_index { |id, index|
					uri = "lib://ECCO/#{id}"
					full_path = find_file(id)
					if full_path.present?
						folder = up_one_folder(full_path) + "/images/"
						begin
						Document.install(uri, full_path, folder)
						rescue Exception => e
							puts "#{e.to_s} [#{full_path}]"
						end
						print "\n[#{index}]" if index % 100 == 0
						print '.'
					else
						full_path = find_file2(id)
						if full_path.present?
							folder = up_one_folder(full_path) + "/Images/#{id}/"
							begin
							Document.install(uri, full_path, folder)
							rescue Exception => e
								puts "#{e.to_s} [#{full_path}]"
							end
							print "\n[#{index}]" if index % 100 == 0
							print '.'
						else
							puts "NOT FOUND: #{id}"
						end
					end
				}
				puts ""
			end
		}
	end

	desc "Upload typewright files (gale format) to the server from a set of files (file=path$path) [one 10-digit number per line]"
	task :gale_from_file, :file do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.

		fnames = args[:file]
		fnames = fnames.split("$")
		puts fnames.map { |str| ">>> #{str} <<<"}
		fnames.each { |fname|
			ids = File.open(fname, 'r') { |f| f.read }
			ids = ids.split("\n")
			if ids == nil
				puts "Usage: call with a filename. The file contains one 10-digit number per line"
			else
				ids.each { |id|
					full_path = find_file(id)
					if full_path.present?
						upload_gale(full_path)
					else
						puts "NOT FOUND: #{id}"
					end
				}
			end
		}
	end

  desc "Upload typewright files (ALTO format) to the server from a set of files (file=path$path) [one 10-digit number per line]"
  task :alto_from_file, :file do |t, args|
    # It will search for a document in all the possible places for it, and stop when it finds it.

    fnames = args[:file]
    fnames = fnames.split("$")
    puts fnames.map { |str| ">>> #{str} <<<"}
    fnames.each { |fname|
      ids = File.open(fname, 'r') { |f| f.read }
      ids = ids.split("\n")
      if ids == nil
        puts "Usage: call with a filename. The file contains one 10-digit number per line"
      else
        ids.each { |id|
          full_path = find_file(id)
          if full_path.present?
            upload_alto(full_path)
          else
            puts "NOT FOUND: #{id}"
          end
        }
      end
    }
  end

	desc "Create scripts to run on Brazos for all documents specified in the set of files (file=path$path) [one 10-digit number per line]"
	task :create_scripts, :file do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.
		substitutions = ["/fdata/idhmc/18connect/ECCO_1of2/", "/fdata/idhmc/18connect/ECCO_2of2/"]

		fnames = args[:file]
		fnames = fnames.split("$")
		puts fnames.map { |str| ">>> #{str} <<<"}
		fnames.each { |fname|
			num = fname.gsub(/[^0-9]/,'')
			sh_name = "tmp/brazos_script#{num}.sh"
			File.open(sh_name, 'w') {|f| f.write("#!/bin/sh\n") }

			ids = File.open(fname, 'r') { |f| f.read }
			ids = ids.split("\n")
			if ids == nil
				puts "Usage: call with a filename. The file contains one 10-digit number per line"
			else
				ids.each { |id|
					full_path = find_file(id)
					if full_path.present?
						script = create_remote_script(full_path, substitutions)
						File.open(sh_name, 'a') {|f| f.write(script+"\n") }
					else
						puts "NOT FOUND: #{id}"
					end
				}
			end
		}
	end

	desc "Create scripts (for ECCOII) to run on Brazos for all documents specified in the set of files (file=path$path) [one 10-digit number per line]"
	task :create_scripts2, :file do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.
		substitutions = ["/fdata/idhmc/18connect/ECCOII/"]

		fnames = args[:file]
		fnames = fnames.split("$")
		puts fnames.map { |str| ">>> #{str} <<<"}
		fnames.each { |fname|
			num = fname.gsub(/[^0-9]/,'')
			sh_name = "tmp/brazos_script#{num}.sh"
			File.open(sh_name, 'w') {|f| f.write("#!/bin/sh\n") }

			ids = File.open(fname, 'r') { |f| f.read }
			ids = ids.split("\n")
			if ids == nil
				puts "Usage: call with a filename. The file contains one 10-digit number per line"
			else
				ids.each { |id|
					full_path = find_file2(id)
					if full_path.present?
						script = create_remote_script(full_path, substitutions, "-2")
						File.open(sh_name, 'a') {|f| f.write(script+"\n") }
					else
						puts "NOT FOUND: #{id}"
					end
				}
			end
		}
	end

	desc "Create rsync script (for ECCOII) to run on Brazos to get all images to typewright server (file=path$path) [one 10-digit number per line]"
	task :create_rsync2, :file do |t, args|
		# It will search for a document in all the possible places for it, and stop when it finds it.

		fnames = args[:file]
		fnames = fnames.split("$")
		puts fnames.map { |str| ">>> #{str} <<<"}
		fnames.each { |fname|
			num = fname.gsub(/[^0-9]/,'')
			sh_name = "tmp/brazos_rsync#{num}.sh"
			File.open(sh_name, 'w') {|f| f.write("#!/bin/sh\n") }
			File.open(sh_name, 'a') {|f| f.write("BASEPATH=/fdata/idhmc/18connect/ECCOII\n") }
			File.open(sh_name, 'a') {|f| f.write("DEST=typewright@typewright.sl.performantsoftware.com:/raid/raw_ecco/ECCOII/\n") }

			ids = File.open(fname, 'r') { |f| f.read }
			ids = ids.split("\n")
			if ids == nil
				puts "Usage: call with a filename. The file contains one 10-digit number per line"
			else
				ids.each { |id|
					full_path = find_file2(id)
					if full_path.present?
						arr = full_path.split('/')
						arr.pop # the file name
						arr.pop # the XML folder
						dest_path = arr.join('/')
						arr.push "Images/#{id}"
						path = arr.join('/')
						my_base = "#{Rails.root}".split('/')
						my_base = "#{my_base[0]}/#{my_base[1]}/#{my_base[2]}/ecco3"
						path = path.gsub(my_base, "$BASEPATH")
						dest_path = dest_path.gsub(my_base, "")
						File.open(sh_name, 'a') {|f| f.write("rsync -rtvz #{path} $DEST#{dest_path}\n") }
					else
						puts "NOT FOUND: #{id}"
					end
				}
			end
		}
	end

	desc "find original document on the usb drives"
	task :find, :ids do |t, args|
		ids = args[:ids].split('-')
		ids.each { |id|
			full_path = find_file(id)
			if full_path.present?
				puts "FOUND: #{full_path}..."
			else
				puts "NOT FOUND: #{id}"
			end
		}
	end

	desc "Sanity check each document in the database. Run this from the typewright server."
	task :sanity_check => :environment do
		# This accesses the xml file, and checks to see that all image files exist. That happens because all the
		# image slices are generated in the get_doc_info call if they weren't already created.

		docs = Document.all
		docs.each_with_index { |doc, index|
			if doc.uri.blank?
				referenced = false
				rec = DocumentUser.find_by_document_id(doc.id)
				referenced = true if rec.present?
				rec = Lines.find_by_document_id(doc.id)
				referenced = true if rec.present?
				rec = PageReport.find_by_document_id(doc.id)
				referenced = true if rec.present?
				if referenced
					puts "Blank doc #{doc.id} is referenced"
				else
					puts "Blank doc #{doc.id} can be safely deleted"
				end
			else
				# Simulate getting the main page
				begin
					info = doc.get_doc_info()
					info['num_pages'].times { |x|
						doc.get_page_info(x+1, false)
					}
				rescue Exception => e
					puts "#{doc.uri}: #{e.to_s}"
				end
			end
			print "\n[#{index}]" if index % 100 == 0
			print '.'
		}
	end

end

require 'json'

desc "read ecco ids (file=/path/to/file)"
task :ecco_uri, :path do |t, args|
	path = args[:path]
	json = File.open(path, 'r') { |f| f.read }
	hash = JSON.parse(json)
	File.open(path+'out', 'w') { |f|
		hash['response']['docs'].each {|doc|
			f.puts doc['uri']
		}
	}
end

desc "try to open each document in the file passed. (This is the uri, one per line) (file=/path/to/file). Run this from the typewright server."
task :touch_all_typewright, :path do |t, args|
	path = args[:path]
	docs = File.open(path, 'r') { |f| f.read }
	docs = docs.split("\n")

	File.open(path+".ok.txt", 'w') { |ok|
		File.open(path+".error.txt", 'w') { |err|
			docs.each_with_index {|doc,count|
				File.open(path+".progress.txt", 'a') {|f| f.puts(count) }
				cmd = "curl \"localhost/documents.xml?id=#{doc}&src=gale\""
				puts cmd
				resp = `#{cmd}`
				start = resp[0..4]
				if start == "<html"
					err.puts("=============== #{doc} =================")
					err.puts(resp)
				elsif start == "<?xml"
					ok.puts("=============== #{doc} =================")
					ok.puts(resp)
				else
					puts "!!!! #{start}"
				end
				puts "."
#				if resp.include?("Action Controller: Exception caught")
#					msg = ""
#					arr = resp.split("<pre>")
#					if arr.length >= 2
#						arr = arr[1].split("</pre>")
#						if arr.length >= 2
#							msg = arr[0]
#						end
#					end
#					err.puts("#{doc}: #{msg}")
#					puts "#{doc}: #{msg}"
#				else
#					ok.puts("#{doc}")
#					puts "#{doc}: OK"
#				end
			}
		}
	}
end

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

def upload_gale(full_path)
	script = "./script/import/gale_xml -v -f typewright.sl.performantsoftware.com"

	puts "uploading: #{full_path}..."
	`#{script} #{full_path} >> #{Rails.root}/log/manual_upload.log`
end

def upload_alto(full_path)
  script = "./script/import/alto_xml -v -f typewright.sl.performantsoftware.com"

  puts "uploading: #{full_path}..."
  `#{script} #{full_path} >> #{Rails.root}/log/manual_upload.log`
end

def base_path()
	path = "#{Rails.root}".split('/')
	path = "/#{path[1]}/#{path[2]}/"
	return path
end

def up_one_folder(full_path)
	arr = full_path.split('/')
	arr.pop # the file name
	arr.pop # the XML folder
	dest_path = arr.join('/')
	return dest_path
end

def create_remote_script(full_path, substitutions, flags='')
	script = "./script/import/gale_xml -f -c #{flags} typewright.sl.performantsoftware.com"
	ret = `#{script} #{full_path}`
	#script = "./gale_xml -v -f typewright.sl.performantsoftware.com"
	#ret = "#{script} #{full_path} >> log/manual_upload.log"
	ret = ret.gsub("#{base_path}ecco3/", substitutions[0])
	ret = ret.gsub("#{base_path}ecco1/", substitutions[0])
	ret = ret.gsub("#{base_path}ecco2/", substitutions[1]) if substitutions.length > 1
	return ret
end

def find_file(id)
	if id.length != 10
		puts "Bad id: #{id}"
	end
	folders = ['ecco1/HistAndGeo', 'ecco1/MedSciTech', 'ecco1/SSAndFineArt', 'ecco2/GenRef',
		'ecco2/Law', 'ecco2/LitAndLang_1', 'ecco2/LitAndLang_2', 'ecco2/RelAndPhil', 'ecco2b']

	folders.each { |folder|
		full_path = base_path + folder + '/' + id + "/xml/" + id + ".xml"
		if File.exists?(full_path)
			return full_path
		end
	}
	return nil
end

def find_file2(id)
	if id.length != 10
		puts "Bad id: #{id}"
	end
	folders = [  'ecco3/GenRef', 'ecco3/HistAndGeo', 'ecco3/Law', 'ecco3/LitAndLang', 'ecco3/MedSciTech', 'ecco3/RelAndPhil', 'ecco3/SSFineArts',
		'ecco3/June2010Update/GenRef', 'ecco3/June2010Update/HistAndGeo', 'ecco3/June2010Update/Law', 'ecco3/June2010Update/LitAndLang',
		'ecco3/June2010Update/MedSciTech', 'ecco3/June2010Update/RelAndPhil', 'ecco3/June2010Update/SSFineArts' ]

	folders.each { |folder|
		full_path = base_path + folder + '/XML/' + id + ".xml"
		if File.exists?(full_path)
			return full_path
		end
	}
	return nil
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


