class LinesController < ApplicationController
	# GET /lines.xml
	def index
		lines = []
		if params[:revisions] == 'true'
			uri = params[:uri]
			doc = Document.find_by_uri(uri)
			if doc
				id = doc.id
				lines = Line.find_all_by_document_id(id)
				lines = lines.sort { |a,b|
					if a.page == b.page
						if a.line == b.line
							a.updated_at <=> b.updated_at
						else
							a.line <=> b.line
						end
					else
						a.page <=> b.page
					end
				}
				start = params[:start]
				size = params[:size]
				lines = lines[start.to_i,size.to_i]
			end
		else
			document_id = params[:document_id]
			page = params[:page]
			line = params[:line]
			if line
				lines = Line.find_all_by_document_id_and_page_and_line(document_id, page, line)
			else
				lines = Line.find_all_by_document_id_and_page(document_id, page)
			end
		end

		lines2 = []
		lines.each { |line|
			user = User.find_by_id(line.user_id)
			w = line.words
			if params[:revisions] == 'true'
				if w == nil || w.length == 0
					w = "0\t0\t0\t0\t1\tLine #{line.status}"
				end
			end
			lines2.push({ :id => line.id, :federation => user.federation, :orig_id => user.orig_id, :updated_at => line.updated_at, :page => line.page,
				 :line => line.line, :status => line.status, :words =>w, :document_id => line.document_id })
		}
		respond_to do |format|
			format.xml  { render :xml => lines2 }
		end
  end

	# POST /lines.xml
	def create
		@line = Line.new(params[:line])

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
