# Build Flutter web and serve it via nginx
# Note: --dart-define values are compiled into the JS bundle.
# Do NOT treat API keys here as secret for client-side apps.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY
ARG DEEPSEEK_BASE_URL
ARG DEEPSEEK_API_KEY
ARG HUGGINGFACE_BASE_URL
ARG HUGGINGFACE_API_KEY
ARG HUGGINGFACE_DEFAULT_MODEL

RUN flutter build web --release \
  --base-href / \
  --no-wasm-dry-run \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=DEEPSEEK_BASE_URL=${DEEPSEEK_BASE_URL} \
  --dart-define=DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY} \
  --dart-define=HUGGINGFACE_BASE_URL=${HUGGINGFACE_BASE_URL} \
  --dart-define=HUGGINGFACE_API_KEY=${HUGGINGFACE_API_KEY} \
  --dart-define=HUGGINGFACE_DEFAULT_MODEL=${HUGGINGFACE_DEFAULT_MODEL}

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
