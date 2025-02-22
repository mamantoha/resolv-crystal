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
cname_records = dns.cname_resources("www.wikipedia.org")
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

# SRV records
puts "\nSRV Records:"
srv_records = dns.srv_resources("_xmpp-client._tcp.jabber.org")
srv_records.each { |record| puts record.inspect }

# CAA records
puts "\nCAA Records:"
caa_records = dns.caa_resources("shards.info")
caa_records.each { |record| puts record.inspect }

# TXT records
puts "\nTXT Records:"
dns = Resolv::DNS.new("dns.toys")
txt_records = dns.txt_resources("lviv.weather")
txt_records.each { |record| puts record.inspect }
