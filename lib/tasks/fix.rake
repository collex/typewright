namespace :fix do
	desc "Read the original XML files to get the number of pages in each document and cache that value."
	task :add_total_pages => :environment do
		documents = Document.all
		documents.each { |doc|
			info = doc.get_doc_info()
			doc.update_attributes!({ total_pages: info['num_pages' ]})
		}
	end

end
