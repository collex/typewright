#!/usr/bin/env ruby
require "#{Dir.pwd}/script/import/common.rb"

def do_usage()
   puts "Usage: alto_doc [flags] server /path/to/directory"
   puts "Import all pages in the given document directory into specified TypeWright server."
   puts "Pages must be in ALTO format."
   puts "If the book does not exist, issue error."
   puts " -v  Verbose output"
   puts " -t  Test only -- don't actually upload files"
end

# start by reading our input parameters

VALID_OPTION_FLAGS = %w( v t )
VALID_OPTIONS = %w( )

if ARGV.size < 1
   do_usage()
   exit(1)
end

server = ''
directory = ''
option_flags = []
options = {}

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
   elsif directory.empty?
      directory = arg
   else
      puts "WARNING: Ignoring unknown parameter: #{arg}"
   end
end

verbose_output = !option_flags.index('v').nil?
test_only = !option_flags.index('t').nil?
cmd_flags = "#{verbose_output ? '-v':''} #{test_only ? '-t':''}"
original_dir = Dir.pwd

# Make sure directory exists...
if !Dir.exist?( directory )
   puts "WARNING: #{directory} does not exist"
   exit( 1 )
end

# ... and has some alto content
Dir.chdir(directory)
page_list = []
Dir.glob("*") do |f|
   page_list << f if f.downcase.end_with?( "_alto.xml" )
end

Dir.chdir(original_dir)

if page_list.empty?
   puts "WARNING: no alto pages located here #{directory}"
   exit( 1 )
end

# Extract the URI for the work from the path and eMOP API and see if a record for it exists
info = get_doc_info(xml_file)
curl_cmd = "-F \"uri=#{info[:uri]}\" -X GET #{server}/documents/exists.xml"
raw_response = do_curl_command(curl_cmd, verbose_output, false)
response = parse_exists_response(raw_response)
puts response if verbose_output

# No record, create it
if response[:exists] == false
   doc = Document.new()
   doc.uri = info[:uri]
   doc.total_pages = page_list.length
   doc.title =   info[:title]
   if !doc.save
      puts "ERROR: Unable to create document record: #{doc.full_messages.to_sentence} ** SKIPPING **"
      exit(1)
   end
end

# process each page we have identified
page_list.sort!
page_list.each do |page|
   xml_file = File.join(directory,page)
   cmd = "script/import/alto_page.rb #{cmd_flags} #{server} #{xml_file}"
   puts "========== #{cmd}"
   result = `#{cmd}`
   puts result
end

exit 0
