require "../src/resolv"

# Example Usage
dns = Resolv::DNS.new("https://cloudflare-dns.com/dns-query", requester: :doh)

# A records
puts "A Records:"
a_records = dns.a_resources("shards.info")
a_records.each { |record| puts record.inspect }
