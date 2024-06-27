require "socket"

module Resolv
  VERSION = "0.1.0"

  class DNS
    alias Resources = Array(Resource::A) |
                      Array(Resource::CNAME) |
                      Array(Resource::MX) |
                      Array(Resource::NS) |
                      Array(Resource::SOA) |
                      Array(Resource::PTR) |
                      Array(Resource::TXT)

    class Resource
      enum Type
        A     =  1 # a host address
        NS    =  2 # an authoritative name server
        CNAME =  5 # the canonical name for an alias
        SOA   =  6 # marks the start of a zone of authority
        PTR   = 12 # a domain name pointer
        MX    = 15 # mail exchange
        TXT   = 16 # text strings
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
          @minimum : UInt32
        )
        end
      end

      class MX < Resource
        getter preference, exchange

        # :nodoc:
        def initialize(
          @preference : UInt16,
          @exchange : String
        )
        end
      end

      class A < Resource
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
    end

    def initialize(@server : String, @read_timeout : Time::Span | Nil = nil, @retry : Int32 | Nil = nil)
    end

    {% for type in ["a", "ns", "cname", "soa", "ptr", "mx", "txt"] %}
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
          socket.connect(server, 53)
          socket.send(dns_query)
          response = Bytes.new(512)
          received_info = socket.receive(response)
          bytes_received = received_info[0]   # Number of bytes received
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

    private def extract_records(response : Bytes, type : Resource::Type) : Array(Tuple(String, Int32))
      records = [] of Tuple(String, Int32)
      offset = 12 # Start after the DNS header, which is always 12 bytes

      # Skip the question section
      _, offset = extract_name(response, offset)
      offset += 4 # Skip QTYPE (2 bytes) and QCLASS (2 bytes)

      # Number of answer records
      answer_count = (response[6] << 8) | response[7]

      while answer_count > 0 && offset < response.size
        # Extract the name (skip it)
        _, offset = extract_name(response, offset)

        type_value = (response[offset] << 8) | response[offset + 1]
        offset += 2 # Skip TYPE
        offset += 2 # Skip CLASS
        offset += 4 # Skip TTL
        data_length = (response[offset] << 8) | response[offset + 1]
        offset += 2 # Skip RDLENGTH

        if type_value == type.value.to_u16
          records << {response[offset, data_length].to_s, offset}
        end

        offset += data_length # Move to the next record
        answer_count -= 1
      end

      records
    end

    private def extract_a_records(response : Bytes) : Array(String)
      records = extract_records(response, :a)

      records.map do |_record_data, offset|
        [response[offset], response[offset + 1], response[offset + 2], response[offset + 3]].join('.')
      end
    end

    private def extract_domain_name_records(response : Bytes, type : Resource::Type) : Array(String)
      records = extract_records(response, type)

      records.map do |_, offset|
        record, _ = extract_name(response, offset)

        record
      end
    end

    private def extract_mx_records(response : Bytes) : Array(Resource::MX)
      records = extract_records(response, :mx)

      records.map do |_, offset|
        preference = (response[offset].to_u16 << 8) | response[offset + 1].to_u16
        exchange, _ = extract_name(response, offset + 2)

        Resource::MX.new(preference, exchange)
      end
    end

    private def extract_soa_records(response : Bytes) : Array(Resource::SOA)
      records = extract_records(response, :soa)

      records.map do |_, offset|
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
        offset += 4

        Resource::SOA.new(mname, rname, serial, refresh, retry, expire, minimum)
      end
    end

    private def extract_txt_records(response : Bytes) : Array(Resource::TXT)
      records = extract_records(response, :txt)

      records.map do |_, offset|
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
  end
end
