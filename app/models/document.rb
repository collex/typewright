class Document < ActiveRecord::Base
	def thumb()
		gale_num = self.uri.split('/').last
		return "http://ocr.performantsoftware.com/data/#{gale_num}/images/#{gale_num}00010.png"
	end

	def title_abbrev()
		t = self.title
		return t if t.length < 32
		return t.slice(0..30)+'...'
	end
end
