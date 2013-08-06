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
    src = params[:src].to_sym unless params[:src].nil?
    src = :gale if src.nil?
    include_word_stats = params[:wordstats].nil? ? false : true
    if doc.nil?
      # nothing found
      result = []

    elsif params[:stats] == 'true'
      # looking for document stats
      result = [ doc.get_doc_stats(doc.id, include_word_stats, src) ]

    elsif !page.nil?
      # looking for info on a particular page of the document
      result = [ doc.get_page_info(page, include_word_stats, src) ]
      
    else
      # looking for info on the document as a whole
      result = [ doc.get_doc_info() ]
    end

		# Can no longer send symbols through the web service
		result.each { |res|
			if res[:lines].present?
				res[:lines].each { |line|
					line[:src] = line[:src].to_s if line[:src].present?
				}
			end
		}

	  respond_to do |format|
		format.xml  { render :xml => result }
	  end
	end
	
	def update
	 doc = Document.find(params[:id])
	 if doc.status == 'not_complete'
  	 doc.status = params[:document][:status]
  	 respond_to do |format|
        if doc.save
          format.xml  { render :xml => doc, :status => :ok}
        else
          format.xml  { render :xml => doc.errors, :status => :unprocessable_entity }
        end
      end
    else
      render :xml => params[:document], :status => :unprocessable_entity
    end
	end

	# GET /documents/{id}/report?page={page}
	def report
		@doc = find_doc(params)
    @page = params[:page]
    @src = params[:src].to_sym unless params[:src].nil?
    @src = :gale if @src.nil?
    @page_report = PageReport.new(:document_id => @doc.id, :page => @page, user_id: params[:user_id], fullname: params[:fullname], email: params[:email])
	end
  

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


  # GET /documents/exists.xml?uri=lib://{source_id}/{book_id}
  def exists
    @document = find_doc(params)
  end

  # POST /documents/1/upload
  def upload
    id = params[:id]
    if id.nil?
      @document = find_doc(params)
      # we weren't given an id, we are creating a new document
      if @document.nil? && params[:nocreate].nil?
          @document = Document.new()
          if !params[:uri].nil?
            @document.uri = params[:uri]
          end
          @document.save()
      end
      @action_params = ''
    else
      # we are modifying a document already created, error out if not found
      @document = Document.find(id)
      # are we uploading a page or are we uploading xml file?
      page_num = params[:page]
      if page_num.nil?
        # uploading xml_file for entire volume
        xml_file = params[:xml_file]

        # save and process the file using the Document Model
        @document.import_primary_xml(xml_file)
        @document.save()
        
        @page_num = 1
      else
        page_num = page_num.to_i
        # uploading a page image
        image_file = params[:image_file]

        # save and process the image file using the Document model
        @document.save_page_image(image_file)
        @document.import_page(page_num, image_file)
        @document.save()

        @page_num = page_num + 1
      end
      @action_params = "?page=#{@page_num}"
    end
    
  end

  # POST /documents/1/update_page_ocr
  def update_page_ocr
    id = params[:id]
    id = nil if id.to_i == 0
    if id.nil?
      # we weren't given an id, we are creating a new document
      @page_num = 1
      @id = nil
    else
      page_num = params[:page].to_i
      xml_file = params[:xml_file]
      src = params[:src]  # (optional src param)
      @document = Document.find(id)
      @document.import_page_ocr(page_num, xml_file.tempfile, src)
      @id = @document.id
      @page_num = page_num + 1
    end
  end

  # Get the overview report for document and user admin pages
  #
	def corrections
		if PRIVATE_TOKEN != params[:private_token]
			render text: {"message" => "401 Unauthorized"}.to_json(), status: :unauthorized
		else
			view = params[:view]
			page = params[:page]
			page_size = params[:page_size]
			page ||= 1
			page_size ||= 10
			if view == 'users'
				resp = Corrections.users(page, page_size, params[:sort], params[:order], params[:filter])
			else
				resp = Corrections.docs(page, page_size, params[:sort], params[:order], params[:filter]) 
			end
			render text: resp.to_json()
		end
	end

	def retrieve
		if PRIVATE_TOKEN != params[:private_token]
			render text: { "message" => "401 Unauthorized" }.to_json(), status: :unauthorized
		else
			uri = params[:uri]
			type = params[:type]
			doc = Document.find_by_uri(uri)
			if doc.present?
				case type
					when 'gale'
						render :text => doc.get_corrected_gale_xml()
					when 'text'
						render :text => doc.get_corrected_text()
					when 'tei-a'
						render :text => doc.get_corrected_tei_a(false)
					when 'tei-a-words'
						render :text => doc.get_corrected_tei_a(true)
					when 'original-gale'
						render :text => doc.get_original_gale_xml()
					when 'original-text'
						render :text => doc.get_original_gale_text()
				end
			else
				render text: { "message" => "Document #{uri} not found" }.to_json(), status: :not_found
			end
		end
	end

  # GET /documents/export_corrected_text?uri=lib://{source_id}/{book_id}
  def export_corrected_text()
    @document = find_doc(params)
    if @document.present?
	    render :text => @document.get_corrected_text()
  else
	  render text: "Document not found", status: :not_found
  end
  end

  # GET /documents/export_corrected_gale_xml?uri=lib://{source_id}/{book_id}
  def export_corrected_gale_xml()
    @document = find_doc(params)
    if @document.present?
	    render :text => @document.get_corrected_gale_xml()
  else
	  render text: "Document not found", status: :not_found
  end
  end

  # GET /documents/export_corrected_tei_a?uri=lib://{source_id}/{book_id}
  def export_corrected_tei_a()
    @document = find_doc(params)
    if @document.present?
	    render :text => @document.get_corrected_tei_a()
  else
	  render text: "Document not found", status: :not_found
  end
  end

  # GET /documents/export_original_gate_xml?uri=lib://{source_id}/{book_id}
  def export_original_gale_xml()
    @document = find_doc(params)
    if @document.present?
	    render :text => @document.get_original_gale_xml()
    else
	    render text: "Document not found", status: :not_found
    end
  end

  # GET /documents/export_original_gate_text?uri=lib://{source_id}/{book_id}
  def export_original_gale_text()
    @document = find_doc(params)
    if @document.present?
	    render :text => @document.get_original_gale_text()
    else
	    render text: "Document not found", status: :not_found
	end
  end

end
