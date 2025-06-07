#!/bin/bash

REPOS=(
    "https://github.com/levyath/Api_Gerenciamento_de_obras.git"
)

DOCKERFILES_DIR="./dockerfiles"
API_ROOT_DIR="./"
API_PORT=3001
DOCKER_COMPOSE="docker-compose.yml"
DOTENV=".env"

echo "+++ Preparando o ambiente +++"
rm -rf "$DOCKERFILES_DIR" "$DOCKER_COMPOSE"
mkdir -p "$DOCKERFILES_DIR"

cat <<EOF > "$DOTENV"
NODE_ENV=development
DB_HOST=db-postgres
DB_PORT=5432
DB_EXT_PORT=15432
DB_DATABASE=postgres
DB_USER=postgres
DB_PASSWORD=postgres
EOF

echo "+++ Clonando e atualizando repositórios +++"
for repo_url in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo_url" .git)

    if [ ! -d "$API_ROOT_DIR/$REPO_NAME" ]; then
        git clone "$repo_url" "$API_ROOT_DIR/$REPO_NAME"
        cp "$DOTENV" "$API_ROOT_DIR/$REPO_NAME"
        echo "Repositório '$REPO_NAME' clonado."
    else
        echo "Repositório '$REPO_NAME' já existe. Atualizando..."
        (cd "$API_ROOT_DIR/$REPO_NAME" && git pull) || \
        (echo "Erro ao atualizar '$REPO_NAME'.")
    fi
done

echo "+++ Gerando '$DOCKER_COMPOSE' +++"
cat <<EOF > "$DOCKER_COMPOSE"
services:
  db-postgres:
    image: postgres:14-alpine
    restart: always
    environment:
      POSTGRES_DB: \${DB_DATABASE}
      POSTGRES_USER: \${DB_USER}
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "\${DB_EXT_PORT}:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${DB_USER} -d \${DB_DATABASE}"]
      interval: 5s
      timeout: 5s
      retries: 5

EOF

CURRENT_PORT=$API_PORT

echo "+++ Adicionando APIs ao ${DOCKER_COMPOSE} +++"
for repo_url in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo_url" .git)
    SERVICE_NAME=$(echo "$REPO_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    DOCKERFILE_NAME="Dockerfile-$REPO_NAME"

    echo "+++ Criando Dockerfile para '$REPO_NAME' em '$DOCKERFILES_DIR/$DOCKERFILE_NAME' +++"
    cat <<EODOCKERFILE > "$DOCKERFILES_DIR/$DOCKERFILE_NAME"
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build || true

EXPOSE 3000

CMD [ "npm", "run", "start:dev" ]
EODOCKERFILE

    cat <<EOF >> "$DOCKER_COMPOSE"

  api-$SERVICE_NAME:
    build:
      context: "./$REPO_NAME"
      dockerfile: "$DOCKERFILES_DIR/$DOCKERFILE_NAME"
    restart: always
    ports:
      - "$CURRENT_PORT:3000"
    environment:
      DATABASE_URL: postgres://\${DB_USER}:\${DB_PASSWORD}@\${DB_HOST}:5432/\${DB_DATABASE}
      NODE_ENV: \${NODE_ENV:-development}
    depends_on:
      db-postgres:
        condition: service_healthy
    volumes:
      - "./$REPO_NAME:/app"
      - "/app/node_modules"

EOF
    CURRENT_PORT=$((CURRENT_PORT + 1))
done

cat <<EOF >> "$DOCKER_COMPOSE"

volumes:
  pgdata:
EOF



#compose gerado, e dockerfiles automatizados