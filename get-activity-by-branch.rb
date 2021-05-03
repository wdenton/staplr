#!/usr/bin/env ruby
# frozen_string_literal: true

# CONFIGURING

require "cgi"
require "csv"
require "json"

require "docopt"
require "http"
require "nokogiri"

doc = <<DOCOPT
  Generate JSON file of the most recent YUL desk activity

  Usage:
    #{__FILE__} [options]

  Options:
    --minutes <min>   Get data for most recent time span [default: 30]
    --verbose         Be verbose [default: false]
DOCOPT

# Keep all desks by default; I'm removing these options.  Keep around for now
# until I clean this up.
# --askus           Include AskUs? [default: false]
# --building        Include Building Services? [default: false]
# --circ            Include circulation desks? [default: false]

options = Docopt.docopt(doc)

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
  warn "Start: #{t_start.strftime('%F %R')}"
  warn "End:   #{t_end.strftime('%F %R')}"
end

if ENV["LIBSTATS_LOGIN_COOKIE"].nil?
  warn "No LibStats cookie known (please set $LIBSTATS_LOGIN_COOKIE)"
  exit 0
end

# Map the way the time_spent is recorded to actual minutes we can use.
TIMES = {
  "0-1 minute" => 1,
  "1-5 minutes" => 3,
  "5-10 minutes" => 8,
  "10-20 minutes" => 15,
  "20-30 minutes" => 25,
  "30-60 minutes" => 40,
  "60+ minutes" => 65
}.freeze

# Thank you again, Stack Overflow.  Created a hash of hashes of an array.
# https://stackoverflow.com/questions/5544858/accessing-elements-of-nested-hashes-in-ruby
activity = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }

data = ""

begin
  response = HTTP.cookies(login: ENV["LIBSTATS_LOGIN_COOKIE"]).get(tweet_csv_url)
  warn "Could not download data: status #{response.status}" unless response.status.success?
  data = response.to_s
rescue StandardError => e
  warn "Could not download data: #{e}"
  exit 0
end

warn data if options["--verbose"]

if data == "\n"
  # LibStats returns a newline if there is no data ... inelegant,
  # but we can deal with it.
  warn "Questions: 0" if options["--verbose"]
else
  csv = CSV.parse(data, headers: true, header_converters: :symbol)

  # Keep all desks by default.
  # csv.delete_if { |row| row[:library_name] == "AskUs" } unless options["--askus"]
  # csv.delete_if { |row| row[:library_name] == "BuildingServices" } unless options["--building"]
  # csv.delete_if { |row| row[:location_name] == "Circulation Desk" } unless options["--circ"]

  # TODO: Refactor this as per  https://github.com/rubocop/rubocop/issues/8247

  unless csv.empty?
    csv.each do |row|
      time = TIMES[row[:time_spent]]
      type = row[:question_type][0].to_i
      activity[row[:library_name]][type] << time
    end
  end
end

puts activity.to_json
