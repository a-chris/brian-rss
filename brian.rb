# frozen_string_literal: true

require "securerandom"

require_relative "client"
require_relative "models/topic"

class Brian
  MODEL = ENV["MODEL"]

  SYSTEM_PROMPT = <<~TEXT
    Create a detailed analysis of the topic chosen by the user, including the whys, how and what results.

    Do not add commentary or colloquial phrases, just focus on the topic itself.
    The analysis should start by explaining the idea or concept very clearly and with simple terms, assume the user didn't read the book.
    It could be useful to make practical examples with real-world and actionable insights if the topic allows them.
    Be engaging and even funny to keep the reader attention and make it pleasant to read, as if you were explaining it to a friend who has never heard of the book before.
    The goal is to provide a deep understanding of the topic and its significance to people who are not familiar with the book.
    Do not repeat sentences or phrases from the book, but rather explain the concepts in your own words. Do not lose the context of the book and its themes.
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

  def self.run(book, covered_topics = [])
    new.run(book, covered_topics)
  end

  def run(book, covered_topics = [])
    return development_topic if development_mode?

    topic = choose_topic(book, covered_topics)
    return if topic.nil? || topic.empty?

    description = generate_post(book, topic)
    return unless topic && description

    audio = generate_audio(remove_html_tags(description))
    Topic.new(
      id: SecureRandom.uuid,
      book:,
      topic:,
      audio:,
      description:
    )
  end

  private

  def client = OPENAI_CLIENT

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

  def choose_topic(book, covered_topics)
    response = client.chat(
      parameters: {
        model: MODEL,
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
        model: MODEL,
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
        model: "tts-1",
        input: text,
        instructions: AUDIO_PROMPT,
        voice: "shimmer",
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
