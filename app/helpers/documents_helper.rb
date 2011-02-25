module DocumentsHelper
	def create_url(book, page)
		return "/line?book=#{book}&page=#{page}"
	end
end
