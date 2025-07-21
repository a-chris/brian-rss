# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.4"

gem "puma", "~> 6.6"
gem "rackup", "~> 2.2"
gem "ruby-openai"
gem "sinatra", "~> 4.1"
gem "sinatra-cors"
gem "rss", "~> 0.3.1"
gem "htmlentities"

group :development do
  gem "debug", ">= 1.0.0"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "rerun"
  gem "dotenv"
end

group :test do
  gem "timecop"
  gem "rspec", "~> 3.13"
  gem "rspec-mocks", "~> 3.13"
end
