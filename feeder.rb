# frozen_string_literal: true

require "rss"
require "securerandom"

require_relative "brian"
require_relative "models/topic"
require_relative "models/history_entry"

class Feeder
  FEED_FILE = "feed/feed.rss"
  HISTORY_FILE = "feed/history.json"

  def self.generate_feed
    new.generate_feed
  end

  def initialize(file_system: File, time_provider: Time, brian: Brian)
    @file_system = file_system
    @time_provider = time_provider
    @brian = brian
  end

  def generate_feed
    history = load_history
    new_topics = generate_new_topics(history)

    puts "New topics: #{new_topics.map(&:topic).join(", ")}"

    rss = build_rss_feed(new_topics)
    write_feed_file(rss)
    write_audio_files(new_topics)
    update_history(history, new_topics)
    write_history_file(history)
  end

  def load_history
    JSON.parse(@file_system.read(HISTORY_FILE))
      .map { |entry| HistoryEntry.new(**entry) }
  end

  def generate_new_topics(history)
    history
      .reject { |entry| DateTime.parse(entry.updated_at).to_date == Date.today }
      .map { |entry| @brian.run(entry.book, entry.covered_topics) }
  end

  def build_rss_feed(new_topics)
    if @file_system.exist?(FEED_FILE)
      merge_feed(new_topics)
    else
      create_feed(new_topics)
    end
  end

  def update_history(history, new_topics)
    new_topics.each do |topic|
      history_entry = history.find { it.book == topic.book }
      next unless history_entry

      history_entry.covered_topics << topic.topic
      history_entry.updated_at = @time_provider.now.utc.iso8601
    end
  end

  def write_history_file(history)
    @file_system.write(HISTORY_FILE, JSON.pretty_generate(history))
  end

  def create_feed(new_topics)
    RSS::Maker.make("2.0") do |maker|
      maker = create_channel(maker)
      create_new_items(maker, new_topics)
    end
  end

  def merge_feed(new_topics)
    old_feed = RSS::Parser.parse(@file_system.read(FEED_FILE))

    RSS::Maker.make("2.0") do |maker|
      maker = create_channel(maker)
      maker = create_new_items(maker, new_topics)

      # Add existing items
      old_feed.items.each do |item|
        maker.items.new_item do |new_item|
          new_item.guid.content = item.guid.content
          new_item.guid.isPermaLink = item.guid.isPermaLink
          new_item.title = item.title
          new_item.description = item.description
          new_item.pubDate = item.pubDate
          new_item.link = item.link if item.link
          new_item.author = item.author
        end
      end
    end
  end

  def create_channel(maker)
    maker.channel.title = ENV["FEED_TITLE"]
    maker.channel.description = ENV["FEED_DESCRIPTION"]
    maker.channel.link = ENV["FEED_LINK"]
    maker.channel.language = "en"
    maker.channel.updated = @time_provider.now
    maker.channel.date = @time_provider.now

    maker
  end

  def create_new_items(maker, new_topics)
    new_topics.each do |topic|
      maker.items.new_item do |item|
        item.guid.content = topic.id
        item.guid.isPermaLink = false
        item.title = topic.topic
        item.description = enriched_description(topic)
        item.date = @time_provider.now
        item.author = topic.book
        item.link = link(topic)
      end
    end

    maker
  end

  def sanitize_content(content)
    content.gsub(",", ", ").gsub("‚", ",")
  end

  def enriched_description(topic)
    description = sanitize_content(topic.description)
    return description if topic.audio.nil?

    "<a href=\"https://#{ENV["FEED_DOMAIN"]}/audio/#{topic.id}\">Listen to the audio</a><br><br>#{topic.description}"
  end

  def link(topic)
    "https://#{ENV["FEED_DOMAIN"]}/audio/#{topic.id}"
  end

  def write_feed_file(rss)
    @file_system.write(FEED_FILE, rss.to_s)
  end

  def write_audio_files(new_topics)
    new_topics.each do |topic|
      next unless topic.audio

      @file_system.binwrite("audio/#{topic.id}.mp3", topic.audio)
    end
  end

  def write_history_file(history)
    @file_system.write(HISTORY_FILE, JSON.pretty_generate(history))
  end
end
