# frozen_string_literal: true

require "spec_helper"
require_relative "../feeder"
require_relative "../models/topic"
require_relative "../models/history_entry"

RSpec.describe Feeder do
  let(:file_system) { class_double("File") }
  let(:client) { instance_double("OpenAI::Client") }
  let(:brian) { instance_double("Brian", client:) }
  let(:current_time) { Time.new(2025, 1, 15, 10, 0, 0, "+00:00") }
  let(:feeder) { described_class.new(file_system:, brian:) }

  before do
    allow(client).to receive(:chat).and_return({choices: [{message: {content: "Generated content"}}]})
  end

  describe "#load_history" do
    let(:history_json) do
      [
        {
          "book" => "Ruby Programming",
          "covered_topics" => ["Variables", "Methods"],
          "updated_at" => "2025-01-14T10:00:00Z"
        },
        {
          "book" => "Rails Guide",
          "covered_topics" => ["Models", "Controllers"],
          "updated_at" => "2025-01-13T10:00:00Z"
        }
      ].to_json
    end

    it "loads and parses history from JSON file" do
      allow(file_system).to receive(:read).with("feed/history.json").and_return(history_json)

      history = feeder.load_history

      expect(history.size).to eq(2)
      expect(history[0]).to be_a(HistoryEntry)
      expect(history[0].book).to eq("Ruby Programming")
      expect(history[0].covered_topics).to eq(["Variables", "Methods"])
      expect(history[0].updated_at).to eq("2025-01-14T10:00:00Z")
    end
  end

  describe "#generate_new_topics" do
    let(:history) do
      [
        HistoryEntry.new("Ruby Programming", ["Variables"], "2025-01-13T10:00:00Z")
      ]
    end

    let(:topic1) { Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil) }

    it "generates topics for entries not updated today" do
      Timecop.freeze(Time.new(2025, 1, 14, 10, 0, 0, "+00:00"))

      allow(brian).to receive(:run).with("Ruby Programming", ["Variables"]).and_return(topic1)
      topics = feeder.generate_new_topics(history)

      expect(topics).to eq([topic1])
      Timecop.return
    end

    it "skips entries updated today" do
      Timecop.freeze(Time.new(2025, 1, 13, 10, 0, 0, "+00:00"))

      topics = feeder.generate_new_topics(history)

      expect(topics).to be_empty
      Timecop.return
    end
  end

  describe "#build_rss_feed" do
    let(:new_topics) { [Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil)] }

    context "when feed file exists" do
      it "merges with existing feed" do
        allow(file_system).to receive(:exist?).with("feed/feed.rss").and_return(true)
        allow(feeder).to receive(:merge_feed).with(new_topics).and_return("merged_feed")

        result = feeder.build_rss_feed(new_topics)

        expect(result).to eq("merged_feed")
      end
    end

    context "when feed file does not exist" do
      it "creates new feed" do
        allow(file_system).to receive(:exist?).with("feed/feed.rss").and_return(false)
        allow(feeder).to receive(:create_feed).with(new_topics).and_return("new_feed")

        result = feeder.build_rss_feed(new_topics)

        expect(result).to eq("new_feed")
      end
    end
  end

  describe "#write_feed_file" do
    let(:rss) { instance_double("RSS::Rss", to_s: "feed_content") }

    it "writes RSS feed to file" do
      expect(file_system).to receive(:write).with("feed/feed.rss", "feed_content")

      feeder.write_feed_file(rss)
    end
  end

  describe "#write_audio_files" do
    let(:topic_with_audio) { Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", "audio_data") }
    let(:topic_without_audio) { Topic.new("id2", "Methods", "About methods", "Ruby Programming", nil) }
    let(:new_topics) { [topic_with_audio, topic_without_audio] }

    it "writes audio files for topics that have audio" do
      expect(file_system).to receive(:binwrite).with("audio/id1.mp3", "audio_data")
      expect(file_system).not_to receive(:binwrite).with("audio/id2.mp3", anything)

      feeder.write_audio_files(new_topics)
    end
  end

  describe "#update_history" do
    let(:history) do
      [
        HistoryEntry.new("Ruby Programming", ["Variables"], "2025-01-14T10:00:00Z"),
        HistoryEntry.new("Rails Guide", ["Models"], "2025-01-13T10:00:00Z")
      ]
    end

    let(:new_topics) do
      [
        Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil),
        Topic.new("id2", "Views", "About Rails views", "Rails Guide", nil)
      ]
    end

    it "updates history entries with new topics and timestamps" do
      Timecop.freeze(Time.new(2025, 1, 15, 10, 0, 0, "+00:00"))
      feeder.update_history(history, new_topics)

      expect(history[0].covered_topics).to eq(["Variables", "Classes"])
      expect(history[0].updated_at).to eq("2025-01-15T10:00:00Z")
      expect(history[1].covered_topics).to eq(["Models", "Views"])
      expect(history[1].updated_at).to eq("2025-01-15T10:00:00Z")
      Timecop.return
    end

    it "skips topics with no matching history entry" do
      orphan_topic = Topic.new("id3", "Orphan", "About orphan", "Unknown Book", nil)
      new_topics << orphan_topic

      expect { feeder.update_history(history, new_topics) }.not_to raise_error
    end
  end

  describe "#write_history_file" do
    let(:history) do
      [
        HistoryEntry.new("Ruby Programming", ["Variables", "Classes"], "2025-01-15T10:00:00Z")
      ]
    end

    it "writes history to JSON file" do
      expected_json = JSON.pretty_generate(history)
      expect(file_system).to receive(:write).with("feed/history.json", expected_json)

      feeder.write_history_file(history)
    end
  end

  describe "#sanitize_content" do
    it "replaces commas with comma-space" do
      result = feeder.sanitize_content("one,two,three")
      expect(result).to eq("one, two, three")
    end

    it "replaces special comma characters" do
      result = feeder.sanitize_content("one‚two‚three")
      expect(result).to eq("one,two,three")
    end
  end

  describe "#enriched_description" do
    let(:topic_without_audio) { Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil) }
    let(:topic_with_audio) { Topic.new("id2", "Methods", "About methods", "Ruby Programming", "audio_data") }

    before do
      allow(ENV).to receive(:[]).with("FEED_DOMAIN").and_return("example.com")
    end

    it "returns sanitized description for topics without audio" do
      result = feeder.enriched_description(topic_without_audio)
      expect(result).to eq("About Ruby classes")
    end

    it "returns enriched description with audio link for topics with audio" do
      result = feeder.enriched_description(topic_with_audio)
      expected = "<a href=\"https://example.com/audio/id2\">Listen to the audio</a><br><br>About methods"
      expect(result).to eq(expected)
    end
  end

  describe "#link" do
    let(:topic) { Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil) }

    before do
      allow(ENV).to receive(:[]).with("FEED_DOMAIN").and_return("example.com")
    end

    it "returns audio link for topic" do
      result = feeder.link(topic)
      expect(result).to eq("https://example.com/audio/id1")
    end
  end

  describe "#generate_feed" do
    let(:history) do
      [
        HistoryEntry.new("Ruby Programming", ["Variables"], "2025-01-14T10:00:00Z")
      ]
    end

    let(:new_topics) do
      [
        Topic.new("id1", "Classes", "About Ruby classes", "Ruby Programming", nil)
      ]
    end

    let(:rss_feed) { instance_double("RSS::Rss", to_s: "feed_content") }

    before do
      allow(feeder).to receive(:load_history).and_return(history)
      allow(feeder).to receive(:generate_new_topics).with(history).and_return(new_topics)
      allow(feeder).to receive(:build_rss_feed).with(new_topics).and_return(rss_feed)
      allow(feeder).to receive(:write_feed_file).with(rss_feed)
      allow(feeder).to receive(:write_audio_files).with(new_topics)
      allow(feeder).to receive(:update_history).with(history, new_topics)
      allow(feeder).to receive(:write_history_file).with(history)
      allow(feeder).to receive(:puts)
    end

    it "orchestrates the complete feed generation process" do
      feeder.generate_feed

      expect(feeder).to have_received(:load_history)
      expect(feeder).to have_received(:generate_new_topics).with(history)
      expect(feeder).to have_received(:build_rss_feed).with(new_topics)
      expect(feeder).to have_received(:write_feed_file).with(rss_feed)
      expect(feeder).to have_received(:write_audio_files).with(new_topics)
      expect(feeder).to have_received(:update_history).with(history, new_topics)
      expect(feeder).to have_received(:write_history_file).with(history)
    end

    it "prints new topics" do
      expect(feeder).to receive(:puts).with("New topics: Classes")

      feeder.generate_feed
    end
  end
end
