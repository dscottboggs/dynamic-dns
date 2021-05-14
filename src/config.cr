require "json"

module DynamicDNS
  struct Config
    include JSON::Serializable
    property domains : Array(String)
    property auth_key : String

    def initialize(@domains, @auth_key)
    end

    def self.from_json(stream : IO) : self
      new pull: JSON::PullParser.new input: stream
    end

    def self.load(*, from file : Path, **file_open_opts)
      File.open(file, **file_open_opts) { |io| from_json io }
    end

    def self.load(*, from file : String, **file_open_opts)
      load **file_open_opts, from: Path.new(file)
    end
  end
end
