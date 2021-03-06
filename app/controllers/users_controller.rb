class UsersController < ApplicationController
	# GET /users.xml
	def index
		federation = params[:federation]
		orig_id = params[:orig_id]
		users = User.find_all_by_federation_and_orig_id(federation, orig_id)

		respond_to do |format|
			format.xml  { render :xml => users }
		end
	end

	# POST /users.xml
	def create
		@user = User.new(params[:user])

		respond_to do |format|
			if @user.save
				format.xml  { render :xml => @user, :status => :created, :location => @user }
			else
				format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
			end
		end
	end

	def corrections
		if PRIVATE_TOKEN != params[:private_token]
			render text: {"message" => "401 Unauthorized"}.to_json(), status: :unauthorized
		else
			orig_id = params[:id]
			federation = params[:federation]
			resp = Corrections.user_corrections(federation, orig_id)
			render text: resp.to_json()
		end
	end

	def test_exception_notifier
		raise "This is only a test of the automatic notification system."
	end
end
