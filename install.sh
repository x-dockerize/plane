#!/usr/bin/env bash
set -e

ENV_EXAMPLE=".env.example"
ENV_FILE=".env"

# --------------------------------------------------
# Kontroller
# --------------------------------------------------
if [ ! -f "$ENV_EXAMPLE" ]; then
  echo "❌ $ENV_EXAMPLE bulunamadı."
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "✅ $ENV_EXAMPLE → $ENV_FILE kopyalandı"
else
  echo "ℹ️  $ENV_FILE mevcut, güncellenecek"
fi

# --------------------------------------------------
# Yardımcı Fonksiyonlar
# --------------------------------------------------
gen_password() {
  openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 20
}

gen_secret_key() {
  openssl rand -hex 32
}

set_env() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

set_env_once() {
  local key="$1"
  local value="$2"

  local current
  current=$(grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2-)

  if [ -z "$current" ]; then
    set_env "$key" "$value"
  fi
}

# --------------------------------------------------
# Kullanıcıdan Gerekli Bilgiler
# --------------------------------------------------
read -rp "PLANE_SERVER_HOSTNAME (örn: board.example.com): " PLANE_SERVER_HOSTNAME

echo
echo "--- S3 / Object Storage Ayarları ---"
read -rp "AWS_REGION (örn: ams3): " AWS_REGION
read -rp "AWS_S3_ENDPOINT_URL (örn: https://ams3.digitaloceanspaces.com): " AWS_S3_ENDPOINT_URL
read -rp "AWS_S3_BUCKET_NAME: " AWS_S3_BUCKET_NAME
read -rp "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
read -rsp "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
echo

echo
echo "--- Veritabanı ---"
read -rp "PGHOST (boş bırakılırsa: postgres): " INPUT_PGHOST
PGHOST="${INPUT_PGHOST:-postgres}"
read -rp "POSTGRES_USER (boş bırakılırsa: plane): " INPUT_POSTGRES_USER
POSTGRES_USER="${INPUT_POSTGRES_USER:-plane}"
read -rsp "POSTGRES_PASSWORD: " POSTGRES_PASSWORD
echo

# --------------------------------------------------
# .env Güncelle
# --------------------------------------------------
set_env PLANE_SERVER_HOSTNAME  "$PLANE_SERVER_HOSTNAME"

set_env AWS_REGION             "$AWS_REGION"
set_env AWS_S3_ENDPOINT_URL    "$AWS_S3_ENDPOINT_URL"
set_env AWS_S3_BUCKET_NAME     "$AWS_S3_BUCKET_NAME"
set_env AWS_ACCESS_KEY_ID      "$AWS_ACCESS_KEY_ID"
set_env AWS_SECRET_ACCESS_KEY  "$AWS_SECRET_ACCESS_KEY"

set_env PGHOST            "$PGHOST"
set_env POSTGRES_USER     "$POSTGRES_USER"
set_env POSTGRES_PASSWORD "$POSTGRES_PASSWORD"

# Secret'lar — mevcut değerlerin üzerine yazılmaz
set_env_once SECRET_KEY             "$(gen_secret_key)"
set_env_once LIVE_SERVER_SECRET_KEY "$(gen_secret_key)"
set_env_once RABBITMQ_PASSWORD      "$(gen_password)"

# --------------------------------------------------
# Sonuçları Göster
# --------------------------------------------------
echo
echo "==============================================="
echo "✅ Plane .env başarıyla hazırlandı!"
echo "-----------------------------------------------"
echo "🌐 Hostname      : https://$PLANE_SERVER_HOSTNAME"
echo "-----------------------------------------------"
echo "==============================================="
