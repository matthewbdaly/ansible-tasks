Ansible setup
-------------

To use these playbooks you need to install Ansible and the `dopy` module:

`sudo pip install ansible dopy`

You'll also need an account on Digital Ocean. You can then set the API token in `.bashrc` on Ubuntu or `.bash_profile` on a Mac using the following syntax:

`export DO_API_TOKEN="<YOUR_TOKEN_HERE>"`

The SSH Key IDs in `playbooks/roles/create_droplet/tasks/main.yml` are user-specific, so you need to change them. You can find the ID of your SSH key by inspecting the checkbox element for it on the New Droplet screen in Digital Ocean.

The task does create a DNS record for the new server, but this uses Digital Ocean's DNS service, so you still need to ensure you set them as the DNS servers for that domain.

The configuration settings are in `ansible.cfg`. You may need to change some of these - the remote_user setting will obviously be different, and the path to the private key file on a Mac will be `/User/<username>/.ssh/id_rsa` instead of that shown. The Python interpreter used will also differ - you may wish to try commenting out this line with a #.

To run the playbooks, you can switch to the appropriate directory and run the following command for the Wordpress setup:

`ansible-playbook playbooks/wpsetup.yml`

And the following for a Laravel app:

`ansible-playbook playbooks/laravel.yml`

It's set up to download an API backend I have on Github by default. To change this you need to amend the `git` role under `playbooks/roles/git/tasks/main.yml`.
