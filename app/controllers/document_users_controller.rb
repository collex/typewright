class DocumentUsersController < ApplicationController
	# GET /document_users.xml
	def index
		user_id = params[:user_id]
		document_id = params[:document_id]
		if document_id
			docs = DocumentUser.find_all_by_user_id_and_document_id(user_id, document_id)
		else
			docs = DocumentUser.find_all_by_user_id(user_id)
		end

		respond_to do |format|
			format.xml  { render :xml => docs }
		end
	end

	# POST /document_users.xml
	def create
		@document = DocumentUser.new(params[:document_user])

		respond_to do |format|
			if @document.save
				format.xml  { render :xml => @document, :status => :created, :location => @document }
			else
				format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /document_users/1.xml
	def destroy
		rec = DocumentUser.find(params[:id])
		rec.destroy

		respond_to do |format|
			format.xml  { head :ok }
		end
	end
end
