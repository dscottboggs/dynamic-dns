# Automatic dynamic DNS for dockerized deployments
#
# Uses labels to associate services with a hostname on the current system

# STDLIB
require "logger"
# STDLIB monkey-patches
require "./core_ext/http_client"
# External shards
require "docker"
# Local Files
require "./domain_record"
require "./domain_records"

def split(rule)
  # find the index of the second-to-last dot
  if div_idx = rule.rindex '.', offset: (rule.rindex('.') || rule.size) - 1
    {rule[..div_idx - 1], rule[(div_idx + 1)..]}
  else
    {"@", rule}
  end
end

def handle_DO_error(resp)
  err = begin
    ErrorResponse.from_json resp.body
  rescue JSON::MappingError
    LOG.error "Error #{resp.status_code} #{(m = resp.status_message) ? '(' + m + ')' : nil}: #{resp.body}"
    return
  end
  LOG.error "Error #{resp.status_code} (#{resp.status_message || err.id}): #{err.message}"
end

struct ErrorResponse
  include JSON::Serializable
  property id : String
  property message : String
end

LOG = Logger.new(
  io: if logfile = ENV["logfile"]?
    file = File.new logfile, mode: "a+"
    at_exit { LOG.try &.close }
    file
  else
    STDOUT
  end,
  level: if loglevel = ENV["loglevel"]?
    Logger::Severity.parse loglevel
  else
    Logger::Severity::WARN
  end
)
LOG.info "NEW INSTANCE"

DO_AUTH_KEY = File.read "#{File.dirname __DIR__}/do.auth.key"
CURRENT_IP  = HTTP::Client.get("https://am.i.mullvad.net/ip").body.strip

begin
  docker_client = HTTP::Client.unix "/var/run/docker.sock"

  do_client = HTTP::Client.new "api.digitalocean.com", tls: true
  do_client.before_request do |req|
    req.headers["Authorization"] = "Bearer " + DO_AUTH_KEY
    req.headers["Content-Type"] = "application/json"
  end
  records = DomainRecords.collect_all(from: do_client)

  Array(Docker::Container).from_json(docker_client.get("/containers/json").body).each do |container|
    if rules = container.labels.try &.["tech.tams.dns_hosts"]?.try &.split
      rules.each do |rule|
        subdomain, host = split rule
        if found = records[host]?.try &.domain_records.find { |record| record.name == subdomain }
          if found.data.strip != CURRENT_IP
            # Update an existing record with PUT /v2/domains/$DOMAIN_NAME/records/$RECORD_ID. Post body is OutgoingDomainRecord
            LOG.warn "Container #{container.names.try(&.first.lchop?('/')) || container.id} needs to be updated! #{found.data.inspect} != #{CURRENT_IP.inspect}"
            uri = "/v2/domains/#{host}/records/#{found.id}"
            resp = do_client.put uri,
              body: OutgoingDomainRecord.new_A_record(subdomain, CURRENT_IP).to_json
            if resp.success?
              LOG.debug "Recieved reply from DigitalOcean on endpoint " +
                        uri + '\n' + JSON.parse(resp.body).to_pretty_json
              LOG.info "Successfully updated rule for domain #{rule} from IP #{found.data} to #{CURRENT_IP}"
            else
              break handle_DO_error resp
            end
          else
            # Do nothing -- already up to date
            LOG.info "container " + (container.names.try(&.first.lchop?('/')) || container.id) + " is already set the correct IP address."
          end
        else
          # create a new domain record with POST /v2/domains/$DOMAIN_NAME/records (post body is OutgoingDomainRecord)
          LOG.warn "no A record with subdomain #{subdomain} and host #{host} found"
          uri = "/v2/domains/#{host}/records"
          resp = do_client.post uri,
            body: OutgoingDomainRecord.new_A_record(subdomain, CURRENT_IP).to_json
          if resp.success?
            LOG.debug "Recieved reply from DigitalOcean on endpoint " +
                      uri + '\n' + JSON.parse(resp.body).to_pretty_json
            LOG.info "Successfully added rule for domain #{rule} with IP #{CURRENT_IP}"
          else
            break handle_DO_error resp
          end
        end
      end
    end
  end
ensure
  do_client.try &.close
  docker_client.try &.close
end
