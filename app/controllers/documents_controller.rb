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
      # Called by Typewright::Document#get_page, and other places.
      # When it is called by get_page, it includes a user_id. That is the
      # call that happens when the page is opened for editing.
      doc = find_doc(params)
      page = params[:page]
      #src = params[:src].to_sym unless params[:src].nil?
      #src = :gale if src.nil?
      include_word_stats = params[:wordstats].nil? ? false : true
      if doc.nil?
         # nothing found
         result = []

      elsif params[:stats] == 'true'
         # looking for document stats
         result = [ doc.get_doc_stats(doc.id, include_word_stats ) ]

      elsif !page.nil?
         # looking for info on a particular page of the document
         result = [ doc.get_page_info(page, include_word_stats) ]

      else
         # looking for info on the document as a whole
         result = [ doc.get_doc_info( ) ]
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

	def unload
		token = params[:token]
		CurrentEditor.unload(token)
		respond_to do |format|
			format.xml  { head :ok }
		end
	end

  def update
    doc = Document.find(params[:id])
    doc.status = params[:document][:status]
    if doc.save
      # see if there are any lines marked with corrections
      # on a document that has just been tagged as user complete
      if doc.status == 'user_complete'
        if Line.where(document_id: doc.id).count == 0
          # none present, add a 'fake' edit from user 0 on page/line 0
          # this lets the document show up in the TW admin overview reports
          # but retain the 0% corrected status
          sys_edit = Line.new
          sys_edit.user_id = 0
          sys_edit.status = 'auto'
          sys_edit.document_id = doc.id
          sys_edit.page = 0
          sys_edit.line = 0
          sys_edit.src = 'gale'
        sys_edit.save
        end
      elsif doc.status == 'not_complete'
        # when status goes to not complete, remove any fake edits
        # that may have been created above
        Line.where(document_id: doc.id, user_id: 0).destroy_all
      end
      render :xml => doc, :status => :ok
    else
      render :xml => doc.errors, :status => :unprocessable_entity
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
      @document = Document.find(id)
      @document.import_page_ocr(page_num, xml_file.tempfile )
      @id = @document.id
      @edits = @document.corrections_exist?( @document.id, page_num, :gale )  # assume we are asking for gale corrections
      @page_num = page_num + 1
    end
  end

  # Get the overview report for document and user admin pages
  #
  def corrections
    if !check_auth()
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
        resp = Corrections.docs(page, page_size, params[:sort], params[:order], params[:filter], params[:status_filter])
      end
      render text: resp.to_json()
    end
  end

  # Get a typewright document in the specified format. Requires authorization token
  #
  def retrieve 
    if !check_auth()
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
        when 'alto'
          render :text => doc.get_corrected_alto_xml()
        when 'tei-a'
          render :text => doc.get_corrected_tei_a(false)
        when 'tei-a-words'
          render :text => doc.get_corrected_tei_a(true)
        when 'original-gale'
          render :text => doc.get_original_gale_xml()
        when 'original-text'
          render :text => doc.get_original_gale_text()
        when 'original-alto'
          render :text => doc.get_original_alto_xml()
        end
      else
        render text: { "message" => "Document #{uri} not found" }.to_json(), status: :not_found
      end
    end
  end

  # PUT /documents/1/delete_corrections
  def delete_corrections
    if !check_auth()
      render text: { "message" => "401 Unauthorized" }.to_json(), status: :unauthorized
    else
      doc = find_doc(params)
      page = params[:page]
      src = params[:src].to_sym unless params[:src].nil?
      src = :gale if src.nil?
      if doc.nil? == false
        if page.nil? == false
           doc.delete_corrections( doc.id, page, src )
           render text: {"message" => "Corrections deleted"}.to_json(), status: :ok
        else
          render text: { "message" => "Page not specified" }.to_json(), status: :unprocessable_entity
        end
      else
        id = params[:id]
        uri = params[:uri]
        render text: { "message" => "Document #{uri.nil? ? id : uri} not found" }.to_json(), status: :not_found
      end
    end
  end

  # # GET /documents/export_corrected_text?uri=lib://{source_id}/{book_id}
  # def export_corrected_text()
  #   if !check_auth()
  #     render text: "Unauthorized", status: :unauthorized
  #     return
  #   end
  #   @document = find_doc(params)
  #   if @document.present?
  #     render :text => @document.get_corrected_text()
  #   else
  #     render text: "Document not found", status: :not_found
  #   end
  # end
  #
  #  # GET /documents/export_corrected_gale_xml?uri=lib://{source_id}/{book_id}
  # def export_corrected_gale_xml()
  #   if !check_auth()
  #     render text: "Unauthorized", status: :unauthorized
  #     return
  #   end
  #   @document = find_doc(params)
  #   if @document.present?
  #     render :text => @document.get_corrected_gale_xml()
  #   else
  #     render text: "Document not found", status: :not_found
  #   end
  # end
  #
  # # GET /documents/export_corrected_tei_a?uri=lib://{source_id}/{book_id}
  # def export_corrected_tei_a()
  #   if !check_auth()
  #     render text: "Unauthorized", status: :unauthorized
  #     return
  #   end
  #   @document = find_doc(params)
  #   if @document.present?
  #     render :text => @document.get_corrected_tei_a()
  #   else
  #     render text: "Document not found", status: :not_found
  #   end
  # end
  #
  # # GET /documents/export_original_gate_xml?uri=lib://{source_id}/{book_id}
  # def export_original_gale_xml()
  #   if !check_auth()
  #     render text: "Unauthorized", status: :unauthorized
  #     return
  #   end
  #   @document = find_doc(params)
  #   if @document.present?
  #     render :text => @document.get_original_gale_xml()
  #   else
  #     render text: "Document not found", status: :not_found
  #   end
  # end
  #
  # # GET /documents/export_original_gate_text?uri=lib://{source_id}/{book_id}
  # def export_original_gale_text()
  #   if !check_auth()
  #     render text: "Unauthorized", status: :unauthorized
  #     return
  #   end
  #   @document = find_doc(params)
  #   if @document.present?
  #     render :text => @document.get_original_gale_text()
  #   else
  #     render text: "Document not found", status: :not_found
  #   end
  # end
  
  private
  def check_auth
    x_auth_key = request.headers['HTTP_X_AUTH_KEY']
    params_token = params[:private_token]
    auth_token = x_auth_key
    auth_token = params_token if x_auth_key.nil? || x_auth_key.blank?  
    return PRIVATE_TOKEN == auth_token
  end

end
