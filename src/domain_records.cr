require "uri"
require "./helper"

module DynamicDNS
  # The response returned from DigitalOcean when requesting a list of all domain records.
  class DomainRecords
    Log = ::Log.for "domain-records"
    extend Helper
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

    def self.collect_all(of hosts, from client : HTTP::Client) : Hash(String, self)
      all = Hash(String, self).new { self.new }
      hosts.each do |host|
        Log.info &.emit "querying existing records", host: host
        link = "/v2/domains/" + host + "/records"
        until link.nil?
          response = client.get link
          break handle_digitalocean_error response unless response.success?
          records = begin
            self.from_json response.body
          rescue e : JSON::Error
            Log.fatal exception: e, &.emit "error parsing JSON response", body: response.body
            raise e
          end
          all[host].domain_records += records.domain_records
          link = if next_link = records.links.try(&.pages.next)
                   uri = URI.parse next_link
                   pgnum = uri.query_params["page"]?
                   break if pgnum.nil?
                   "/v2/domains/#{host}/records?page=#{pgnum}"
                 end

          Log.debug &.emit "redirecting", destination: link if link
        end
      end
      all
    end
  end
end
