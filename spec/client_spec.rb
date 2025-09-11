# frozen_string_literal: true

require "spec_helper"
require_relative "../client"

RSpec.describe AiClient do
  let(:text_uri_base) { "https://text.example.com/" }
  let(:audio_uri_base) { "https://audio.example.com/" }
  let(:access_token) { "test_token" }

  before do
    # Mock ENV variables
    allow(ENV).to receive(:[]).with("AI_TEXT_PROVIDER").and_return("custom")
    allow(ENV).to receive(:[]).with("CUSTOM_TEXT_PROVIDER").and_return(text_uri_base)
    allow(ENV).to receive(:[]).with("AI_AUDIO_PROVIDER").and_return("custom")
    allow(ENV).to receive(:[]).with("CUSTOM_AUDIO_PROVIDER").and_return(audio_uri_base)
    allow(ENV).to receive(:[]).with("ACCESS_TOKEN").and_return(access_token)

    @audio_double = instance_double(OpenAI::Client)
    @audio_speech_double = instance_double(OpenAI::Audio)

    allow(@audio_double).to receive(:audio).and_return(@audio_speech_double)
    allow(@audio_speech_double).to receive(:speech).and_return(true)

    # Mock OpenAI::Client
    @text_client_double = instance_double(OpenAI::Client)

    allow(OpenAI::Client).to receive(:new).and_return(@text_client_double, @audio_double)
  end

  describe "#initialize" do
    it "creates text client with correct parameters" do
      AiClient.new

      expect(OpenAI::Client).to have_received(:new).with(
        access_token: access_token,
        uri_base: text_uri_base,
        log_errors: true
      )
    end

    it "creates audio client with correct parameters" do
      AiClient.new

      expect(OpenAI::Client).to have_received(:new).with(
        access_token: access_token,
        uri_base: audio_uri_base,
        log_errors: true
      )
    end
  end

  describe "#chat" do
    it "forwards call to text client" do
      client = AiClient.new
      test_args = {
        parameters: {
          model: "test",
          messages: [
            {role: "system", content: "a"},
            {role: "user", content: "b"}
          ],
          temperature: 1
        }
      }

      expect(@text_client_double).to receive(:chat).with(test_args)
      client.chat(test_args)
    end
  end

  describe "#audio" do
    it "allows chained call to speech" do
      client = AiClient.new
      test_args = {
        parameters: {
          model: "tts-1",
          input: "test",
          instructions: "test",
          voice: "shimmer",
          response_format: "mp3",
          speed: 1.0
        }
      }

      expect(@audio_double).to receive(:audio)
      expect(@audio_speech_double).to receive(:speech).with(test_args)
      client.audio.speech(test_args)
    end
  end
end
