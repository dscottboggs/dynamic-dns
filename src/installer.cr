#!/usr/bin/env crystal

# Install the dynamic_dns script as a persistent system service
module Installer
  include FileUtils
  extend self

  private def checked_run(command, message = nil)
    process = Process.run command
    status = process.wait
    message ||= "execute " + command.to_s
    raise "failed to #{message}" unless status.success?
    status.
  end

  private def run_as_root?
    ENV["UID"] == 0
  end

  def source_dir
    checked_run "find #{pwd} -type f -name installer.cr",
      message: "find source directory within the present directory."
    
  end

  raise "must be run as root" unless run_as_root?
  checked_run "crystal build -o /usr/bin/dynamic_dns "
end
