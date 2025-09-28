#!/bin/bash
set -e

echo "=== Market Watch Bot Setup ==="

# Prompt for credentials
read -p "Enter Polygon API Key: " POLYGON_API_KEY
read -p "Enter Redis URL [default: redis://redis:6379/0]: " REDIS_URL
REDIS_URL=${REDIS_URL:-redis://redis:6379/0}
read -p "Enter Alert Webhook URL (e.g., Slack/Discord): " ALERT_WEBHOOK
read -p "Enter Vault Address (or leave blank): " VAULT_ADDR
read -p "Enter Vault Token (or leave blank): " VAULT_TOKEN

# Create project root
PROJECT_DIR="market-watch-bot"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# ===== Docker Compose =====
cat << EOF > docker-compose.yml
version: "3.9"
services:
  bot:
      build: .
          env_file:
                - .env
                    depends_on:
                          - redis
                            redis:
                                image: redis:7
                                    ports:
                                          - "6379:6379"
                                          EOF

                                          # ===== Dockerfile =====
                                          cat << 'EOF' > Dockerfile
                                          FROM python:3.11-slim
                                          WORKDIR /app
                                          COPY requirements.txt .
                                          RUN pip install --no-cache-dir -r requirements.txt
                                          COPY . .
                                          CMD ["python", "app/main.py"]
                                          EOF

                                          # ===== Python Dependencies =====
                                          cat << EOF > requirements.txt
                                          requests
                                          redis
                                          pytest
                                          EOF

                                          # ===== Application Code =====
                                          mkdir -p app
                                          cat << 'EOF' > app/main.py
                                          import os, time, requests, redis, json

                                          REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
                                          ALERT_WEBHOOK = os.getenv("ALERT_WEBHOOK", "")
                                          VAULT_ADDR = os.getenv("VAULT_ADDR", "")
                                          VAULT_TOKEN = os.getenv("VAULT_TOKEN", "")
                                          POLYGON_API_KEY = os.getenv("POLYGON_API_KEY", "demo")

                                          rdb = redis.Redis.from_url(REDIS_URL)

                                          def fetch_stock_price(symbol="AAPL"):
                                              url = f"https://api.polygon.io/v2/aggs/ticker/{symbol}/prev?apiKey={POLYGON_API_KEY}"
                                                  try:
                                                          res = requests.get(url, timeout=5)
                                                                  if res.status_code == 200:
                                                                              data = res.json()
                                                                                          return data.get("results", [{}])[0].get("c")
                                                                                              except Exception as e:
                                                                                                      print("Error fetching price:", e)
                                                                                                          return None

                                                                                                          def send_alert(message):
                                                                                                              if not ALERT_WEBHOOK:
                                                                                                                      print("ALERT:", message)
                                                                                                                              return
                                                                                                                                  try:
                                                                                                                                          requests.post(ALERT_WEBHOOK, json={"text": message}, timeout=5)
                                                                                                                                              except Exception as e:
                                                                                                                                                      print("Error sending alert:", e)

                                                                                                                                                      def check_cross_reference():
                                                                                                                                                          price = fetch_stock_price("AAPL")
                                                                                                                                                              if price:
                                                                                                                                                                      cached = rdb.get("AAPL_LAST")
                                                                                                                                                                              if cached and abs(float(price) - float(cached)) > 5:
                                                                                                                                                                                          send_alert(f"⚠️ AAPL price anomaly detected: {price} vs {cached.decode()}")
                                                                                                                                                                                                  rdb.set("AAPL_LAST", price)
                                                                                                                                                                                                          return price

                                                                                                                                                                                                          def cross_reference_loop():
                                                                                                                                                                                                              while True:
                                                                                                                                                                                                                      check_cross_reference()
                                                                                                                                                                                                                              time.sleep(30)

                                                                                                                                                                                                                              if __name__ == "__main__":
                                                                                                                                                                                                                                  print("Starting Market Watch Bot...")
                                                                                                                                                                                                                                      cross_reference_loop()
                                                                                                                                                                                                                                      EOF

                                                                                                                                                                                                                                      # ===== Tests =====
                                                                                                                                                                                                                                      mkdir -p tests
                                                                                                                                                                                                                                      cat << 'EOF' > tests/test_bot.py
                                                                                                                                                                                                                                      import app.main as bot

                                                                                                                                                                                                                                      def test_fetch_stock_price():
                                                                                                                                                                                                                                          price = bot.fetch_stock_price("AAPL")
                                                                                                                                                                                                                                              assert price is None or isinstance(price, (int, float))

                                                                                                                                                                                                                                              def test_cross_reference_logic(monkeypatch):
                                                                                                                                                                                                                                                  calls = {}
                                                                                                                                                                                                                                                      monkeypatch.setattr(bot, "fetch_stock_price", lambda s="AAPL": 150.0)
                                                                                                                                                                                                                                                          monkeypatch.setattr(bot.rdb, "get", lambda k: b"140")
                                                                                                                                                                                                                                                              monkeypatch.setattr(bot.rdb, "set", lambda k, v: calls