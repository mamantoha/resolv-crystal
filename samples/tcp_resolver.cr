require "../src/resolv"

# Example Usage
dns = Resolv::DNS.new("8.8.8.8", requester: :tcp)

# A records
puts "A Records:"
a_records = dns.a_resources("crystal-lang.org")
a_records.each { |record| puts record.inspect }
