#!/usr/bin/env ruby

# CONFIGURING

require "cgi"
require "csv"
require "json"
require "open-uri"

require "docopt"
require "nokogiri"

doc = <<DOCOPT
  Generate JSON file of the most recent YUL desk activity

  Usage:
    #{__FILE__} [options]

  Options:
    --minutes <min>   Get data for most recent time span [default: 30]
    --circ            Include circulation desks? [default: false]
    --verbose         Be verbose [default: false]
DOCOPT

options = Docopt.docopt(doc)

# options = {}
# options[:minutes] = 30
# options[:circ] = false
# OptionParser.new do |opts|
#   opts.banner = "Usage: get-activity-by-branch.rb [options]"
#   opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
#     options[:verbose] = v
#   end
#   opts.on("-m", "--minutes m", "Minutes to capture") do |m|
#     options[:minutes] = m.to_i
#   end
#   opts.on("c", "--circ", "Include circulation desks") do
#     options[:circ] = TRUE
#   end
# end.parse!

data_url = "https://www.library.yorku.ca/libstats/reportReturn.do?&library_id=&location_id=&report_id=DataCSVReport"

t_end   = Time.now
t_start = t_end - 60 * options["--minutes"].to_i

ugly_date_format = "%m/%d/%y %l:%M %p"

end_time = t_end.strftime(ugly_date_format)
start_time = t_start.strftime(ugly_date_format)

tweet_csv_url = data_url +
                "&date1=#{CGI.escape(start_time)}" \
                "&date2=#{CGI.escape(end_time)}"

if options["--verbose"]
  STDERR.puts "Start: #{t_start.strftime('%F %R')}"
  STDERR.puts "End:   #{t_end.strftime('%F %R')}"
end

if ENV["LIBSTATS_LOGIN_COOKIE"].nil?
  STDERR.puts "No LibStats cookie known (please set $LIBSTATS_LOGIN_COOKIE)"
  exit 0
end

# Thank you again, Stack Overflow.  Created a hash of hashes of an array.
# https://stackoverflow.com/questions/5544858/accessing-elements-of-nested-hashes-in-ruby
activity = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }

# activity = {
#   "ASC"      => {},
#   "Bronfman" => {},
#   "Frost"    => {},
#   "Maps"     => {},
#   "Scott"    => {},
#   "SMIL"     => {},
#   "Steacie"  => {},
# }

# activity = Array.new(6) { Array.new(0) } # Create array of 6 empty arrays

data = ""

begin
  open(tweet_csv_url,
       "Cookie" => "login=#{ENV['LIBSTATS_LOGIN_COOKIE']}") do |f|
    if f.status[0] != "200"
      STDERR.puts "Could not download data: status #{f.status}"
    end
    data = f.read
  end
rescue StandardError => e
  STDERR.puts "Could not download data: #{e}"
  exit 0
end

STDERR.puts data if options["--verbose"]

if data == "\n"
  # LibStats returns a newline if there is no data ... inelegant,
  # but we can deal with it.
  STDERR.puts "Questions: 0" if options["--verbose"]
else
  csv = CSV.parse(data, headers: true, header_converters: :symbol)

  # Silently drop activity at the Scott info desk, which is too busy
  # and would overwhelm Twitter.
  csv.delete_if { |row| row[:library_name] == "Scott Information" }

  # Only include circ desks if the --circ option is true
  unless options["--circ"]
    csv.delete_if { |row| row[:location_name] == "Circulation Desk" }
  end

  unless csv.empty?
    csv.each do |row|
      time = case row[:time_spent]
             when "0-1 minute"    then 1
             when "1-5 minutes"   then 3
             when "5-10 minutes"  then 8
             when "10-20 minutes" then 15
             when "20-30 minutes" then 25
             when "30-60 minutes" then 40
             when "60+ minutes"   then 65
             end
      type = row[:question_type][0].to_i

      activity[row[:library_name]][type] << time
    end
  end
end

puts activity.to_json
