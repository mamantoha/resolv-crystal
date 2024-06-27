# Resolv

[![Crystal CI](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml/badge.svg)](https://github.com/mamantoha/resolv-crystal/actions/workflows/crystal.yml)

Resolv is a DNS resolver library written in Crystal.

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
