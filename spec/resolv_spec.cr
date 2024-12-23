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
    dns = Resolv::DNS.new("8.8.8.8", 5.seconds, retry: 3)
    records = dns.caa_resources("shards.info")

    records.should be_a(Array(Resolv::DNS::Resource::CAA))
    records.size.should eq(1)

    record = records.first

    record.not_nil!.flags.should eq(0)
    record.not_nil!.tag.should eq("issue")
    record.not_nil!.value.should eq("letsencrypt.org")
  end

  context "UDP requester" do
    describe "response is large than 512 bytes" do
      it "fails by default" do
        dns = Resolv::DNS.new("dns.toys", requester: :udp)

        expect_raises Resolv::Error, /Unknown error: `Index out of bounds`/ do
          dns.txt_resources("Dublin.weather")
        end
      end

      it "success with larger udp size" do
        dns = Resolv::DNS.new("dns.toys", requester: :udp, udp_size: 2048)
        records = dns.txt_resources("Dublin.weather")

        records.should be_a(Array(Resolv::DNS::Resource::TXT))
      end
    end
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
