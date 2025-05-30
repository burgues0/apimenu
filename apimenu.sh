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
        echo "Repositório $REPO_NAME já existe."
    fi
done

# Criando Dockerfiles para cada API
for repo in "${REPOS[@]}"; do
    REPO_NAME=$(basename "$repo" .git)
    DOCKERFILE_PATH="$DOCKERFILES_DIR/Dockerfile_$REPO_NAME"

    cat > "$DOCKERFILE_PATH" <<EOF
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
EOF
    echo "Dockerfile criado para $REPO_NAME em $DOCKERFILE_PATH"
done

#todo
#> subir api autenticacao
#> menu pra subir e derrubar as APIs