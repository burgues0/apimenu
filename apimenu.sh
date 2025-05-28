#!/bin/bash

REPOS=("https://github.com/teste1/teste1.git" "https://github.com/teste2/teste2.git")

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

#todo
#> criar dockerfiles
#> subir api autenticacao
#> menu pra subir e derrubar as APIs