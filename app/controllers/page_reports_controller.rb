class PageReportsController < ApplicationController
  # GET /page_reports
  # GET /page_reports.xml
  def index
    @page_reports = PageReport.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @page_reports }
    end
  end

  # GET /page_reports/1
  # GET /page_reports/1.xml
  def show
    @page_report = PageReport.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page_report }
    end
  end

  # GET /page_reports/new
  # GET /page_reports/new.xml
  def new
    @page_report = PageReport.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page_report }
    end
  end

  # GET /page_reports/1/edit
  def edit
    @page_report = PageReport.find(params[:id])
  end

  # POST /page_reports
  # POST /page_reports.xml
  def create
    @page_report = PageReport.new(params[:page_report])

    respond_to do |format|
      if @page_report.save
        format.html { redirect_to(@page_report, :notice => 'Page report was successfully created.') }
        format.xml  { render :xml => @page_report, :status => :created, :location => @page_report }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /page_reports/1
  # PUT /page_reports/1.xml
  def update
    @page_report = PageReport.find(params[:id])

    respond_to do |format|
      if @page_report.update_attributes(params[:page_report])
        format.html { redirect_to(@page_report, :notice => 'Page report was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page_report.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /page_reports/1
  # DELETE /page_reports/1.xml
  def destroy
    @page_report = PageReport.find(params[:id])
    @page_report.destroy

    respond_to do |format|
      format.html { redirect_to(page_reports_url) }
      format.xml  { head :ok }
    end
  end
end
