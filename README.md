# 🧠 Brian RSS

Daily RSS feed for continuous learners. Brian RSS creates personalized learning content about your favorite books, delivered daily through RSS and audio formats.

Want to see it in action? Check out my personal feed at [brian.achris.me/rss](https://brian.achris.me/rss) 📚

![screenshot](readme/screenshot.jpeg)

## ✨ What is Brian RSS?

- Generates intelligent RSS feeds about books you love or want to read
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

- Ruby & Sinatra for the lightweight, fast API
- Docker for easy deployment and scaling
- OpenAI for intelligent content and audio generation
- Cron jobs for automated scheduling

## 🏗️ Quick Start

### Docker Setup (Recommended)

Build with Docker:

```bash
docker build -t brian-rss .
```

Configure your environment in `docker-compose.yml`:

```yaml
environment:
  FEED_TITLE: your-title # Your RSS feed title
  FEED_LINK: your-feed-channel-link # Your RSS feed URL
  FEED_DOMAIN: your-domain.com # Your domain name
  FEED_DESCRIPTION: awesome-description # Brief description of your feed
  MODEL: gpt-4 # OpenAI model to use
  OPENAI_ACCESS_TOKEN: sk-xxx # Your OpenAI API key
  AWS_ACCESS_KEY_ID: your-aws-key # AWS access key for Polly
  AWS_SECRET_ACCESS_KEY: your-aws-secret # AWS secret for Polly
  AWS_REGION: us-east-1 # AWS region for Polly
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

2. Access your feed:
   - RSS feed available at: `http://your-domain.com/rss`
   - Audio files at: `http://your-domain.com/audio/<filename>`
   - Daily updates at 6:00 AM UTC

## 🤝 Contributing

We welcome contributions! Here's how:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

GNU GPLv3 Licensed - Feel free to use and modify!
