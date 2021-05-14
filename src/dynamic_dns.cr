# Automatic dynamic DNS for dockerized deployments
#
# Uses labels to associate services with a hostname on the current system

# STDLIB

# STDLIB monkey-patches
require "./core_ext/log"

# External shards
require "xdg"

# Local Files
require "./domain_record"
require "./domain_records"
require "./rules"
require "./config"
require "./helper"

module DynamicDNS
  include Helper

  CONFDIR = ENV["confdir"]?.try { |var| Path.new var } || (XDG::CONFIG::HOME / "dynamic-dns")
  CONFIG  = Config.load from: CONFDIR / "config.json"
end
