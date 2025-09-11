# frozen_string_literal: true

require "securerandom"

require_relative "client"
require_relative "models/topic"

class Brian
  TEXT_MODEL = ENV["TEXT_MODEL"]

  SYSTEM_PROMPT = <<~TEXT
    Create a detailed analysis of the topic chosen by the user, including the whys, how and what results.

    Just focus on the topic itself, do not add commentary or colloquial phrases.
    The analysis should start by explaining the idea or concept very clearly and with simple terms, assume the user didn't read the book.
    Make practical examples with real-world and actionable insights if the topic allows them.
    Be engaging and even funny to keep the reader attention and make it pleasant to read, as if you were explaining it to a friend who has never heard of the book before.
    The goal is to provide a deep understanding of the topic and its significance to people who are not familiar with the book.
    Do not repeat sentences or phrases from the book, but rather explain the concepts in your own words.
    Do not lose the context of the book and its themes.
    Use valid html tags to better format the text and make it easier to read. Absolutely avoid CSS and Markdown formatting.
    Keep a B2+ level of English.
  TEXT

  AUDIO_PROMPT = <<~TEXT
    Voice Affect: Calm, composed, and reassuring; project quiet authority and confidence.
    Tone: Sincere, empathetic, and gently authoritative—express genuine apology while conveying competence.
    Pacing: Steady and moderate; unhurried enough to communicate care, yet efficient enough to demonstrate professionalism.
    Emotion: Genuine empathy and understanding; speak with warmth, especially during apologies ("I'm very sorry for any disruption...").
    Pronunciation: Clear and precise, emphasizing key reassurances ("smoothly," "quickly," "promptly") to reinforce confidence.
    Pauses: Brief pauses after offering assistance or requesting details, highlighting willingness to listen and support.
  TEXT

  #
  # Entry point to generate a new text topic and audio recording for this entry.
  #
  # @param entry [HistoryEntry]
  # @return [Topic]
  #
  def self.run(entry)
    new.run(entry)
  end

  #
  # Generates a new text topic and audio recording for this entry
  # 1. If in development mode, returns a dummy topic
  # 2. Chooses a new topic based on the book and covered topics
  # 3. Generates a detailed description of the topic
  # 4. Generates audio if requested
  #
  # @param entry [HistoryEntry]
  # @return [Topic, nil] Returns a Topic object or nil if an error occurs
  #
  def run(entry)
    # return development_topic if development_mode?

    new_topic = choose_new_topic(entry.book, entry.covered_topics)
    if new_topic.nil? || new_topic.empty?
      LOGGER.error "Failed to generate a new topic for book: #{entry.book}"
      return nil
    end

    description = generate_post(entry.book, new_topic)
    if description.nil? || description.empty?
      LOGGER.error "Failed to generate a description for book: #{entry.book}"
      return nil
    end

    audio = generate_audio(remove_html_tags(description)) if entry.generate_audio

    Topic.new(
      id: SecureRandom.uuid,
      book: entry.book,
      topic: new_topic,
      audio:,
      description:
    )
  end

  private

  def client = AI_CLIENT

  def development_mode?
    ENV["ENVIRONMENT"] == "development"
  end

  def development_topic
    puts "Running in development mode, returning a dummy topic."
    Topic.new(
      id: SecureRandom.uuid,
      audio: File.read("audio/test.mp3"),
      book: "Thinking, fast and slow by Daniel Kahneman",
      topic: "test",
      description: "test<b/><b/>test new line"
    )
  end

  def choose_new_topic(book, covered_topics)
    response = client.chat(
      parameters: {
        model: "gemini-2.5-flash",
        messages: [
          {role: "user", content: pick_topic_prompt(book, covered_topics)}
        ],
        temperature: 1
      }
    ).dig("choices", 0, "message", "content")
    response.strip
  rescue => e
    puts "Error generating topic: #{e.message}"
    nil
  end

  def generate_post(book, topic)
    client.chat(
      parameters: {
        model: TEXT_MODEL,
        messages: [
          {role: "system", content: SYSTEM_PROMPT},
          {role: "user", content: user_prompt(book, topic)}
        ],
        temperature: 1
      }
    ).dig("choices", 0, "message", "content")
  rescue JSON::ParserError => e
    puts "Error parsing JSON response: #{e.message}\nResponse: #{response}"
    []
  end

  def generate_audio(text)
    client.audio.speech(
      parameters: {
        model: ENV["AUDIO_MODEL"],
        input: text,
        instructions: AUDIO_PROMPT,
        voice: "charon",
        response_format: "mp3",
        speed: 1.0
      }
    )
  rescue => e
    puts "Error generating audio: #{e.message}"
    []
  end

  def pick_topic_prompt(book, covered_topics)
    if covered_topics.empty?
      "Please choose a topic from the book #{book}. Only return the topic, no other text, explaining or commentary."
    else
      "Please choose a new topic from the book #{book}, avoiding the following topics: #{covered_topics.join(", ")}. Only return the topic, no other text, explaining or commentary."
    end
  end

  def user_prompt(book, topic)
    "The book is #{book} and the chosen topic is #{topic}"
  end

  def remove_html_tags(text)
    text.gsub(/<[^>]*>/, "").gsub("&nbsp;", " ").gsub("&amp;", "&").strip
  end
end
