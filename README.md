# proxmox-cloud-init
Downloads a cloud-init supported qcow or ISO to proxmox and creates a template for you with a cloud-init disk attached.


# Usage
Execute this script on your Proxmox host, either in the web shell or via SSH. You'll need to provide a wget compatible download link and an optional checksum for the downloaded image. Ubuntu server's standard ISO is compatible so I'll use that as an example here:

## Download link
https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso

## SHA256 Checksum
d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d

**NOTE:** *This checksum is accurate as of writing, but will almost certainly change if you're using this at a later time. The checksum is optional.*
