require 'csv'
require 'optparse'
require 'fileutils'
require './lib/postgres.rb'
require './lib/oracle.rb'

opt = OptionParser.new
opt.version = '0.0.1'
options = {}

opt.on('-t DATABASE', '--target=DATABASE', 'Target database, postgres | oracle', ['postgres', 'oracle']) {|v| options[:target] = v }
opt.on('-h', '--header', 'Specify this option when header is in CSV') {|v| options[:header] = v }
opt.on('-n table_name', '--name table_name', 'Table name to import') {|v| options[:table_name] = v }
opt.on('-f FILE', '--file=FILE', 'CSV file to input') {|v| options[:file] = v }

opt.parse(ARGV)

raise "File must be specified" if options[:file].nil?
raise "File not found: #{options[:file]}" unless File.exists? options[:file]


header_str = nil
open(options[:file], 'r', encoding: 'cp932') { |f| header_str = f.gets.chomp.encode('utf-8') }
headers = CSV.parse_line(header_str)
FileUtils.mkdir_p(options[:table_name])

db = nil
if options[:target] == 'postgres'
  db = Postgres.new options, headers
elsif options[:target] == 'oracle'
  db = Oracle.new options, headers
else
  STDERR.puts "Invalid usage. please #{$0} -h"
end
db.create_table
db.import_csv
db.drop_table
db.show_usage
