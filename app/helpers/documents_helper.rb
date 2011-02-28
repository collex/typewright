module DocumentsHelper
	def create_url(doc_id, page)
		return "/document/#{doc_id}/edit&page=#{page}"
	end
end
