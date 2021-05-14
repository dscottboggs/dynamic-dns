module DynamicDNS
  module Helper
    IP_CHECK_ADDRESS = ENV["IP_CHECK_ADDRESS"]? || "https://am.i.mullvad.net/ip"
    CURRENT_IP       = HTTP::Client.get(IP_CHECK_ADDRESS).body.strip
    LOG_BACKEND      = Log::IOBackend.new formatter: JSONFormatter.new, io: if logfile = ENV["logfile"]?
      file = File.new logfile, mode: "a+"
      at_exit { file.close }
      file
    else
      STDOUT
    end
    Log.setup level: if loglevel = ENV["LOG_LEVEL"]?
      Log::Severity.parse loglevel
    else
      Log::Severity::Warn
    end, backend: LOG_BACKEND

    struct ErrorResponse
      include JSON::Serializable
      property id : String
      property message : String
    end

    def handle_digitalocean_error(response)
      err = begin
        ErrorResponse.from_json response.body
      rescue e : JSON::Error
        Log.error exception: e, &.emit "Error from DigitalOcean",
          status_code: response.status_code,
          status_text: response.status_message,
          body: response.body
        return false
      end
      Log.error &.emit "Error from DigitalOcean",
        status_code: response.status_code,
        status_text: response.status_message,
        error_id: err.id,
        error_message: err.message
      false
    end
  end
end
