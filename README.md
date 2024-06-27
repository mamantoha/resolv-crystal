# Resolv

[![Crystal CI](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml/badge.svg)](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml)

Resolv is a DNS resolver library written in Crystal.

Supported Resource Record (RR) TYPEs [[RFC1035](https://www.rfc-editor.org/rfc/rfc1035.html)]:

|    | Type   | Value | Meaning                                 |
| -- | ------ | ----- | --------------------------------------- |
| ✓ | `A`     | `1`  | a host address                           |
| ✓ | `NS`    | `2`  | an authoritative name server             |
|   | `MD`    | `3`  | a mail destination (Obsolete - use MX)   |
|   | `MF`    | `4`  | a mail forwarder (Obsolete - use MX)     |
| ✓ | `CNAME` | `5`  | the canonical name for an alias          |
| ✓ | `SOA`   | `6`  | marks the start of a zone of authority   |
|   | `MB`    | `7`  | a mailbox domain name (EXPERIMENTAL)     |
|   | `MG`    | `8`  | a mail group member (EXPERIMENTAL)       |
|   | `MR`    | `9`  | a mail rename domain name (EXPERIMENTAL) |
|   | `NULL`  | `10` | a null RR (EXPERIMENTAL)                 |
|   | `WKS`   | `11` | a well known service description         |
| ✓ | `PTR`   | `12` | a domain name pointer                    |
|   | `HINFO` | `13` | host information                         |
|   | `MINFO` | `14` | mailbox or mail list information         |
| ✓ | `MX`    | `15` | mail exchange                            |
| ✓ | `TXT`   | `16` | text strings                             |

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

dns = Resolv::DNS.new("8.8.8.8")
ress = dns.resources("www.ruby-lang.org", :a)
# => Array(Resolv::DNS::Resources)
# <Resolv::DNS::Resource::A:0x1010d0c40 @address="185.199.111.153">
ress = dns.resources("gmail.com", :mx)
# <Resolv::DNS::Resource::MX:0x1010d0560 @preference=40, @exchange="alt4.gmail-smtp-in.l.google.com">

ress = dns.mx_resources("gmail.com")
# => Array(Resolv::DNS::Resource::MX)
```

## Contributing

1. Fork it (<https://github.com/mamantoha/resolv-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Anton Maminov](https://github.com/mamantoha) - creator and maintainer
