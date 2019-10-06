require "./core_ext/http_client"
require "docker"
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

DO_AuthKey = File.read "#{File.dirname __DIR__}/do.auth.key"
CurrentIP  = HTTP::Client.get(
  "https://am.i.mullvad.net/ip",
  headers: HTTP::Headers.new.tap { |h| h["Content-Type"] = "text/plain" }
).body.strip

begin
  docker_client = HTTP::Client.unix "/var/run/docker.sock"

  do_client = HTTP::Client.new "api.digitalocean.com", tls: true
  do_client.before_request { |req| req.headers["Authorization"] = "Bearer " + DO_AuthKey }
  records = DomainRecords.collect_all(from: do_client)

  Array(Docker::Container).from_json(docker_client.get("/containers/json").body).each do |container|
    if rules = container.labels.try &.["tech.tams.dns_hosts"]?.try &.split
      rules.each do |rule|
        subdomain, host = split rule
        if found = records[host]?.try &.domain_records.find { |record| record.name == subdomain }
          if found.data.strip != CurrentIP
            # Update an existing record with PUT /v2/domains/$DOMAIN_NAME/records/$RECORD_ID. Post body is OutgoingDomainRecord
            puts "Container #{container.names.try(&.first.lchop?('/')) || container.id} needs to be updated! #{pp found.data} != #{pp CurrentIP}"
          else
            # Do nothing -- already up to date
            puts "container " + (container.names.try(&.first.lchop?('/')) || container.id) + " is already set the correct IP address."
          end
        else
          # create a new domain record with POST /v2/domains/$DOMAIN_NAME/records (post body is OutgoingDomainRecord)
          puts "no A record with subdomain #{subdomain} and host #{host} found"
        end
      end
    end
  end
ensure
  do_client.try &.close
  docker_client.try &.close
end
