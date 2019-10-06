require "uri"

# The response returned from DigitalOcean when requesting a list of all domain records.
class DomainRecords
  include JSON::Serializable
  property domain_records : Set(IncomingDomainRecord)
  property links : Links?

  struct Links
    struct Pages
      include JSON::Serializable
      property first : String?
      property prev : String?
      property next : String?
      property last : String?
    end

    include JSON::Serializable
    property pages : Pages
  end

  def initialize
    @domain_records = Set(IncomingDomainRecord).new
  end

  def self.collect_all(from client : HTTP::Client) : Hash(String, self)
    all = {} of String => self
    {"tams.tech", "madscientists.co"}.each do |host|
      link = "/v2/domains/" + host + "/records"
      until link.nil?
        resp = client.get link
        records = begin
          self.from_json resp.body
        rescue e : JSON::MappingError
          puts "error parsing the following JSON:\n", JSON.parse(resp.body).to_pretty_json
          raise e
        end
        all[host] = all[host]? || new
        all[host].domain_records += records.domain_records
        link = if next_link = records.links.try(&.pages.next)
                 uri = URI.parse next_link
                 pgnum = uri.query_params["page"]?
                 break if pgnum.nil?
                 "/v2/domains/#{host}/records?page=#{pgnum}"
               end
      end
    end
    all
  end
end