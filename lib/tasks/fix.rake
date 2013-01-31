namespace :fix do
	desc "Read the original XML files to get the number of pages in each document and cache that value."
	task :add_total_pages => :environment do
		documents = Document.all
		documents.each { |doc|
			num_pages = doc.get_num_pages()
			doc.update_attributes!({ total_pages: num_pages })
		}
	end

end
