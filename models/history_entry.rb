require "json"

class HistoryEntry < Struct.new(:book, :generate_audio, :covered_topics, :updated_at, keyword_init: true)
  def initialize(**)
    super
    self.generate_audio = true if generate_audio.nil?
    self.covered_topics ||= []
  end

  def to_json(*_args)
    JSON.generate({
      book:,
      generate_audio:,
      covered_topics:,
      updated_at:
    })
  end
end
