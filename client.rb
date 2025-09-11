# frozen_string_literal: true

require "openai"

class AiClient
  def initialize
    text_uri_base =
      case ENV["TEXT_PROVIDER"]
      when "openai" then nil
      when "google" then "https://generativelanguage.googleapis.com/v1beta/openai/"
      when "deepseek" then "https://api.deepseek.com/"
      else ENV["CUSTOM_TEXT_PROVIDER"]
      end

    @text_client = OpenAI::Client.new(
      access_token: ENV["ACCESS_TOKEN"],
      uri_base: text_uri_base,
      log_errors: true
    )

    audio_uri_base =
      case ENV["AUDIO_PROVIDER"]
      when "openai" then nil
      when "google" then "https://generativelanguage.googleapis.com/v1beta/openai/"
      when "deepseek" then "https://api.deepseek.com/"
      else ENV["CUSTOM_AUDIO_PROVIDER"]
      end

    @audio_client = OpenAI::Client.new(
      access_token: ENV["ACCESS_TOKEN"],
      uri_base: audio_uri_base,
      log_errors: true
    )
  end

  def chat(**) = @text_client.chat(**)
  def audio(**) = @audio_client.audio(**)
end

AI_CLIENT = AiClient.new
