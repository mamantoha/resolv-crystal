require "./spec_helper"

describe Resolv do
  it "A records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.a_resources("shards.info")

    records.should be_a(Array(Resolv::DNS::Resource::A))
    records.size.should eq(1)

    addresses = records.map(&.address)
    addresses.should contain("67.205.136.192")
  end

  it "AAAA records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.aaaa_resources("wikimedia.org")

    records.should be_a(Array(Resolv::DNS::Resource::AAAA))
    records.size.should eq(1)

    addresses = records.map(&.address)
    addresses.should contain("2a02:ec80:300:ed1a::1")
  end
end
