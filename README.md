# Resolv

[![Crystal CI](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml/badge.svg)](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml)
[![GitHub release](https://img.shields.io/github/release/mamantoha/resolv-crystal.svg)](https://github.com/mamantoha/resolv-crystal/releases)
[![License](https://img.shields.io/github/license/mamantoha/resolv-crystal.svg)](https://github.com/mamantoha/resolv-crystal/blob/master/LICENSE)

Resolv is a DNS resolver library in Crystal that supports both UDP and TCP.

Supported Resource Record (RR) TYPEs :

|   | Type    | Value | Meaning                                  | Defining RFC |
| - | ------- | ----- | ---------------------------------------- | ------------ |
| ✓ | `A`     | `1`   | a host address                           | RFC 1035     |
| ✓ | `NS`    | `2`   | an authoritative name server             | RFC 1035     |
|   | `MD`    | `3`   | a mail destination (Obsolete - use MX)   | RFC 1035     |
|   | `MF`    | `4`   | a mail forwarder (Obsolete - use MX)     | RFC 1035     |
| ✓ | `CNAME` | `5`   | the canonical name for an alias          | RFC 1035     |
| ✓ | `SOA`   | `6`   | marks the start of a zone of authority   | RFC 1035     |
|   | `MB`    | `7`   | a mailbox domain name (EXPERIMENTAL)     | RFC 1035     |
|   | `MG`    | `8`   | a mail group member (EXPERIMENTAL)       | RFC 1035     |
|   | `MR`    | `9`   | a mail rename domain name (EXPERIMENTAL) | RFC 1035     |
|   | `NULL`  | `10`  | a null RR (EXPERIMENTAL)                 | RFC 1035     |
|   | `WKS`   | `11`  | a well known service description         | RFC 1035     |
| ✓ | `PTR`   | `12`  | a domain name pointer                    | RFC 1035     |
|   | `HINFO` | `13`  | host information                         | RFC 1035     |
|   | `MINFO` | `14`  | mailbox or mail list information         | RFC 1035     |
| ✓ | `MX`    | `15`  | mail exchange                            | RFC 1035     |
| ✓ | `TXT`   | `16`  | text strings                             | RFC 1035     |
| ✓ | `AAAA`  | `28`  | IPv6 host address                        | RFC 3596     |
| ✓ | `SRV`   | `33`  | service location                         | RFC 2782     |
| ✓ | `CAA`   | `257` | certification authority authorization    | RFC 8659     |

- [[RFC 1035](https://datatracker.ietf.org/doc/html/rfc1035)]
- [[RFC 3596](https://datatracker.ietf.org/doc/html/rfc3596)]
- [[RFC 2782](https://datatracker.ietf.org/doc/html/rfc2782)]
- [[RFC 8659](https://datatracker.ietf.org/doc/html/rfc8659)]

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

dns = Resolv::DNS.new("8.8.8.8", read_timeout: 10.seconds, retry: 3, requester: :tcp)

dns.resources("crystal-lang.org", :a)
# #<Resolv::DNS::Resource::A:0x1010d0c40 @address="18.66.112.124">

dns.mx_resources("gmail.com")
# #<Resolv::DNS::Resource::MX:0x1010d0560 @preference=40, @exchange="alt4.gmail-smtp-in.l.google.com">

dns.soa_resources("gmail.com")
# => #<Resolv::DNS::Resource::SOA:0x10245c100 @mname="ns1.google.com", @rname="dns-admin.google.com", @serial=646797294, @refresh=900, @retry=900, @expire=1800, @minimum=60>

dns.srv_resources("_xmpp-client._tcp.jabber.org")
# #<Resolv::DNS::Resource::SRV:0x74689eebdf60 @priority=30, @weight=30, @port=5222, @target="zeus.jabber.org">

dns = Resolv::DNS.new("dns.toys")
dns.txt_resources("lviv.weather")
# #<Resolv::DNS::Resource::TXT:0x104cf00a0 @txt_data=["Lviv (UA)", "28.00C (82.40F)", "43.90% hu.", "partlycloudy_day", "14:00, Thu"]>
```

## Alternatives

Other alternatives are:

- <https://gitlab.com/jgillich/crystal-dns>
- <https://github.com/636f7374/durian.cr>
- <https://github.com/spider-gazelle/dns>

## Contributing

1. Fork it (<https://github.com/mamantoha/resolv-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
