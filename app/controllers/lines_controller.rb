class LinesController < ApplicationController
	# GET /lines.xml
	def index
		# called by Typewright::Line.get_undoable_record [ not passing :revisions ]
		# called when showing the main page for a document [ passing :revisions ]
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

		lines = format_lines(lines, params[:revisions])

		respond_to do |format|
			format.xml  { render :xml => lines }
		end
  end

	# GET /lines/ping.xml
	def ping
		document_id = params[:document_id]
		page = params[:page]
		user_id = params[:user_id]
		token = params[:token]
		load_time = params[:load_time]
		ret = ping_processing(token, document_id, page, user_id, false, load_time)
		respond_to do |format|
			format.json  { render :json => ret }
		end
	end

	# POST /lines.xml
	def create
		# called when a line is modified.
		token = params[:line]['token']
		params[:line].delete('token')
		@line = Line.new(params[:line])
		src = params[:src]
		src = :gale if src.nil?
		# Can no longer send symbols through the web service
		@line.src = src.to_s
		line = @line.attributes.to_options!
		ret = ping_processing(token, @line.document_id, @line.page, @line.user_id, params[:revisions], nil)
		line[:changes] = ret[:lines]
		line[:editors] = ret[:editors]

		respond_to do |format|
			if @line.save
				line[:updated_at] = @line.updated_at.getlocal.strftime("%b %e, %Y %I:%M%P")
				line[:exact_time] = @line.updated_at.getlocal.strftime("%s")
				format.xml { render :xml => line, :status => :created, :location => @line }
			else
				format.xml { render :xml => @line.errors, :status => :unprocessable_entity }
			end
		end
	end

	# DELETE /lines/1.xml
	def destroy
		# called when a line is modified, but it had already been modified by that user.
		@line = Line.find(params[:id])
		@line.destroy

		respond_to do |format|
			format.xml  { head :ok }
		end
	end

	private

	def ping_processing(token, document_id, page, user_id, is_revisions, load_time)
		begin
			load_time = Time.parse(load_time)
			load_time = load_time.utc
		rescue
		end
		since = CurrentEditor.since(token, document_id, page, user_id, load_time)
		lines = Line.since(document_id, page, since)
		editors = CurrentEditor.editors(token, document_id, page)
		lines = format_lines(lines, is_revisions)
		lines = lines.map { |line|
			{
				id: line[:id],
				federation: line[:federation],
				orig_id: line[:orig_id],
				page: line[:page],
				line: line[:line],
				action: line[:status],
				date: line[:updated_at].getlocal.strftime("%b %e, %Y %I:%M%P"),
				exact_time: line[:updated_at].getlocal.strftime("%s"),
				words: line[:words]
			}
		}

		return { lines: lines, editors: editors }
	end

	def format_lines(lines, is_revisions)
		lines2 = []
		if lines.present?
			lines.each { | ln |
				if ln.user_id > 0
					user = User.get(ln.user_id)
					w = ln.words
					if is_revisions == 'true'
						if w == nil || w.length == 0
							w = "0\t0\t0\t0\t1\tLine #{ln.status}"
						end
					end
					lines2.push({ :id => ln.id, :federation => user.federation, :orig_id => user.orig_id, :updated_at => ln.updated_at, :page => ln.page,
								  :line => ln.line, :src => ln.src, :status => ln.status, :words =>w, :document_id => ln.document_id })
				end
			}
		end
		return lines2
	end
end
