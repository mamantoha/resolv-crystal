require "../src/resolv"

# Example Usage
dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)

# A records
puts "A Records:"
a_records = dns.a_resources("crystal-lang.org")
a_records.each { |record| puts record.inspect }

# AAAA records
puts "\nAAAA Records:"
aaaa_records = dns.aaaa_resources("wikimedia.org")
aaaa_records.each { |record| puts record.inspect }

# NS records
puts "\nNS Records:"
ns_records = dns.ns_resources("wikimedia.org")
ns_records.each { |record| puts record.inspect }

# CNAME records
puts "\nCNAME Records:"
cname_records = dns.cname_resources("hz.cdn.mycar168.com")
cname_records.each { |record| puts record.inspect }

# SOA records
puts "\nSOA Records:"
soa_records = dns.soa_resources("gmail.com")
soa_records.each { |record| puts record.inspect }

# MX records
puts "\nMX Records:"
mx_records = dns.mx_resources("gmail.com")
mx_records.each { |record| puts record.inspect }

# PTR records
puts "\nPTR Records:"
ptr_records = dns.ptr_resources("206.3.217.172.in-addr.arpa")
ptr_records.each { |record| puts record.inspect }

# TXT records
dns = Resolv::DNS.new("dns.toys")
txt_records = dns.txt_resources("lviv.weather")
puts "\nTXT Records:"
txt_records.each { |record| puts record.inspect }
