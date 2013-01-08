class PageReport < ActiveRecord::Base

  belongs_to :document
  belongs_to :user
  attr_accessible :document_id, :page, :reportText, :user_id, :fullname, :email

  #def get_document
  #  return Document.find(self.document_id)
  #end
  
end
