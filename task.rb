#
# This script is meant to be run as a task from cron or a similar scheduler.
#

require "dotenv/load"
require_relative "feeder"
require "debug" if ENV["ENVIRONMENT"] == "development"

Feeder.generate_feed

puts "Feed generated successfully at #{Time.now}"
