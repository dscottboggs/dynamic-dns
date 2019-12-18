module Helper
  IP_CHECK_ADDRESS = ENV["IP_CHECK_ADDRESS"]? || "https://am.i.mullvad.net/ip"
  CURRENT_IP       = HTTP::Client.get(IP_CHECK_ADDRESS).body.strip
  LOG              = Logger.new(
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

  struct ErrorResponse
    include JSON::Serializable
    property id : String
    property message : String
  end

  def handle_DO_error(response)
    err = begin
      ErrorResponse.from_json response.body
    rescue JSON::MappingError
      LOG.error "Error #{response.status_code} #{(m = response.status_message) ? '(' + m + ')' : nil}: #{response.body}"
      return false
    end
    LOG.error "Error #{response.status_code} (#{response.status_message || err.id}): #{err.message}"
    false
  end
end
