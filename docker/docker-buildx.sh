# build docker image for multi-platforms
# https://github.com/docker/buildx

mkdir -p ~/.docker/cli-plugins
curl -sSL https://github.com/docker/buildx/releases/download/v0.5.1/buildx-v0.5.1.linux-amd64 -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

docker run --privileged --rm tonistiigi/binfmt --install all

# docker buildx build --platform linux/amd64,linux/arm64 .
