# Get eMOP API credentials from settings
#
def get_emop_api_info
  config_file = File.join("config", "site.yml")
  if File.exists?(config_file)
    site_specific = YAML.load_file(config_file)
    url =  site_specific['authentication']['emop_root_url']
    token =  site_specific['authentication']['emop_token']
    return url,token
  end
  raise "Missing site.yml"
end

def get_work_info(work_id)
   # Call the emop API to get details on the work
   base_url, token = get_emop_api_info()
   url = "#{base_url}/works/#{work_id}"
   resp_str = RestClient.get url,  :authorization => "Token #{token}"
   resp = JSON.parse(resp_str)['work']
   if resp['wks_ecco_number'].nil?
      # No ecco number; this is an EEBO document.
      last = resp['wks_eebo_citation_id'].to_s.rjust(10, "0")
      image_id = resp['wks_eebo_image_id'].to_i
      first = resp['wks_eebo_image_id'].rjust(10, "0")
      unique = "#{first}-#{last}"
      uri = "lib://EEBO/#{unique}"
   else
      # Found ECCO number. Must be ECCO document; generate the URI
      uri = "lib://ECCO/#{resp['wks_ecco_number']}"
   end
   out = {:uri=>uri, :title=>resp['wks_title']}
   return out
end

# Extract the document URI/Title from file and emop API
#
def get_doc_info(doc_path)
   # path follws a rigid directory structure:
   #    /data/shared/text-xml/IDHMC-ocr/[batch_id]/[emop_work_id]
   # Use this to get the work ID
   bits = xml_file.split("/")
   work_id = bits[bits.length-1]
   return get_work_info(work_id) 
end

# Extract the URI from the page file path and eMOP API
#
def get_doc_uri(xml_file)
   # file follws a rigid directory structure:
   #    /data/shared/text-xml/IDHMC-ocr/[batch_id]/[emop_work_id]/[page]_ALTO.xml
   # Use this to get the work ID
   bits = xml_file.split("/")
   work_id = bits[bits.length-2]
   
   info = get_work_info(work_id) 
   return info[:uri]   
end

# Execute a CURL command and return results
#
def do_curl_command(cmd, verbose, test_only)
  puts "" if verbose
  puts "curl #{cmd} 2>&1" if verbose
  return '' if test_only
  resp = `curl #{cmd} 2>&1`
  puts resp if verbose
  return resp
end

# Parse XML respose to determine if document exists
#
def parse_exists_response(response)
  result = {}
  doc_id_str = response[/<id>\d+<\/id>/]
  result[:doc_id] = 0
  result[:doc_id] = doc_id_str[4..-6].to_i unless doc_id_str.nil?
  exists_str = response[/<exists>\D+<\/exists>/]
  result[:exists] = (exists_str[8..11] == 'true')
  return result
end