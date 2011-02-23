class DocumentsController < ApplicationController
	# GET /documents
	# GET /documents.xml
	def index
		# this is a web service that gets a list of a user's documents
		federation = params[:federation]
		orig_id = params[:user_id]
		user = User.get_user(federation, orig_id)
		if user == nil
			render :text => ''
		else
			docs = UserDoc.find_all_by_user_id(user.id)
			if docs.length == 0
				render :text => ''
			else
				str = ''
				docs.each { |ud|
					doc = Document.find_by_id(ud.document_id)
					str += "#{doc[:uri]}\t#{doc.thumb()}\t#{doc[:title]}\n"
				}
				render :text => str
			end
		end
	end

	# GET /documents/1
	# GET /documents/1.xml
	def show
		# This goes to the main page of a particular document.
		federation = params[:federation]
		orig_id = params[:user_id]
		@user = User.get_or_create_user(federation, orig_id)
		session[:user] = @user

		@uri = params[:uri]
		title = params[:title]
		doc = Document.find_by_uri(@uri)
		if doc == nil
			doc = Document.create({ :uri => @uri, :title => title })
		end
		@id = doc.id
		@title = doc[:title]

		ud = UserDoc.find_by_user_id_and_document_id(@user.id, @id)
		if ud == nil
			UserDoc.create({ :user_id => @user.id, :document_id => @id })
		end
		@thumb = doc.thumb()
	end

	# GET /documents/new
	# GET /documents/new.xml
#  def new
#    @document = Document.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @document }
#    end
#  end

  # GET /documents/1/edit
  def edit
	  # This goes to the editing page of a particular document
	@uri = params[:uri]
  end

	# POST /documents
	# POST /documents.xml
#  def create
#    @document = Document.new(params[:document])
#
#    respond_to do |format|
#      if @document.save
#        format.html { redirect_to(@document, :notice => 'Document was successfully created.') }
#        format.xml  { render :xml => @document, :status => :created, :location => @document }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
#      end
#    end
#  end

	# PUT /documents/1
	# PUT /documents/1.xml
	def update
		# This receives notifications of changes from the user's interaction with the web page.
		@document = Document.find(params[:id])

		respond_to do |format|
			if @document.update_attributes(params[:document])
				format.html { redirect_to(@document, :notice => 'Document was successfully updated.') }
				format.xml  { head :ok }
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @document.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /documents/1
	# DELETE /documents/1.xml
	def destroy
		# this actually passes through to the user_doc
		doc = Document.find_by_uri(params[:id])
		user = User.find_by_federation_and_orig_id(params[:federation], params[:orig_id])
		if (doc && user)
			@user_doc = UserDoc.find_by_user_id_and_document_id(user.id, doc.id)
			@user_doc.destroy if @user_doc
			redirect_to :index
		end

#    @document = Document.find(params[:id])
#    @document.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(documents_url) }
#      format.xml  { head :ok }
#    end
	end
end
