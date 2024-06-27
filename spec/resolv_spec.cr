require "./spec_helper"

describe Resolv do
  it "works" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds)
    a_records = dns.a_resources("crystal-lang.org")

    a_records.should be_a(Array(Resolv::DNS::Resource::A))
    a_records.size.should eq(4)

    addresses = a_records.map(&.address)
    addresses.should contain("18.244.146.39")
  end
end
