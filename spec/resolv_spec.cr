require "./spec_helper"

describe Resolv do
  context "default resolver" do
    it "A records" do
      dns = Resolv::DNS.new(read_timeout: 5.seconds, retry: 3)
      records = dns.a_resources("shards.info")

      records.should be_a(Array(Resolv::DNS::Resource::A))
      records.size.should eq(1)

      addresses = records.map(&.address)
      addresses.should contain("67.205.136.192")
    end
  end

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

    address = records.map(&.address).first
    address.should match(/[a-z0-9]+:[a-z0-9]+:[a-z0-9]+:[a-z0-9]+::1/)
  end

  it "SRV records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.srv_resources("_xmpp-client._tcp.jabber.org")

    records.should be_a(Array(Resolv::DNS::Resource::SRV))
    records.size.should eq(2)

    record = records.find { |r| r.target == "zeus-v6.jabber.org" }

    record.not_nil!.target.should eq("zeus-v6.jabber.org")
    record.not_nil!.port.should eq(5222)
  end

  it "CAA records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.caa_resources("shards.info")

    records.should be_a(Array(Resolv::DNS::Resource::CAA))
    records.size.should eq(1)

    record = records.first

    record.not_nil!.flags.should eq(0)
    record.not_nil!.tag.should eq("issue")
    record.not_nil!.value.should eq("shards.info")
  end
end
