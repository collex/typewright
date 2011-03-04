class LinesController < ApplicationController
	# GET /lines.xml
	def index
	  document_id = params[:document_id]
	  page = params[:page]
	  lines = Line.find_all_by_document_id_and_page(document_id, page)

    respond_to do |format|
      format.xml  { render :xml => lines }
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
