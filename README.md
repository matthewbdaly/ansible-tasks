Ansible setup
-------------

To use these playbooks you need to install Ansible and the `dopy` module:

`sudo pip install ansible dopy`

You'll also need an account on Digital Ocean. You can then set the API token in `.bashrc` on Ubuntu or `.bash_profile` on a Mac using the following syntax:

`export DO_API_TOKEN="<YOUR_TOKEN_HERE>"`

The SSH Key IDs in `playbooks/roles/create_droplet/tasks/main.yml` are user-specific, so you need to change them. You can find the ID of your SSH key by inspecting the checkbox element for it on the New Droplet screen in Digital Ocean.

The task does create a DNS record for the new server, but this uses Digital Ocean's DNS service, so you still need to ensure you set them as the DNS servers for that domain.
