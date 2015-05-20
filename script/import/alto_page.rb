#!/usr/bin/env ruby
require "#{Dir.pwd}/app/models/xml_reader.rb"

# upload xml file for a book page

def do_usage()
  puts "Usage: alto_page [flags] server /path/to/xml_file.xml"
  puts "Import ALTO ocr for a page into specified TypeWright server."
  puts "If the book does not exist, issue error."
  puts " -v Verbose output"
  puts " -t Test only -- don't actually upload files"
  puts " -c Output the curl commands that would have been executed."
end

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

# Extract the URI from the page file path and eMOP API
#
def get_doc_uri(xml_file)
   # file follws a rigid directory structure:
   #    /data/shared/text-xml/IDHMC-ocr/[batch_id]/[emop_work_id]/[page]_ALTO.xml
   # Use this to get the work ID
   bits = xml_file.split("/")
   work_id = bits[bits.length-2]
   
   # Now call the emop API to get details on the work
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
      out = "lib://EEBO/#{unique}"       
   else
      # Found ECCO number. Must be ECCO document; generate the URI
      out = "lib://ECCO/#{resp['wks_ecco_number']}"
   end
   return out   
end


def do_curl_command(cmd, verbose, test_only)
  puts "" if verbose
  puts "curl #{cmd} 2>&1" if verbose
  return '' if test_only
  resp = `curl #{cmd} 2>&1`
  puts resp if verbose
  return resp
end

def parse_exists_response(response)
  result = {}
  doc_id_str = response[/<id>\d+<\/id>/]
  result[:doc_id] = 0
  result[:doc_id] = doc_id_str[4..-6].to_i unless doc_id_str.nil?
  exists_str = response[/<exists>\D+<\/exists>/]
  result[:exists] = (exists_str[8..11] == 'true')
  return result
end

def parse_upload_response(response)
  result = {}
  doc_id_str = response[/<id>\d+<\/id>/]
  result[:doc_id] = 0
  result[:doc_id] = doc_id_str[4..-6].to_i unless doc_id_str.nil?
  exists_str = response[/<exists>\D+<\/exists>/]
  result[:exists] = (exists_str[8..11] == 'true')
  auth_token_str = response[/<auth_token>\S*<\/auth_token>/]
  edits_str = response[/<edits>\D+<\/edits>/]
  result[:edits] = (edits_str[7..10] == 'true')
  result[:auth_token] = auth_token_str[12..-14]
  uri_str = response[/<uri>\S*<\/uri>/]
  result[:uri] = uri_str[5..-7]
  return result
end

# start by reading our input parameters
VALID_OPTION_FLAGS = %w( v t c )
VALID_OPTIONS = %w( )

if ARGV.size < 2
  do_usage()
  exit(1)
end

server = ''
xml_file = ''
option_flags = []
options = {}
ret_value = []

ARGV.each do |arg|
   next if arg == "--"
   if arg[0..0] == '-'  # if I don't do [0..0] I get an int rather than a string
      if arg =~ /=/
         arg_name = arg[1..99].split("=")[0]
         if VALID_OPTIONS.index(arg_name) == nil
            puts "WARNING: Ignoring unknown parameter: #{arg_name} (#{arg})"
         else
            options[arg_name] = arg[arg_name.size+2..999]
         end
      else
         arg_name = arg[1..99]
         if VALID_OPTION_FLAGS.index(arg_name) == nil
            puts "WARNING: Ignoring unknown parameter: #{arg}"
         else
            option_flags << arg_name
         end
      end
   elsif server.empty?
      server = arg
   elsif xml_file.empty?
      xml_file = arg
   else
      puts "WARNING: Ignoring unknown parameter: '#{arg}'"
   end
end

verbose_output = !option_flags.index('v').nil?
test_only = !option_flags.index('t').nil?
output_curl_only = !option_flags.index('c').nil?

# Verify that file exists and can be parsed
if File.exists?( xml_file ) == false
  puts "ERROR: #{xml_file} does not exist or is not readable"
  exit(1)
end

xml_doc = XmlReader.open_xml_file(xml_file)
if xml_doc.nil?
  puts "ERROR: couldn't open XML file [#{xml_file}]"
  exit(1)
end

# Extract the URI for the work from the path and eMOP API
doc_uri = get_doc_uri(xml_file)

# now that we have all the parameters, determine if the book exists
curl_cmd = "-F \"uri=#{doc_uri}\" -X GET #{server}/documents/exists.xml"
raw_response = do_curl_command(curl_cmd, verbose_output, false)
response = parse_exists_response(raw_response)
puts response if verbose_output

# check to see if it exists; if not, bail out
if response[:exists] == false
   puts "Book for #{xml_file} does not exist -skipped- (DONE)" if !output_curl_only
   exit(0)
end

doc_id = response[:doc_id]

# determine the page number
page_num = 0
page_num_str = File.basename( xml_file )[/\d+_alto\.xml/i]
page_num = page_num_str[0..-9].to_i unless page_num_str.nil?

# upload the xml file
curl_cmd = "-F \"xml_file=@#{xml_file};type=text/xml\" -F \"page=#{page_num}\" -X POST #{server}/documents/#{doc_id}/update_page_ocr.xml"
if output_curl_only
	ret_value.push("curl #{curl_cmd} 2>&1")
else
	raw_response = do_curl_command(curl_cmd, verbose_output, test_only)
end

response = parse_upload_response(raw_response) unless test_only || output_curl_only
puts response if verbose_output
puts "#{xml_file} #{File.new(xml_file).size} (DONE)" if !output_curl_only
puts "WARNING: user edits exist for this page" if response[:edits] == true

if output_curl_only
	puts ret_value.map { |line| "#{line}\n"}
end

exit 0