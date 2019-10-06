require "json"

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

struct IncomingDomainRecord
  include JSON::Serializable
  include DomainRecord

  property id : Int32

  def to_outgoing : OutgoingDomainRecord
    OutgoingDomainRecord.new({% for ivar in @type.instance_vars %}
      {{ivar.id}}: @{{ivar.id}}
    {% end %})
  end
end

struct OutgoingDomainRecord
  include JSON::Serializable
  include DomainRecord
end
