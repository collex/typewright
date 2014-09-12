namespace :generate do

  desc "Create fake EEBO OCR documents for import (workid=num$num)"
  task :fake_eebo, [:workid] => :environment do |t, args|

    fake_eebo_root = "/tmp/fakeEEBO"
    fake_page_xml = "data/example_alto.xml"

    require "#{Rails.root}/app/models/work.rb"

    workids = args[:workid]
    workids = workids.split("$")
    workids.each { |work_id|
      work_item = Work.find( work_id )
      if work_item.nil?
        puts "ERROR: cannot locate work item for #{work_id}"
        next
      end

      if work_item.isEEBO? == false
        puts "ERROR: not an EEBO document for work item for #{work_id}"
        next
      end

      uri = "lib://EEBO/#{sprintf( "%010d", work_item.wks_eebo_image_id.to_i )}-#{sprintf( "%010d", work_item.wks_eebo_citation_id)}"
      puts "Creating fake EEBO OCR for #{uri}"

      images = Dir.glob( "#{work_item.wks_eebo_directory}/*.tif")
      puts "Located #{images.size} pages"
      target_dir = "#{fake_eebo_root}/#{work_id}/0"
      FileUtils.mkdir_p( target_dir ) unless FileTest.directory?( target_dir )

      images.each_with_index { |img_name, ix|
        target_name = "#{target_dir}/#{ix + 1}.xml"
        FileUtils.rm( target_name, { :force => true } ) if FileTest.file?( target_name )
        content = ""
        File.open( fake_page_xml, "r" ) { |f|
          content = f.read
        }
        content.gsub!( "XX_FILENAME_XX", File.basename( img_name ) )
        File.open( target_name, "w" ) { |f|
          f << content
        }
      }
      puts "Pages located here: #{target_dir}"
    }

  end

end


