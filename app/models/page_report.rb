class PageReport < ActiveRecord::Base

  belongs_to :document

  #def get_document
  #  return Document.find(self.document_id)
  #end
  
end
