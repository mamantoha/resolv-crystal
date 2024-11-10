require "socket"

module Resolv
  VERSION = "0.1.0"

  class Error < Exception
    def initialize(message = "Error")
      super(message)
    end
  end

  def self.default_dns_resolver : String
    dns_servers = [] of String

    {% if flag?(:win32) %}
      output = `powershell -Command "Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses"`

      output.each_line do |line|
        line = line.strip

        if line != ""
          dns_servers << line
        end
      end
    {% else %}
      if File.exists?("/etc/resolv.conf")
        File.each_line("/etc/resolv.conf") do |line|
          if match_result = /nameserver\s+(\S+)/.match(line)
            dns_servers << match_result[1]
          end
        end
      end
    {% end %}

    dns_servers.first? || raise Error.new("No DNS servers found")
  end

  class DNS
    # Default DNS Port
    PORT = 53

    # Default DNS UDP packet size
    UDP_SIZE = 512

    alias Resources = Array(Resource::A) |
                      Array(Resource::CNAME) |
                      Array(Resource::MX) |
                      Array(Resource::NS) |
                      Array(Resource::SOA) |
                      Array(Resource::PTR) |
                      Array(Resource::TXT) |
                      Array(Resource::AAAA) |
                      Array(Resource::SRV) |
                      Array(Resource::CAA)

    # DNS RCODEs
    #
    # See http://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#dns-parameters-6 for reference
    enum RCode
      NoError   =  0
      FormErr   =  1
      ServFail  =  2
      NXDomain  =  3
      NotImp    =  4
      Refused   =  5
      YXDomain  =  6
      YXRRSet   =  7
      NXRRSet   =  8
      NotAuth   =  9
      NotZone   = 10
      DSOTYPENI = 11
      BADVERS   = 16
      BADSIG    = 16
      BADKEY    = 17
      BADTIME   = 18
      BADMODE   = 19
      BADNAME   = 20
      BADALG    = 21
      BADTRUNC  = 22
      BADCOOKIE = 23
    end

    class Resource
      enum Type
        A     =   1 # a host address
        NS    =   2 # an authoritative name server
        CNAME =   5 # the canonical name for an alias
        SOA   =   6 # marks the start of a zone of authority
        PTR   =  12 # a domain name pointer
        MX    =  15 # mail exchange
        TXT   =  16 # text strings
        AAAA  =  28 # IPv6 host address
        SRV   =  33 # service location
        CAA   = 257 # certification authority authorization
      end

      class SOA < Resource
        getter mname, rname, serial, refresh, retry, expire, minimum

        # :nodoc:
        def initialize(
          @mname : String,
          @rname : String,
          @serial : UInt32,
          @refresh : UInt32,
          @retry : UInt32,
          @expire : UInt32,
          @minimum : UInt32,
        )
        end
      end

      class MX < Resource
        getter preference, exchange

        # :nodoc:
        def initialize(
          @preference : UInt16,
          @exchange : String,
        )
        end
      end

      class A < Resource
        getter address

        # :nodoc:
        def initialize(@address : String)
        end
      end

      class AAAA < Resource
        getter address

        # :nodoc:
        def initialize(@address : String)
        end
      end

      class NS < Resource
        getter nsdname

        # :nodoc:
        def initialize(@nsdname : String)
        end
      end

      class CNAME < Resource
        getter cname

        # :nodoc:
        def initialize(@cname : String)
        end
      end

      class PTR < Resource
        getter ptrdname

        # :nodoc:
        def initialize(@ptrdname : String)
        end
      end

      class TXT < Resource
        getter txt_data

        # :nodoc:
        def initialize(@txt_data : Array(String))
        end
      end

      class SRV < Resource
        getter priority, weight, port, target

        # :nodoc:
        def initialize(
          @priority : UInt16,
          @weight : UInt16,
          @port : UInt16,
          @target : String,
        )
        end
      end

      class Resource::CAA < Resource
        getter flags, tag, value

        def initialize(
          @flags : UInt8,
          @tag : String,
          @value : String,
        )
        end
      end
    end

    def initialize(@server : String = Resolv.default_dns_resolver, @read_timeout : Time::Span | Nil = nil, @retry : Int32 | Nil = nil)
    end

    {% for type in ["a", "ns", "cname", "soa", "ptr", "mx", "txt", "aaaa", "srv", "caa"] %}
      def {{type.id}}_resources(domain : String) : Array(Resource::{{type.id.upcase}})
        resources(domain, :{{type.id}}).as(Array(Resource::{{type.id.upcase}}))
      end
    {% end %}

    def resources(domain : String, type : Resource::Type) : Resources
      response = query_dns(domain, @server, type)

      case type
      in .a?
        extract_a_records(response).map do |record|
          Resource::A.new(record)
        end
      in .ns?
        extract_domain_name_records(response, :ns).map do |record|
          Resource::NS.new(record)
        end
      in .cname?
        extract_domain_name_records(response, :cname).map do |record|
          Resource::CNAME.new(record)
        end
      in .soa?
        extract_soa_records(response)
      in .ptr?
        extract_domain_name_records(response, :ptr).map do |record|
          Resource::PTR.new(record)
        end
      in .mx?
        extract_mx_records(response)
      in .txt?
        extract_txt_records(response)
      in .aaaa?
        extract_aaaa_records(response).map do |record|
          Resource::AAAA.new(record)
        end
      in .srv?
        extract_srv_records(response)
      in .caa?
        extract_caa_records(response)
      end
    end

    private def build_dns_query(domain : String, type : Resource::Type) : Bytes
      transaction_id = Random::Secure.random_bytes(2) # Random transaction ID for uniqueness
      flags = Bytes[0x01_u8, 0x00_u8]                 # Standard query with recursion desired
      questions = Bytes[0x00_u8, 0x01_u8]             # One question
      answer_rrs = Bytes[0x00_u8, 0x00_u8]            # Zero answer RRs
      authority_rrs = Bytes[0x00_u8, 0x00_u8]         # Zero authority RRs
      additional_rrs = Bytes[0x00_u8, 0x00_u8]        # Zero additional RRs

      labels = domain.split('.')

      question = labels.reduce([] of UInt8) do |acc, label|
        acc << label.size.to_u8
        acc += label.bytes

        acc
      end

      question << 0_u8 # End of domain label sequence

      question_bytes = Bytes.new(question.size)
      question.each_with_index { |byte, index| question_bytes[index] = byte }

      type = Bytes[type.value.to_u16 >> 8, type.value.to_u16 & 0xFF]
      dns_class = Bytes[0x00_u8, 0x01_u8] # Class IN

      transaction_id + flags + questions + answer_rrs + authority_rrs + additional_rrs + question_bytes + type + dns_class
    end

    private def query_dns(domain : String, server : String, type : Resource::Type) : Bytes
      dns_query = build_dns_query(domain: domain, type: type)
      retries_left = @retry || 0

      loop do
        socket = UDPSocket.new
        socket.read_timeout = @read_timeout

        begin
          socket.connect(server, PORT)
          socket.send(dns_query)
          response = Bytes.new(UDP_SIZE)
          received_info = socket.receive(response)
          bytes_received = received_info[0] # Number of bytes received

          status = status(response)

          raise Error.new(status.to_s) unless status.no_error?

          return response[0...bytes_received] # Return the actual response
        rescue ex : IO::TimeoutError
          if retries_left > 0
            retries_left -= 1
          else
            raise ex
          end
        ensure
          socket.close
        end
      end
    end

    private def status(response : Bytes) : RCode
      status_code = (response[3] & 0x0F).to_u8

      RCode.new(status_code)
    end

    # Extracts a domain name from the DNS response message starting at the specified offset.
    # Returns a Tuple containing the extracted domain name and the new offset position after the name.
    private def extract_name(response : Bytes, offset : Int32) : Tuple(String, Int32)
      name = ""

      while offset < response.size && response[offset] != 0_u8
        if (response[offset] & 0xC0) == 0xC0
          pointer = ((response[offset] & 0x3F) << 8) | response[offset + 1]
          extracted_name, _ = extract_name(response, pointer)
          name += extracted_name + "."
          offset += 2

          return {name[0..-2], offset} # Return immediately since we are following a pointer
        else
          length = response[offset]
          offset += 1
          name += String.new(response[offset, length]) + "."
          offset += length
        end
      end

      offset += 1 if offset < response.size && response[offset] == 0_u8 # Skip the zero byte

      {name[0..-2], offset} # Remove the trailing dot and return
    end

    # Extracts the offsets of DNS resource records of a specified type from the DNS response message.
    #
    # This method processes the DNS response to extract the offsets of resource records (e.g., A, NS, MX, etc.).
    # It skips the question section and parses the answer section to find records of the specified type.
    # Each extracted record offset is returned.
    private def extract_record_offsets(response : Bytes, type : Resource::Type) : Array(Int32)
      offsets = [] of Int32
      offset = 12 # Start after the DNS header, which is always 12 bytes

      # Skip the question section
      _, offset = extract_name(response, offset)
      offset += 4 # Skip QTYPE (2 bytes) and QCLASS (2 bytes)

      # Number of answer records
      answer_count = (response[6] << 8) | response[7]

      while answer_count > 0 && offset < response.size
        # Extract the name (skip it)
        _, offset = extract_name(response, offset)

        type_value = (response[offset].to_u16 << 8) | response[offset + 1].to_u16

        offset += 2 # Skip TYPE
        offset += 2 # Skip CLASS
        offset += 4 # Skip TTL
        data_length = (response[offset] << 8) | response[offset + 1]
        offset += 2 # Skip RDLENGTH

        if type_value == type.value.to_u16
          offsets << offset
        end

        offset += data_length # Move to the next record
        answer_count -= 1
      end

      offsets
    end

    private def extract_a_records(response : Bytes) : Array(String)
      offsets = extract_record_offsets(response, :a)

      offsets.map do |offset|
        ip_tuple = {response[offset], response[offset + 1], response[offset + 2], response[offset + 3]}

        Socket::IPAddress.v4(*ip_tuple, port: 0).address
      end
    end

    private def extract_aaaa_records(response : Bytes) : Array(String)
      offsets = extract_record_offsets(response, :aaaa)

      offsets.map do |offset|
        segments = (0..7).map { |i| (response[offset + 2 * i].to_u16 << 8) | response[offset + 2 * i + 1].to_u16 }
        ip_tuple = {segments[0], segments[1], segments[2], segments[3], segments[4], segments[5], segments[6], segments[7]}

        Socket::IPAddress.v6(*ip_tuple, port: 0).address
      end
    end

    private def extract_domain_name_records(response : Bytes, type : Resource::Type) : Array(String)
      offsets = extract_record_offsets(response, type)

      offsets.map do |offset|
        record, _ = extract_name(response, offset)

        record
      end
    end

    private def extract_mx_records(response : Bytes) : Array(Resource::MX)
      offsets = extract_record_offsets(response, :mx)

      offsets.map do |offset|
        preference = (response[offset].to_u16 << 8) | response[offset + 1].to_u16
        exchange, _ = extract_name(response, offset + 2)

        Resource::MX.new(preference, exchange)
      end
    end

    private def extract_soa_records(response : Bytes) : Array(Resource::SOA)
      offsets = extract_record_offsets(response, :soa)

      offsets.map do |offset|
        mname, offset = extract_name(response, offset)
        rname, offset = extract_name(response, offset)

        serial = (response[offset].to_u32 << 24) | (response[offset + 1].to_u32 << 16) | (response[offset + 2].to_u32 << 8) | response[offset + 3].to_u32

        offset += 4
        refresh = (response[offset].to_u32 << 24) | (response[offset + 1].to_u32 << 16) | (response[offset + 2].to_u32 << 8) | response[offset + 3].to_u32

        offset += 4
        retry = (response[offset].to_u32 << 24) | (response[offset + 1].to_u32 << 16) | (response[offset + 2].to_u32 << 8) | response[offset + 3].to_u32

        offset += 4
        expire = (response[offset].to_u32 << 24) | (response[offset + 1].to_u32 << 16) | (response[offset + 2].to_u32 << 8) | response[offset + 3].to_u32

        offset += 4
        minimum = (response[offset].to_u32 << 24) | (response[offset + 1].to_u32 << 16) | (response[offset + 2].to_u32 << 8) | response[offset + 3].to_u32

        Resource::SOA.new(mname, rname, serial, refresh, retry, expire, minimum)
      end
    end

    private def extract_txt_records(response : Bytes) : Array(Resource::TXT)
      offsets = extract_record_offsets(response, :txt)

      offsets.map do |offset|
        txt_end = offset + (response[offset - 2] << 8) + response[offset - 1]
        record_texts = [] of String

        while offset < txt_end
          text_length = response[offset].to_u8
          offset += 1
          record_texts << String.new(response[offset, text_length])
          offset += text_length
        end

        Resource::TXT.new(record_texts)
      end
    end

    private def extract_srv_records(response : Bytes) : Array(Resource::SRV)
      offsets = extract_record_offsets(response, :srv)

      offsets.map do |offset|
        priority = (response[offset].to_u16 << 8) | response[offset + 1].to_u16
        weight = (response[offset + 2].to_u16 << 8) | response[offset + 3].to_u16
        port = (response[offset + 4].to_u16 << 8) | response[offset + 5].to_u16
        target, _ = extract_name(response, offset + 6)

        Resource::SRV.new(priority, weight, port, target)
      end
    end

    private def extract_caa_records(response : Bytes) : Array(Resource::CAA)
      offsets = extract_record_offsets(response, :caa)

      offsets.map do |offset|
        flags = response[offset].to_u8
        tag_len = response[offset + 1].to_u8
        tag = String.new(response[offset + 2, tag_len])
        value = String.new(response[offset + 2 + tag_len, response.size - offset - 2 - tag_len])

        Resource::CAA.new(flags, tag, value)
      end
    end
  end
end
