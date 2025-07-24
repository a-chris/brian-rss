FROM ruby:3.4.4-alpine AS builder

WORKDIR /app

COPY Gemfile* ./

RUN apk add --no-cache build-base yaml-dev libffi-dev && \
  bundle install

FROM ruby:3.4-alpine

WORKDIR /app

RUN touch /app/cron.log && chmod 644 /app/cron.log
RUN echo "0 6 * * * cd /app && ruby task.rb >> /app/cron.log 2>&1" | crontab -

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY . .

EXPOSE 4567

# # Use crond to run the cron jobs and start the server in main.rb
CMD ["sh", "-c", "crond -f & ruby main.rb"]
