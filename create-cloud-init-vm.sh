#!/bin/bash

# Function to check the checksum of the downloaded image
check_checksum() {
  local image_path="$1"
  local expected_checksum="$2"
  local checksum_type="$3"  # e.g., sha256, sha512

  if [[ -z "$expected_checksum" ]]; then
    echo "Skipping checksum verification (no checksum provided)."
    return 0  # Return success if no checksum is provided
  fi

  local calculated_checksum
  if [[ "$checksum_type" == "sha256" ]]; then
    calculated_checksum=$(sha256sum "$image_path" | awk '{print $1}')
  elif [[ "$checksum_type" == "sha512" ]]; then
      calculated_checksum=$(sha512sum "$image_path" | awk '{print $1}')
  else
    echo "Error: Unsupported checksum type '$checksum_type'. Supported types are sha256 and sha512"
    return 1
  fi

  if [[ "$calculated_checksum" == "$expected_checksum" ]]; then
    echo "Checksum verification successful."
    return 0
  else
    echo "Error: Checksum mismatch. Expected: $expected_checksum, Calculated: $calculated_checksum"
    return 1
  fi
}


# Prompt for cloud image URL, template ID, storage location, checksum, and checksum type
read -p "Enter the URL of the cloud image: " cloud_image_url
read -p "Enter the desired template ID: " template_id

# Display available storage locations for images and prompt for selection
echo "Available storage locations for images:"
pvesm status --content images | awk '{print $1}' | while read storage; do
  echo "- $storage"
done

read -p "Enter the desired storage location: " storage_location

read -p "Enter the expected checksum (or leave blank to skip): " expected_checksum
read -p "Enter the checksum type (sha256 or sha512, leave blank if no checksum): " checksum_type

# Check if the template ID already exists
if qm status "$template_id" &> /dev/null; then
  echo "Error: VM/Template with ID $template_id already exists."
  exit 1
fi

# Check if the storage location is valid for images
if ! pvesm status --content images | grep -q "^$storage_location "; then
  echo "Error: Storage location '$storage_location' is not valid for images."
  exit 1
fi

# Download the cloud image
wget "$cloud_image_url"

# Extract the image name from the URL
image_name=$(basename "$cloud_image_url")

# Get the full path to the downloaded image
image_path=$(pwd)/"$image_name"

# Check the checksum (if provided)
if ! check_checksum "$image_path" "$expected_checksum" "$checksum_type"; then
  echo "Error: Checksum verification failed."

  read -r -p "Do you want to remove the downloaded image '$image_name'? (y/N): " response
  case "$response" in
    y|Y )
      rm "$image_name"
      echo "Image '$image_name' removed."
      ;;
    * )
      echo "Image '$image_name' not removed."
      ;;
  esac

  exit 1
fi

# Create a new VM
qm create "$template_id" --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci

# Import the downloaded disk to the specified storage - Use the FULL path here!
qm set "$template_id" --scsi0 "$storage_location":0,import-from="$image_path"

# Add Cloud-Init CD-ROM drive to the specified storage
qm set "$template_id" --ide2 "$storage_location":cloudinit

# Set boot order to SCSI
qm set "$template_id" --boot order=scsi0

# Configure serial console (optional, adjust if needed)
qm set "$template_id" --serial0 socket --vga serial0

# Convert the VM to a template
qm template "$template_id"

# Clean up the downloaded image (optional)
read -r -p "Do you want to remove the downloaded image '$image_name'? (y/N): " response
case "$response" in
y|Y )
    rm "$image_name"
    echo "Image '$image_name' removed."
    ;;
* )
    echo "Image '$image_name' not removed."
    ;;
esac

echo "Template $template_id created successfully on storage '$storage_location'."