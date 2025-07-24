# 🧠 Brian RSS

Daily RSS feed for continuous learners. Brian RSS creates personalized learning content about your favorite books, delivered daily through RSS and audio formats.

Want to see it in action? Check out my personal feed at [brian.achris.me/rss](https://brian.achris.me/rss) 📚

Public Docker images is available at [Docker Hub](https://hub.docker.com/r/achris15/brian-rss).

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

### 👉 Docker Compose Run (Recommended)

You can use Docker Compose to quickly set up and run Brian RSS.

Start from the `docker-compose.yml` file present in the repository and personalize it with your environment variables.

```yml
environment:
  RACK_ENV: production
  ENVIRONMENT: production
  PORT: 4567
  FEED_TITLE: "Brian: achris RSS Feed"
  FEED_LINK: https://achris.me
  FEED_DOMAIN: brian.achris.me
  FEED_DESCRIPTION: AI-Generated RSS Feeds from books I would like to learn more about
  MODEL: gpt-4o
  OPENAI_ACCESS_TOKEN: your-openai-access-token
```

Then, start your Brian RSS instance with:

```bash
docker compose up -d
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
