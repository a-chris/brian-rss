# frozen_string_literal: true

require "rss"
require "securerandom"
require "htmlentities"

require_relative "brian"
require_relative "models/topic"
require_relative "models/history_entry"

class Feeder
  FEED_FILE = "feed/feed.rss"
  HISTORY_FILE = "feed/history.json"

  #
  # History is a JSON file with entries like:
  # - name: "Thinking, fast and slow by Daniel Kahneman"
  # - covered_topics: []
  # - updated_at: "2023-10-30T20:00:00Z"
  #
  def self.generate_feed
    history =
      JSON.parse(File.read(HISTORY_FILE))
        .map { HistoryEntry.new(**it) }

    new_topics =
      history
        .reject { DateTime.parse(it.updated_at).to_date == Date.today }
        .map { Brian.run(it.book, it.covered_topics) }

    puts "New topics: #{new_topics.map(&:topic).join(", ")}"
    rss =
      if File.exist?(FEED_FILE)
        merge_feed(new_topics)
      else
        create_feed(new_topics)
      end

    # update rss feed
    File.write(FEED_FILE, rss.to_s)
    new_topics.each do |topic|
      File.binwrite("audio/#{topic.id}.mp3", topic.audio) if topic.audio
    end

    # update history
    new_topics.each do |topic|
      history_entry = history.find { it.book == topic.book }
      next unless history_entry

      history_entry.covered_topics << topic.topic
      history_entry.updated_at = Time.now.utc.iso8601
      history[history.index(history_entry)] = history_entry
    end

    File.write(HISTORY_FILE, JSON.pretty_generate(history))
  end

  def self.create_feed(new_topics)
    RSS::Maker.make("2.0") do |maker|
      maker = create_channel(maker)
      create_new_items(maker, new_topics)
    end
  end

  def self.merge_feed(new_topics)
    old_feed = RSS::Parser.parse(File.read(FEED_FILE))

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

  def self.create_channel(maker)
    maker.channel.title = ENV["FEED_TITLE"]
    maker.channel.description = ENV["FEED_DESCRIPTION"]
    maker.channel.link = ENV["FEED_LINK"]
    maker.channel.language = "en"
    maker.channel.updated = Time.now
    maker.channel.date = Time.now

    maker
  end

  def self.create_new_items(maker, new_topics)
    new_topics.each do |topic|
      maker.items.new_item do |item|
        item.guid.content = topic.id
        item.guid.isPermaLink = false
        item.title = topic.topic
        item.description = enriched_description(topic)
        item.date = Time.now
        item.author = topic.book
        item.link = link(topic)
      end
    end

    maker
  end

  def self.sanitize_content(content)
    content.gsub(",", ", ").gsub("‚", ",")
  end

  def self.enriched_description(topic)
    description = sanitize_content(topic.description)
    return description if topic.audio.nil?

    "<a href=\"#{ENV["FEED_DOMAIN"]}/audio/#{topic.id}\">Voice recording</a><br><br>#{topic.description}"
  end

  def self.link(topic)
    "https://#{ENV["FEED_DOMAIN"]}/audio/#{topic.id}"
  end
end
