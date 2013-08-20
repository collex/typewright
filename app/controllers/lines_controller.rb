class LinesController < ApplicationController
	# GET /lines.xml
	def index
		lines = []
		src = params[:src].blank? ? :gale : params[:src].to_sym
		if params[:revisions] == 'true'
			uri = params[:uri]
			doc = Document.find_by_uri(uri)
			if doc
				id = doc.id
				lines = Line.find_all_by_document_id_and_src(id, src)
				lines = lines.sort do |a,b|
					if a.page == b.page
						if a.line == b.line
							a.updated_at <=> b.updated_at
						else
							a.line <=> b.line
						end
					else
						a.page <=> b.page
					end
				end
				start = params[:start]
				size = params[:size]
				lines = lines[start.to_i,size.to_i]
			end
		else
			document_id = params[:document_id]
			page = params[:page]
			line = params[:line]
			if line
				lines = Line.find_all_by_document_id_and_page_and_line_and_src(document_id, page, line, src)
			else
				lines = Line.find_all_by_document_id_and_page_and_src(document_id, page, src)
			end
		end

		lines2 = []
		if lines.present?
  		lines.each do | ln |
  		  if ln.user_id > 0
    			user = User.get(ln.user_id)
    			w = ln.words
    			if params[:revisions] == 'true'
    				if w == nil || w.length == 0
    					w = "0\t0\t0\t0\t1\tLine #{ln.status}"
    				end
    			end
    			lines2.push({ :id => ln.id, :federation => user.federation, :orig_id => user.orig_id, :updated_at => ln.updated_at, :page => ln.page,
    				 :line => ln.line, :src => ln.src, :status => ln.status, :words =>w, :document_id => ln.document_id })
    	  end
  		end 
    end
		
		respond_to do |format|
			format.xml  { render :xml => lines2 }
		end
  end

	# POST /lines.xml
	def create
		@line = Line.new(params[:line])
    src = params[:src]
    src = :gale if src.nil?
		# Can no longer send symbols through the web service
    @line.src = src.to_s

		respond_to do |format|
			if @line.save
				format.xml  { render :xml => @line, :status => :created, :location => @line }
			else
				format.xml  { render :xml => @line.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /lines/1.xml
	def destroy
		@line = Line.find(params[:id])
		@line.destroy

		respond_to do |format|
			format.xml  { head :ok }
		end
	end
end
