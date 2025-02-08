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

  it "CNAME records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.cname_resources("www.wikipedia.org")

    records.should be_a(Array(Resolv::DNS::Resource::CNAME))
    records.size.should eq(1)

    cname = records.map(&.cname).first
    cname.should eq("dyna.wikimedia.org")
  end

  it "SRV records" do
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.srv_resources("_xmpp-client._tcp.jabber.org")

    records.should be_a(Array(Resolv::DNS::Resource::SRV))
    records.size.should eq(1)

    record = records.find { |rec| rec.target == "scarlet.jabber.org" }

    record.not_nil!.port.should eq(5222)
  end

  it "CAA records" do
    dns = Resolv::DNS.new("1.1.1.1", 5.seconds, retry: 3)
    records = dns.caa_resources("shards.info")

    records.should be_a(Array(Resolv::DNS::Resource::CAA))
    records.size.should eq(10)

    record = records.first

    record.not_nil!.flags.should eq(0)
    record.not_nil!.tag.should eq("issue")
    record.not_nil!.value.should eq("comodoca.com")
  end

  it "LOC records" do
    dns = Resolv::DNS.new("1.1.1.1", 5.seconds, retry: 3)
    records = dns.loc_resources("shards.info")

    records.should be_a(Array(Resolv::DNS::Resource::LOC))
    records.size.should eq(1)

    record = records.first

    # dig loc shards.info @1.1.1.1
    # 49 33 11.710 N 25 35 49.740 E 0.00m 1m 10000m 10m

    record.not_nil!.latitude.should eq(49.55325277777777)
    record.not_nil!.longitude.should eq(25.59715)
    record.not_nil!.altitude.should eq(0.0)
    record.not_nil!.size.should eq(1.0)
    record.not_nil!.horizontal_precision.should eq(10000.0)
    record.not_nil!.vertical_precision.should eq(10.0)
  end

  context "TCP requester" do
    it "A records" do
      dns = Resolv::DNS.new("8.8.8.8", requester: :tcp)
      records = dns.a_resources("shards.info")

      records.should be_a(Array(Resolv::DNS::Resource::A))
      records.size.should eq(1)

      addresses = records.map(&.address)
      addresses.should contain("67.205.136.192")
    end
  end

  context "DOH requester" do
    it "A records" do
      # https://developers.cloudflare.com/1.1.1.1/encryption/dns-over-https/make-api-requests/
      dns = Resolv::DNS.new("https://cloudflare-dns.com/dns-query", requester: :doh)
      records = dns.a_resources("shards.info")

      records.should be_a(Array(Resolv::DNS::Resource::A))
      records.size.should eq(1)

      addresses = records.map(&.address)
      addresses.should contain("67.205.136.192")
    end
  end
end
