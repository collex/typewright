namespace :fix do
	desc "Read the original XML files to get the number of pages in each document and cache that value."
	task :add_total_pages => :environment do
		documents = Document.all
		documents.each_with_index { |doc, index|
			if doc.total_pages.blank?
				begin
					num_pages = doc.get_num_pages()
				rescue Exception => e
					puts "#{doc.uri}: #{e.to_s}"
				end

				doc.update_attributes!({ total_pages: num_pages })
			end
			print "\n[#{index}]" if index % 100 == 0
			print '.'
		}
	end

	desc "Go through each document in the database and put the title in."
	task :add_title => :environment do
		docs = Document.all
		docs.each_with_index { |doc, index|
			begin
				info = doc.get_doc_info()
			rescue Exception => e
				puts "#{doc.uri}: #{e.to_s}"
				info = nil
			end
			if info.present?
				doc.title = info[:title]
				doc.save!
			end
			print "\n[#{index}]" if index % 100 == 0
			print '.'
		}
	end
	
	desc "Go through each document in the database and see if the title matches Gale"
  task :validate_title => :environment do
    update_count = 0
    docs = Document.all
    docs.each_with_index do |doc, index|
      begin
        info = doc.get_doc_info()
      rescue Exception => e
        puts "#{doc.uri}: #{e.to_s}"
        info = nil
      end
      if info.present? && info[:title] != doc.title
        puts "#{doc.uri}: Title does not match Gale. Updating..."
        doc.title = info[:title]
        doc.save!
        puts "#{doc.uri}: Title updated."
        update_count = update_count +1
      end
      print "\n[#{index}]" if index % 100 == 0
      print '.'
    end
    puts "DONE. Total documents updated: #{update_count}"
  end

	desc "Find usages of null documents in the database"
	task :analyze_null_documents => :environment do
		documents = Document.find_all_by_uri(nil)
		documents.each { |doc|
			du = DocumentUser.find_all_by_document_id(doc.id)
			lines = Line.find_all_by_document_id(doc.id)
			pr = PageReport.find_all_by_document_id(doc.id)
			puts "#{doc.id}: usage: #{du.length} #{lines.length} #{pr.length}"
		}
	end
end