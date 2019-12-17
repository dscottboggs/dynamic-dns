# dynamic_dns
A dynamic DNS solution for Docker and DigitalOcean.

Rules are defined with a docker label on a relevant container. For example, my ethercalc deployment right now uses the following configuration in it's docker-compose.yml

```yaml
version: '2.0'
services:
  ethercalc:
    # ... other options ...
    labels:
      traefik.enable: "true"
      traefik.http.routers.ethercalc.tls: 'true'
      traefik.http.routers.ethercalc.tls.certresolver: letsencrypt
      traefik.http.routers.ethercalc.rule: Host(`sheets.tams.tech`,`sheets.madscientists.co`,`sht.tams.tech`)
      traefik.http.services.ethercalc.loadbalancer.server.port: 8000
      tech.tams.dns_hosts: sheets.tams.tech sheets.madscientists.co sht.tams.tech
    # ... other options ...
```

By simply labelling the container with the whitespace-separated list of domains it will use,
the service will automatically have Digital Ocean point those domains at your IP address.

## Installation
#### Configuration
 - Put your digital ocean OAuth key in a file with nothing else in it at `~/.config/do-dynamic-dns/do.auth.key`.
 - Copy the dynamic-dns.service and dynamic-dns.timer files to `/etc/systemd/system` and run
   `systemctl enable dynamic-dns` to install the service to run periodically

#### Installation from a binary
Download the binary and place it on your path, for example:

```sh
wget `curl -sL https://api.github.com/repos/dscottboggs/dynamic-dns/releases/latest | jq -r '.assets[].browser_download_url' `
sudo mv dynamic-dns /usr/local/bin
```

#### Installation from source
Clone the repository and run the following commands from the project directory to compile it and install:
```sh
crystal build -odynamic-dns --release src/run.cr
sudo mv dynamic-dns /usr/local/bin
```

## Contributing

1. Fork it (<https://github.com/dscottboggs/dynamic-dns/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
