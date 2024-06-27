require "./spec_helper"

describe Resolv do
  it "works" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    a_records = dns.a_resources("shards.info")

    a_records.should be_a(Array(Resolv::DNS::Resource::A))
    a_records.size.should eq(1)

    addresses = a_records.map(&.address)
    addresses.should contain("67.205.136.192")
  end
end
