require "../src/resolv"

# https://code.blogs.iiidefix.net/posts/get-public-ip-using-dns/

dns = Resolv::DNS.new("resolver1.opendns.com", 5.seconds, retry: 3)

records = dns.a_resources("myip.opendns.com")
records.each { |record| puts record.address }
