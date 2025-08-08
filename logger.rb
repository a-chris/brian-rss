require "logger"

OUTPUT =
  if ENV["DOCKER_LOGS"] == "1"
    # Use a logger that writes to the container's stdout/stderr
    # This is useful for Docker and Kubernetes environments
    # where logs are collected from stdout/stderr
    fd = IO.sysopen("/proc/1/fd/1", "w")
    io = IO.new(fd, "w")
    io.sync = true
    io
  else
    $stdout
  end

class CustomFormatter < Logger::Formatter
  def call(severity, time, progname, msg)
    # Format: [TIME] SEVERITY: Message
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S %z")
    "#{timestamp} #{severity}: #{msg}\n"
  end
end

LOGGER = Logger.new(OUTPUT)
LOGGER.level = Logger::INFO
LOGGER.formatter = CustomFormatter.new
