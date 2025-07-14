# frozen_string_literal: true

require "openai"

OPENAI_CLIENT = OpenAI::Client.new(
  access_token: ENV["OPENAI_ACCESS_TOKEN"],
  log_errors: true
)

# Available but not used right now
DEEPSEEK_CLIENT = OpenAI::Client.new(
  access_token: ENV["DEEP_SEEK_ACCESS_TOKEN"],
  uri_base: "https://api.deepseek.com/"
)
