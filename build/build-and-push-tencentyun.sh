#!/bin/bash
set -eux;

# Define the private repository
repository="ccr.ccs.tencentyun.com/huansky/tengine";

# Find all Dockerfiles in the mainline directory
dockerfiles=$(find mainline -type f -name "Dockerfile*");

# Loop through each Dockerfile, build and push the image
for dockerfile in $dockerfiles; do
    # Extract the version from the Dockerfile's directory name
    version=$(basename "$(dirname "$dockerfile")");
    
    echo "Building and pushing tengine:$version...";
    
    # Cross compile the Dockerfile for multiple environments
    # platforms=("linux/amd64" "linux/arm/v7" "linux/arm64/v8");
    # platforms=("linux/amd64" "linux/arm64");
    platforms=("linux/amd64");
    # echo "Building tengine:$version";
    platforms_csv=$(IFS=,; echo "${platforms[*]}");

    # Build the Docker image for the specified platforms
    # Use --platform to specify the target platforms
    # Use --push to push the image directly to the repository
    docker buildx build --platform "$platforms_csv" -f "$dockerfile" -t "$repository:$version" --push .;

    # Build the Docker image for the default platform
    # docker build -f "$dockerfile" -t "$repository:$version" --build-arg ALL_PROXY="http://192.168.199.199:7890" .;
    
    # Push the Docker image to the private repository
    docker push "$repository:$version";

    echo "Successfully pushed tengine:$version to $repository";
done