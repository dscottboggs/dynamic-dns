require "json"

DEFAULT_TTL = 600_i64

module DomainRecord
  macro included
    property type : String
    property name : String
    property data : String
    property priority : Int64?
    property port : Int64?
    property ttl : Int64
    property weight : Int64?
    property flags : Int64?
    property tag : String?
  end
end

@[JSON::Serializable::Options(emit_nulls: true)]
struct IncomingDomainRecord
  include JSON::Serializable
  include DomainRecord

  property id : Int32

  def initialize(@id, @type, @name, @data, @ttl,
                 @priority = nil,
                 @port = nil,
                 @weight = nil,
                 @flags = nil,
                 @tag = nil)
  end

  def to_outgoing : OutgoingDomainRecord
    OutgoingDomainRecord.new({% for ivar in @type.instance_vars %}
      {{ivar.id}}: @{{ivar.id}}
    {% end %})
  end
end

@[JSON::Serializable::Options(emit_nulls: true)]
struct OutgoingDomainRecord
  include JSON::Serializable
  include DomainRecord

  def initialize(@type, @name, @data, @ttl,
                 @priority = nil,
                 @port = nil,
                 @weight = nil,
                 @flags = nil,
                 @tag = nil)
  end

  def self.new_A_record(subdomain : String, ip_address : String, ttl = DEFAULT_TTL)
    new type: "A",
      name: subdomain,
      data: ip_address,
      ttl: ttl
  end
end
