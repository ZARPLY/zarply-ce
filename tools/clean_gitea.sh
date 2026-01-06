#!/bin/bash

docker system prune -f
# Current date in seconds since epoch
current_date=$(date +%s)

# Define an exclusion list (repositories that should not be deleted)
exclusion_list=(
    "edoburu/pgbouncer"                        # Exclude all tags of this repository
    "redis"                                    # Exclude all tags of this repository
    # Add more repositories to exclude if needed
)

# Function to check if a tag is in the exclusion list
is_excluded() {
    local image_tag=$1
    local repository=$(echo "$image_tag" | awk -F: '{print $1}') # Extract repository name

    for excluded in "${exclusion_list[@]}"; do
        if [[ "$repository" == "$excluded" ]]; then
            return 0 # True: image is excluded
        fi
    done
    return 1 # False: image is not excluded
}

# Fetch image IDs to delete: images not tagged as 'latest' or images older than 1 week
images_to_delete=$(docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.CreatedSince}}' | while read -r line; do
    tag=$(echo "$line" | awk '{print $1}')
    image_id=$(echo "$line" | awk '{print $2}')
    created_since=$(echo "$line" | awk '{print $3}')

    # Check if the image is in the exclusion list
    if is_excluded "$tag"; then
        echo "Skipping excluded image: $tag"
        continue
    fi

    # Check if the image is not tagged as 'latest' or is older than 1 week
    if [[ "$tag" != *":latest" ]] || [[ "$created_since" == "weeks"* || "$created_since" == "months"* || "$created_since" == "years"* ]]; then
        echo "$image_id"
    fi
done)

# Check if there are images to delete
if [ -z "$images_to_delete" ]; then
    echo "No images to delete. Only 'latest' and recent images are present."
else
    # Delete each image
    for image_id in $images_to_delete; do
        echo "Deleting image ID: $image_id"
        docker rmi "$image_id"
    done
fi

echo "Script complete."
