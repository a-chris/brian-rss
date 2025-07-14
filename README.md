# 🧠 Brian

AI-powered RSS feeds for for book lovers and continuous learners. Brian RSS creates personalized learning content about your favorite books, delivered daily through RSS and audio formats.

My personal instance is available at [brian.achris.me/rss](https://brian.achris.me/rss), feel free to add it to your preferred RSS reader 😎

## ✨ What is Brian RSS?

Brian is your personal book companion that:

- Generates intelligent RSS feeds about books you love
- Creates audio recordings for easy listening
- Delivers fresh content daily
- Makes learning from books more engaging and interactive

## 🚀 Features

- AI-powered RSS feed generation
- Text-to-speech audio recordings
- Daily automated content updates
- Docker-ready deployment
- Simple JSON configuration

## 🛠️ Tech Stack

- Ruby & Sinatra for the core application
- Docker for containerization
- AI integration for content generation
- Automated scheduling with cron

## 🏗️ Quick Start

### Docker Setup (Recommended)

Build with Docker:

```bash
docker build -t brian-rss .
```

Fill the `docker-compose.yml` with your configuration and API keys:

```yaml
FEED_TITLE: your-title
FEED_LINK: your-feed-channel-link
FEED_DOMAIN: your-domain.com
FEED_DESCRIPTION: awesome-description
MODEL: gpt-4o
DEEP_SEEK_ACCESS_TOKEN: not-used-right-now
OPENAI_ACCESS_TOKEN: your-openai-access-token
```

Finally, run the container:

```bash
docker compose up -d
```

### Manual Setup

```bash
# Install dependencies
bundle install

# Start the application
ruby main.rb
```

## 📖 How to Use

1. Configure your reading list in `history.json`:

```json
[
  {
    "book": "Thinking, Fast and Slow by Daniel Kahneman",
    "covered_topics": ["Cognitive Biases and Heuristics"],
    "updated_at": "2024-01-01T10:00:00Z"
  }
]
```

2. Brian automatically generates new content daily at 6:00 AM UTC:
   - Fresh RSS feed entries for each book
   - Audio recordings for on-the-go learning
   - Intelligent insights and recordings

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

GNU GPLv3 Licensed - Feel free to use and modify!
