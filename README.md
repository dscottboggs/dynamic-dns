# dynamic_dns

A highly opinionated dynamic DNS solution. Ideal for self-hosters, small business, or other small-to-medium sized deployments. I use it on my home server for my personal services as well as a VPS for more public-facing services (I don't have great upload speeds).

## Features

- Subdomain discovery from Docker container labels
- Integration with DigitalOcean
- Structured Logging (ideal for monitoring and alerting)
- SystemD integration (some manual setup required for now)

### Things I don't plan to add (but would accept a PR for)

- Integration with other dynamic DNS services
- Support for other methods of rule discovery

### Non-goals

- support for swarms, clusters, or however you want to call multi-server deployments. My use case is well-suited to a few single servers which each host a few services separately from each other, so the added complexity is not worth it to me.

## Usage

Rules are defined with a docker label on a relevant container. For example, my ethercalc deployment right now uses the following configuration in it's docker-compose.yml

```yaml
version: "2.0"
services:
  ethercalc:
    # ... other options ...
    labels:
      # ... other labels ...
      tech.tams.dns_hosts: sheets.tams.tech sheets.madscientists.co sht.tams.tech
    # ... other options ...
```

By simply labelling the container with the whitespace-separated list of domains it will use,
the service will automatically have Digital Ocean point those domains at your IP address.

## Installation

### Configuration

- Get a [DigitalOcean API key](https://cloud.digitalocean.com/account/api/tokens) with Read and Write access.
- Create a config file in `$XDG_CONFIG_HOME/dynamic-dns/config.json`:

```json
{
  "auth_key": "your DigitalOcean API key",
  "domains": ["tams.tech"]
}
```

- Copy the dynamic-dns.service and dynamic-dns.timer files to `/etc/systemd/system` and run
  `systemctl enable dynamic-dns` to install the service to run periodically

### Installation from a binary

Download the binary and place it on your path, for example:

```sh
wget `curl -sL https://api.github.com/repos/dscottboggs/dynamic-dns/releases/latest | jq -r '.assets[].browser_download_url' `
sudo mv dynamic-dns /usr/local/bin
```

#### Installation from source

Clone the repository and run the following commands from the project directory to compile it and install:

```sh
shards build --production --release
sudo mv bin/dynamic_dns /usr/local/bin
```

## Running manually after changes

If you know you've made some changes recently and want to force an update, just run `systemctl start dynamic-dns`.

## Contributing

1. Fork it (<https://github.com/dscottboggs/dynamic-dns/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
