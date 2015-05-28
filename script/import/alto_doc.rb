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


# Generae primary XML. Just title and pages
#
def generate_primary_xml( doc )
   
   # generate a list of paths to xml files for each page
   pages = []
   (1..doc.total_pages).each do | num |
      pages << File.basename( doc.get_document_page_xml_file( doc.id, num, :alto ) )
   end

   # Create the XML document this binds all of theses pages together with a title
   doc = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset( 'book', nil, 'book.dtd' )
      xml.book {
         xml.bookInfo {
            xml.documentId "#{doc.id}"
         }
         xml.citation {
            xml.titleGroup {
               xml.fullTitle "#{doc.title}"
            }
         }
         xml.text_ {
            pages.each do |pg|
               xml.page( :fileRef => pg )
            end
         }
      }
   end
   
   # Dump the file to TW filesystem
   xml_file = doc.get_primary_xml_file()
   File.open( xml_file, "w" ) { |f| f.write( doc.to_xml ) }
   puts "Write pimary XML file #{xml_file}"
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
info = get_doc_info(directory)
curl_cmd = "-F \"uri=#{info[:uri]}\" -X GET #{server}/documents/exists.xml"
raw_response = do_curl_command(curl_cmd, verbose_output, false)
response = parse_exists_response(raw_response)
puts response if verbose_output

# No record, create it
if response[:exists] == false
   
   # if this is EEBO, create the doc, copy images and create the primary XML.
   # Otherwise bail
   if !doc_info[:eebo_dir].nil? && !doc_info[:eebo_dir].empty?
      puts "INFO: Document #{info[:uri]} does not exist. Creating new record"
      doc = Document.new()
      doc.uri = info[:uri]
      doc.total_pages = page_list.length
      doc.title =   info[:title]
      if !doc.save
         puts "ERROR: Unable to create document record: #{doc.full_messages.to_sentence} ** SKIPPING **"
         exit(1)
      end
      puts "INFO: Document #{info[:uri]} created"

      # Grab the path to the 1st page of XML and use
      # this to figure out the root directory for this document
      xml_page_file = doc.get_page_xml_file(1, :alto)
      root_path = xml_page_file.split("/xml")[0]
      tw_image_path = File.join(root_path, "img").to_s
      if !Dir.exists? tw_image_path
         Dir.mkdir tw_image_path
      end
      
      # switch over to the EEBO image dir copy all tiffs to TW
      Dir.chdir( doc_info[:eebo_dir] )
      img_cnt = 0
      Dir.glob("*") do |f|
         if f.end_with?( ".tif", ".TIF" )
            src_img = File.join(Dir.pwd,f).to_s 
            puts "INFO: Copy #{src_img} to #{tw_image_path}"
            FileUtils.cp(src_img, tw_image_path )
            img_cnt += 1
         end
      end
      Dir.chdir(original_dir)

      # Warn if image count / page count mismatch
      if img_cnt != doc.total_pages
         puts "WARNING: Document #{info[:uri]} has #{doc.total_pages} pages and #{img_cnt} page images."
      end
      
      # Last; create the primary XML file for this document
      puts "INFO: Create primary XML file"
      generate_primary_xml(doc)
      puts "INFO: Document creation success"
   else
      puts "WARNING: Document #{info[:uri]} does not exist. ** SKIPPING **"
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
