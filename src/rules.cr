require "./helper"

struct Rules
  include Helper
  @rules : Set(String)

  def initialize(@rules); end

  def self.from_docker(client : HTTP::Client)
    new Array(Docker::Container)
      .from_json(client.get("/containers/json").body)
      .map(&.labels.try &.["tech.tams.dns_hosts"]?.try &.split)
      .compact
      .flatten
      .to_set
  end

  def apply(with client : HTTP::Client)
    records = DomainRecords.collect_all from: client
    @rules.each do |rule|
      subdomain, host = split rule
      if found = records[host]?.try &.domain_records.find &.name.== subdomain
        if found.data.strip != CURRENT_IP
          break unless update subdomain, host, found, client
        else
          # Do nothing -- already up to date
          LOG.info "rule for #{subdomain}.#{host} is already set the correct IP address."
        end
      else
        break unless create subdomain, host, client
      end
    end
  end

  private def create(subdomain : String, host : String, client) : Bool
    # create a new domain record with POST /v2/domains/$DOMAIN_NAME/records (post body is OutgoingDomainRecord)
    LOG.warn "no A record with subdomain #{subdomain} and host #{host} found"
    uri = "/v2/domains/#{host}/records"
    resp = client.post uri,
      body: OutgoingDomainRecord.new_A_record(subdomain, CURRENT_IP).to_json
    return handle_DO_error resp unless resp.success?
    LOG.debug "Recieved reply from DigitalOcean on endpoint " +
              uri + '\n' + JSON.parse(resp.body).to_pretty_json
    LOG.info "Successfully added rule for domain #{subdomain}.#{host} with IP #{CURRENT_IP}"
    true
  end

  private def update(subdomain : String, host : String, found, client) : Bool
    # Update an existing record with PUT /v2/domains/$DOMAIN_NAME/records/$RECORD_ID. Post body is OutgoingDomainRecord
    LOG.warn "Rule for #{subdomain}.#{host} needs to be updated! #{found.data.inspect} != #{CURRENT_IP.inspect}"
    uri = "/v2/domains/#{host}/records/#{found.id}"
    resp = client.put uri,
      body: OutgoingDomainRecord.new_A_record(subdomain, CURRENT_IP).to_json
    return handle_DO_error resp unless resp.success?
    LOG.debug "Recieved reply from DigitalOcean on endpoint " +
              uri + '\n' + JSON.parse(resp.body).to_pretty_json
    LOG.info "Successfully updated rule for domain #{subdomain}.#{host} from IP #{found.data} to #{CURRENT_IP}"
    true
  end

  private def split(rule : String) : Tuple(String, String)
    # find the index of the second-to-last dot
    if div_idx = rule.rindex '.', offset: (rule.rindex('.') || rule.size) - 1
      {rule[..div_idx - 1], rule[(div_idx + 1)..]}
    else
      {"@", rule}
    end
  end
end
