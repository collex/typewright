class PageReport < ActiveRecord::Base

  belongs_to :document
  attr_accessible :document_id, :page, :reportText

  #def get_document
  #  return Document.find(self.document_id)
  #end
  
end
