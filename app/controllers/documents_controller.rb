class DocumentsController < ApplicationController
	def find_doc(params)
		id = params[:id]
		if id
			doc = Document.find_by_id(id)
			doc = Document.find_by_uri(id) if doc == nil
		else
			uri = params[:uri]
			doc = Document.find_by_uri(uri)
		end
		return doc
	end

	# GET /documents.xml
	def index
		doc = find_doc(params)
    page = params[:page]
    if doc.nil?
      # nothing found
      result = []

    elsif params[:wordstats] == 'true'
      # looking for word stats for doc or for page
      if page.nil?
        result = [ doc.get_doc_word_stats() ]
      else
        result = [ doc.get_page_word_stats(page) ]
      end

    elsif params[:stats] == 'true'
      # looking for document stats
      result = [ doc.get_doc_stats(doc.id) ]

    elsif !page.nil?
      # looking for info on a particular page of the document
      result = [ doc.get_page_info(page) ]
      
    else
      # looking for info on the document as a whole
      result = [ doc.get_doc_info() ]
    end

	  respond_to do |format|
		format.xml  { render :xml => result }
	  end
	end

	# GET /documents/1.xml
#	def show
#		doc = find_doc(params)
#
#		if params[:stats] == 'true' && doc != nil
#			changes = Line.num_pages_with_changes(doc.id)
#			ret = { :pages_with_changes => changes }
#		else
#			ret = doc
#		end
#
#		respond_to do |format|
#		  format.xml  { render :xml => ret }
#		end
#	end

  # GET /documents/1/edit
#	def edit
#		# This goes to the editing page of a particular document
#		document_id = params[:id]
#		doc = Document.find_by_id(document_id)
#		if doc == nil
#			redirect_to :back
#		else
#			page = params[:page]
#
#			@params = doc.setup_page(page)
#			@user = session[:user]
#			@debugging = session[:debugging] ? session[:debugging] : false
#		end
#	end

	# POST /documents.xml
	def create
		@document = Document.new(params[:document])

		respond_to do |format|
			if @document.save
				format.xml  { render :xml => @document, :status => :created, :location => @document }
			else
				format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
			end
		end
	end

	# PUT /documents/1.xml
#	def update
#		# this is called whenever the user corrects a line.
#		doc_id = params[:id]
#		page = params[:page]
#		line = params[:line].to_f if params[:line]
#		user_id = params[:user].to_i if params[:user]
#		status = params[:status]
#		words = params[:words]
#		if doc_id == nil || page == nil || line == nil || user_id == nil || status == nil
#			render :text => 'Illegal parameters.', :status => :bad_request
#		else
#			rec = Line.get_undoable_record(doc_id, page, line, user_id)
#			if rec
#				rec.destroy()
#			end
#			if status != 'undo'
#				Line.create({ :user_id => user_id, :document_id => doc_id, :page => page, :line => line, :status => status, :words => Line.words_to_db(words) })
#			end
#
#			render :text => ""
#		end
#	end

	# DELETE /documents/1.xml
#	def destroy
#		# this actually passes through to the user_doc. It doesn't destroy this document, but just the
#		# user's connection to it.
#		doc = Document.find_by_uri(params[:id])
#		user = User.find_by_federation_and_orig_id(params[:federation], params[:user_id])
#		if (doc && user)
#			@user_doc = DocumentUser.find_by_user_id_and_document_id(user.id, doc.id)
#			@user_doc.destroy if @user_doc
#		end
#		redirect_to :index
#	end
end
