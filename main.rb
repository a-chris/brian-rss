# frozen_string_literal: true

require "dotenv/load"
require "sinatra"

require "debug" if ENV["ENVIRONMENT"] == "development"

require_relative "feeder"

set :port, ENV.fetch("PORT", 4567)
set :bind, "0.0.0.0"
set :environment, :production
set :permitted_hosts, ["*.*.*.*"]
set :static_headers, {
  "access-control-allow-origin" => "*"
}

# cors
set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type,if-modified-since"
set :allow_credentials, true

disable :protection

get "/" do
  "Welcome to Brian RSS!"
end

get "/health" do
  "OK"
end

get "/rss" do
  if File.exist?(Feeder::CACHE_FILE)
    content_type "application/rss+xml"
    cache_control :public, :must_revalidate, max_age: 300  # 5 minutes
    last_modified File.mtime(Feeder::CACHE_FILE)
    headers "Pragma" => "no-cache"
    File.read(Feeder::CACHE_FILE)
  else
    status 404
    "Feed not found"
  end
end

get "/audio/:id" do
  id = params[:id]
  audio_file = "audio/#{id}.mp3"

  if File.exist?(audio_file)
    content_type "audio/mpeg"
    cache_control :public, :must_revalidate, max_age: 86400  # 1 day
    last_modified File.mtime(audio_file)
    headers "Pragma" => "no-cache"
    File.read(audio_file)
  else
    status 404
    "Audio file not found"
  end
end
