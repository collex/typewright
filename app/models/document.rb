class Document < ActiveRecord::Base
	def thumb()
		gale_num = self.uri.split('/').last
		return "http://ocr.performantsoftware.com/data/#{gale_num}/images/#{gale_num}00010.png"
	end
end
