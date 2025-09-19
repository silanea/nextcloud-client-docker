name: Build Nextcloud GUI Docker Image

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build Docker image
        run: |
          docker build \
            --pull \
            -t your-dockerhub-username/nextcloud-gui:latest \
            .

      - name: Push Docker image
        run: |
          docker push your-dockerhub-username/nextcloud-gui:latest
