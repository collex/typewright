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
    if doc.nil?
      # nothing found
      result = []

    elsif params[:wordstats] == 'true'
      # looking for word stats for doc or for page
      if page.nil?
        result = [ doc.get_doc_word_stats(src) ]
      else
        result = [ doc.get_page_word_stats(page, src) ]
      end

    elsif params[:stats] == 'true'
      # looking for document stats
      result = [ doc.get_doc_stats(doc.id, src) ]

    elsif !page.nil?
      # looking for info on a particular page of the document
      result = [ doc.get_page_info(page, src) ]
      
    else
      # looking for info on the document as a whole
      result = [ doc.get_doc_info() ]
    end

	  respond_to do |format|
		format.xml  { render :xml => result }
	  end
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

  
  # POST /documents/1/upload
  def upload
    id = params[:id]
    if id.nil?
      # we weren't given an id, we are creating a new document
      @document = Document.new()
      @document.save()
      id = @document.id
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
#        @document.set_uri_from_xml_file(xml_file)
#        @document.save_primary_xml(xml_file)
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

end
