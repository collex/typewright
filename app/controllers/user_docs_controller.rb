class UserDocsController < ApplicationController
  # GET /user_docs
  # GET /user_docs.xml
  def index
	  federation = params[:federation]
	  orig_id = params[:user]
	  user = User.find_all_by_federation_and_orig_id(federation, orig_id)
	  if user == nil
		  render :text => ''
	  else
		  docs = UserDoc.find_all_by_user_id(user.id)
		  if docs.length == 0
			  render :text => ''
		  else
			  str = ''
			  docs.each { |doc|
				  str += doc[:doc] + "\n"
			  }
			  render :text => str
		  end
	  end
#    @user_docs = UserDoc.find_all_by_federation_and_
#
#    respond_to do |format|
#      format.html # index.html.erb
#      format.xml  { render :xml => @user_docs }
#    end
  end

  # GET /user_docs/1
  # GET /user_docs/1.xml
#  def show
#    @user_doc = UserDoc.find(params[:id])
#
#    respond_to do |format|
#      format.html # show.html.erb
#      format.xml  { render :xml => @user_doc }
#    end
#  end
#
#  # GET /user_docs/new
#  # GET /user_docs/new.xml
#  def new
#    @user_doc = UserDoc.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @user_doc }
#    end
#  end
#
#  # GET /user_docs/1/edit
#  def edit
#    @user_doc = UserDoc.find(params[:id])
#  end

  # POST /user_docs
  # POST /user_docs.xml
  def create
    @user_doc = UserDoc.new(params[:user_doc])

    respond_to do |format|
      if @user_doc.save
        format.html { redirect_to(@user_doc, :notice => 'User doc was successfully created.') }
        format.xml  { render :xml => @user_doc, :status => :created, :location => @user_doc }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user_doc.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /user_docs/1
  # PUT /user_docs/1.xml
#  def update
#    @user_doc = UserDoc.find(params[:id])
#
#    respond_to do |format|
#      if @user_doc.update_attributes(params[:user_doc])
#        format.html { redirect_to(@user_doc, :notice => 'User doc was successfully updated.') }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @user_doc.errors, :status => :unprocessable_entity }
#      end
#    end
#  end
#
#  # DELETE /user_docs/1
#  # DELETE /user_docs/1.xml
#  def destroy
#    @user_doc = UserDoc.find(params[:id])
#    @user_doc.destroy
#
#    respond_to do |format|
#      format.html { redirect_to(user_docs_url) }
#      format.xml  { head :ok }
#    end
#  end
end
