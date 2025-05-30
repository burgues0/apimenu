#!/bin/bash

REPOS=("https://github.com/levyath/Api_Gerenciamento_de_obras.git")
DOCKERFILES_DIR="./dockerfiles"

mkdir -p "$DOCKERFILES_DIR"

#clonando os repos
for repo in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo" .git)
    if [ ! -d "$REPO_NAME" ]; then
        git clone "$repo"
        echo "Repositório $REPO_NAME clonado!"
    else
        echo "Repositório $REPO_NAME já existe. Atualizando repositório a partir da main..."
        cd "$REPO_NAME" && git pull
    fi
done

cd ..

# Criando Dockerfiles para cada API
for repo in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo" .git)
    DOCKERFILE_PATH="$DOCKERFILES_DIR/Dockerfile_$REPO_NAME"

    if [ ! -d "$REPO_NAME" ]; then
        echo "Erro: Diretorio $REPO_NAME não encontrado. Pulando criação do Dockerfile..."
        continue
    fi

    if [ ! -f "$REPO_NAME/package.json" ]; then
        echo "Aviso: package.json não foi encontrado no repo $REPO_NAME."
    fi

    cat > "$DOCKERFILE_PATH" <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["npm", "start"]
EXPOSE 3000
EOF
    echo "Dockerfile criado para $REPO_NAME em $DOCKERFILE_PATH"
done

#todo
#> subir api autenticacao
#> menu pra subir e derrubar as APIs