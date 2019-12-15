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
require "./rules"
require "./config"
require "./helper"

module DynamicDNS
  include Helper
  LOG.info "NEW INSTANCE"

  DO_AUTH_KEY = File.read "#{File.dirname __DIR__}/do.auth.key"

  DEFAULT_CONFIG_LOC = Path[__DIR__, "do-dynamic-dns.json"]
  class_property config : Config { Config.load from: DEFAULT_CONFIG_LOC }
end
