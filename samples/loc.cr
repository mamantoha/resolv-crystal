require "../src/resolv"

dns = Resolv::DNS.new
# https://wiki.openstreetmap.org/wiki/Uk:%D0%A2%D0%B5%D1%80%D0%BD%D0%BE%D0%BF%D1%96%D0%BB%D1%8C
# latitude 49°33′11.71″ North, longitude 25°35′49.74″ East
loc_records = dns.resources("shards.info", Resolv::DNS::Resource::Type::LOC)

puts loc_records
