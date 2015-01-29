class AwlController < ApplicationController
   def index
      if !AWL['enabled']
         f = File.open(Rails.root.join("public/404.html"),"r")
         render :text=>f.read, :status=>:not_found and return
      end

      did = params[:doc]

      # save our client ip
      ip_addr = request.remote_ip
      if ip_addr == '::1' || ip_addr == '0:0:0:0:0:0:0:1' || ip_addr == '0.0.0.0' || ip_addr == '127.0.0.1'
         ip_addr = 'localhost'
      end
      @ip = ip_addr

      # create the authentication token
      secret_key = AWL['shared_secret']
      user_name = "collex"# hardcoded, change to use actual username
      auth_token = create_auth_token(ip_addr, user_name, secret_key)

      # figure out the target url
      @use_debug = 0
      @target_url = "#{AWL['url']}Did=#{did}&Aid=#{did}.original&Appid=#{AWL['app_id']}&a=#{auth_token}"
   end

   def create_auth_token(ip, user_name, secret_key)
      time_now = Time.now.to_i

      @token = "{\"ip\":\"#{ip}\",\"ts\":\"#{time_now}\",\"uid\":\"#{user_name}\"}"

      # now encrypt the token in a way the WebLayoutEditor servlet can read
      # Encrypt with 256 bit AES with CBC
      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cfb8')
      cipher.encrypt # We are encypting
      # The OpenSSL library will generate random keys and IVs
      real_key = Digest::MD5.hexdigest(secret_key)
      cipher.padding = 0
      cipher.key = real_key
      iv = cipher.iv = cipher.random_iv

      encrypted_data = cipher.update(@token) # Encrypt the data.
      encrypted_data << cipher.final
      encrypted_data = "#{iv}#{encrypted_data}"

      @iv = iv
      @sk = real_key.unpack('H*').join
      @step1 = encrypted_data.unpack('H*').join

      encrypted_data = Base64.encode64(encrypted_data)

      @step2 = encrypted_data

      encrypted_data = CGI::escape(encrypted_data)
      return encrypted_data
   end

   def attachment_permissions
      uid = params[:uid]
      aid = params[:aid]
      did = get_document_id_for_attachment(aid)

      # ALL
      json = { :did => did, :aid => aid,
         :permissions => 'a' }.to_json

      render json: json
   end

   # Returns JSON with source URIs for WebLayoutEditor
   #
   def attachment_sources
      uid = params[:uid]
      aid = params[:aid]
      did = get_document_id_for_attachment(aid)

      attach_type = 'PAGE'
      attach_url = url_for :controller => :awl, :action => :attachment, :id => aid
      doc_type = 'fullview'
      doc_url = url_for :controller => :awl, :action => :fullview, :id => did

      # TODO: for security, add an auth token to the full view url
      json = { :did => did, :aid => aid,
         :attype => attach_type, :aturl => attach_url,
         :viewurl => doc_url, :viewtype => doc_type }.to_json

      render json: json
   end

   def fullview
      # TODO: for security, look for an auth token and check that it is valid
      # FIXME hacked to always return the sample
      path = find_document( "cbil1702_116_1_005") #params[:id])
      if path.nil?
         raise "No document for #{params[:id]} could be found"
      end
      send_file path
   end

   def attachment
      # FIXME
      # HACK for now. Always return the sampled
      aid = "cbil1702_116_1_005.beforecorrections"#params[:id]
      path = "#{Rails.root.to_s}/awl-repo/attachments/#{aid}.xml"
      send_file path, :content_type => "application/xml"
   end

   def get_document_id_for_attachment(aid)
      return aid.split('.', 2).first
   end

   def find_document(id)
      path = nil
      files = Dir.glob("#{Rails.root.to_s}/awl-repo/fullview/*")
      files.each do |file|
         temp_id = File.basename(file, File.extname(file))
         if temp_id == id
         path = file
         break
         end
      end
      return path
   end
end