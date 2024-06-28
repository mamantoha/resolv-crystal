require "time"
require "../src/resolv"

location = ARGV[0]

dns = Resolv::DNS.new("dns.toys", read_timeout: 5.seconds, retry: 3)
txt_records = dns.txt_resources("#{location}.weather")

records = txt_records.map { |txt_record| txt_record.txt_data }

current_time = Time.local

# Function to parse time in "HH:MM, Day" format
def parse_time(time_str : String, current_time : Time) : Time
  hour, minute = time_str.split(",")[0].split(":").map(&.to_i)

  Time.local(current_time.year, current_time.month, current_time.day, hour, minute, 0)
end

# Find the closest time
closest_time = records.min_by do |record_arry|
  time_str = record_arry.last
  (parse_time(time_str, current_time) - current_time).abs
end

puts closest_time.join(", ")
