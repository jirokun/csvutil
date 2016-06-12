class Postgres
  def initialize(options, headers)
    @options = options
    @headers = headers
  end

  def create_table
    create_sql = "create table #{@options[:table_name]} ("
    create_sql += @headers.map {|c| "#{c} varchar(1000)"}.join(',')
    create_sql += ");"
    open(@options[:table_name] + "/1_create_table.sql", "w") do |f|
      f.puts create_sql
    end
  end

  def import_csv
    open(@options[:table_name] + "/2_import_csv.sql", "w") do |f|
      f.puts "\\copy #{@options[:table_name]}(#{@headers.join(',')}) from '#{@options[:file]}' with encoding 'SJIS' header csv;"
    end
  end

  def drop_table
    open(@options[:table_name] + "/3_drop_table.sql", "w") do |f|
      f.puts "drop table #{@options[:table_name]};"
    end
  end

  def show_usage
    puts <<EOT
Please execute following commands.

# create table to insert
psql -h <host> -d <database> -U <user> < #{@options[:table_name]}/1_create_table.sql
# import csv to table
psql -h <host> -d <database> -U <user> < #{@options[:table_name]}/2_import_csv.sql
# drop table
psql -h <host> -d <database> -U <user> < #{@options[:table_name]}/3_drop_table.sql
EOT

  end
end
