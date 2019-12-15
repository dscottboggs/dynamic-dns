require "./dynamic_dns"

begin
  docker_client = HTTP::Client.unix "/var/run/docker.sock"

  do_client = HTTP::Client.new "api.digitalocean.com", tls: true
  do_client.before_request do |req|
    req.headers["Authorization"] = "Bearer " + DynamicDNS::DO_AUTH_KEY
    req.headers["Content-Type"] = "application/json"
  end
  records = DomainRecords.collect_all(from: do_client)

  rules = Rules.from_docker docker_client
  rules.apply with: do_client
ensure
  begin
    do_client.try &.close
  ensure
    docker_client.try &.close
  end
end
