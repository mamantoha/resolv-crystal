require "time"
require "../src/resolv"

location = ARGV[0]

dns = Resolv::DNS.new("dns.toys", read_timeout: 5.seconds, retry: 3)
txt_records = dns.txt_resources("#{location}.weather")

records = txt_records.map(&.txt_data)

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

location = closest_time[0]
temperature = closest_time[1]
# humidity = closest_time[2]
condition = closest_time[3]
# time = closest_time[4]

temperature_regex = /(?<celsius>\d+\.\d+)C \((?<fahrenheit>\d+\.\d+)F\)/

celsius = if m = temperature_regex.match(temperature)
            m["celsius"]
          else
            temperature.split(" ").first[...-1]
          end

# https://www.nerdfonts.com/cheat-sheet
weather = {
  "cloudy"               => "",
  "partlycloudy_day"     => "",
  "partlycloudy_night"   => "",
  "fair_day"             => "",
  "fair_night"           => "",
  "clearsky_day"         => "",
  "clearsky_night"       => "",
  "rainshowers_day"      => "",
  "heavyrainshowers_day" => "",
  "lightrainshowers_day" => "",
  "rain"                 => "",
  "heavyrain"            => "",
  "lightrain"            => "",
  "sleet"                => "",
  "lightsleet"           => "",
}

puts closest_time.join(", ")

puts "#{weather[condition]? || ' '} #{celsius}°C #{location}"
