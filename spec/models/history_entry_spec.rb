# frozen_string_literal: true

require "spec_helper"

require_relative "../../models/history_entry"

RSpec.describe HistoryEntry do
  let(:params) do
    {
      book: "test",
      generate_audio: false,
      covered_topics: "test",
      updated_at: Time.now
    }
  end

  it "is correctly initialized when all fields provided" do
    entry = HistoryEntry.new(**params)
    expect(entry.book).to eq params[:book]
    expect(entry.generate_audio).to eq params[:generate_audio]
    expect(entry.covered_topics).to eq params[:covered_topics]
    expect(entry.updated_at).to eq params[:updated_at]
  end

  it "is correctly initialized when optional fields are not provided" do
    entry = HistoryEntry.new(**params.slice(:book, :updated_at))
    expect(entry.book).to eq params[:book]
    expect(entry.generate_audio).to be_truthy
    expect(entry.covered_topics).to eq []
    expect(entry.updated_at).to eq params[:updated_at]
  end
end
