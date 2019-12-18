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
  LOG.debug "NEW INSTANCE"

  CONFDIR = ENV["confdir"]?.try { |var| Path.new var } || (os_config_dir / "do-dynamic-dns")

  DO_AUTH_KEY = File.read "#{CONFDIR}/do.auth.key"

  private def self.os_config_dir
    Path[ENV.fetch("XDG_CONFIG_HOME", default: Path.home.to_s), ".config"]
  end
end
