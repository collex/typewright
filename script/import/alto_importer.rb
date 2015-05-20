#!/usr/bin/env ruby

require "#{Dir.pwd}/app/models/page_queue.rb"

def do_usage()
  puts "Usage: alto_importer [flags] server limit"
  puts "Import available ALTO pages into specified TypeWright server."
  puts " -v Verbose output"
  puts " -t Test only -- don't actually upload files"
end

# start by reading our input parameters

VALID_OPTION_FLAGS = %w( v t )
VALID_OPTIONS = %w( )

if ARGV.size < 2
  do_usage()
  exit(1)
end

server = ''
limit = ''
option_flags = []
options = {}
ret_value = []

ARGV.each do |arg|
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
  elsif limit.empty?
    limit = arg
  else
    puts "WARNING: Ignoring unknown parameter: #{arg}"
  end
end

verbose_output = !option_flags.index('v').nil?
test_only = !option_flags.index('t').nil?
cmd_flags = "#{verbose_output ? '-v':''} #{test_only ? '-t':''}"

if limit.to_i == 0
  puts "ERROR: Invalid limit specified (must be numeric, greater than 0)"
  exit(1)
end

pages = PageQueue.get_pages( limit.to_i )

if pages.empty? == true
  puts "WARNING: No pages available for import"
  exit( 0 )
end

pages.each { |page|

  id = page[:id]
  ecco_id = page[:ecco_number]
  xml_file = page[:xml_file]

  # convert the names... not really sure why we have to do this but Matt said so
  tokens = File.basename( xml_file ).split( "." )
  new_name = "#{tokens[ 0 ]}_ALTO.#{tokens[ 1 ]}"
  xml_file = File.join( File.dirname( xml_file ), new_name )

  cmd = "script/import/alto_page #{cmd_flags} #{server} #{xml_file} #{ecco_id}"
  puts "" if verbose_output
  puts "" if verbose_output
  puts cmd
  PageQueue.mark_importing( id ) unless test_only
  result = `#{cmd}`
  ok = $?.success?

  if test_only == false
    PageQueue.mark_imported( id ) if ok == true
    PageQueue.mark_errored( id ) if ok == false
  end

  puts result
}

exit( 0 )

#
# end of file
#