# Resolv

[![Crystal CI](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml/badge.svg)](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml)

Resolv is a DNS resolver library written in Crystal.

Supported Resource Record (RR) TYPEs [[RFC 1035](https://www.rfc-editor.org/rfc/rfc1035.html)] and [[RFC 3596](https://datatracker.ietf.org/doc/html/rfc3596)]:

|   | Type    | Value | Meaning                                  |
| - | ------- | ----- | ---------------------------------------- |
| ✓ | `A`     | `1`   | a host address                           |
| ✓ | `NS`    | `2`   | an authoritative name server             |
|   | `MD`    | `3`   | a mail destination (Obsolete - use MX)   |
|   | `MF`    | `4`   | a mail forwarder (Obsolete - use MX)     |
| ✓ | `CNAME` | `5`   | the canonical name for an alias          |
| ✓ | `SOA`   | `6`   | marks the start of a zone of authority   |
|   | `MB`    | `7`   | a mailbox domain name (EXPERIMENTAL)     |
|   | `MG`    | `8`   | a mail group member (EXPERIMENTAL)       |
|   | `MR`    | `9`   | a mail rename domain name (EXPERIMENTAL) |
|   | `NULL`  | `10`  | a null RR (EXPERIMENTAL)                 |
|   | `WKS`   | `11`  | a well known service description         |
| ✓ | `PTR`   | `12`  | a domain name pointer                    |
|   | `HINFO` | `13`  | host information                         |
|   | `MINFO` | `14`  | mailbox or mail list information         |
| ✓ | `MX`    | `15`  | mail exchange                            |
| ✓ | `TXT`   | `16`  | text strings                             |
| ✓ | `AAAA`  | `28`  | IPv6 host address                        |

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     resolv:
       github: mamantoha/resolv-crystal
   ```

2. Run `shards install`

## Usage

```crystal
require "resolv"

dns = Resolv::DNS.new("8.8.8.8", read_timeout: 10.seconds, retry: 3)

dns.resources("crystal-lang.org", :a)
# #<Resolv::DNS::Resource::A:0x1010d0c40 @address="18.66.112.124">

dns.mx_resources("gmail.com")
# #<Resolv::DNS::Resource::MX:0x1010d0560 @preference=40, @exchange="alt4.gmail-smtp-in.l.google.com">

dns.soa_resources("gmail.com")
# => #<Resolv::DNS::Resource::SOA:0x10245c100 @mname="ns1.google.com", @rname="dns-admin.google.com", @serial=646797294, @refresh=900, @retry=900, @expire=1800, @minimum=60>

dns = Resolv::DNS.new("dns.toys")
dns.txt_resources("lviv.weather")
# #<Resolv::DNS::Resource::TXT:0x104cf00a0 @txt_data=["Lviv (UA)", "28.00C (82.40F)", "43.90% hu.", "partlycloudy_day", "14:00, Thu"]>
```

## Contributing

1. Fork it (<https://github.com/mamantoha/resolv-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
