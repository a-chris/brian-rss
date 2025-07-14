class HistoryEntry < Struct.new(:book, :covered_topics, :updated_at)
  def to_json(*_args)
    JSON.generate({
      book: book,
      covered_topics: covered_topics,
      updated_at: updated_at
    })
  end
end
