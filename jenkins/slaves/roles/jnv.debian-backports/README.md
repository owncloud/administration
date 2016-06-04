# [Debian/Ubuntu Backports with Ansible](https://github.com/jnv/ansible-role-debian-backports)

Adds backports repository for Debian and Ubuntu.

## Usage

Install via [Galaxy](https://galaxy.ansibleworks.com/):

```
ansible-galaxy install jnv.debian-backports
```

In your playbook:

```yaml
- hosts: all
  roles:
    # ...
    - jnv.debian-backports
```

The role uses [apt_repository module](http://docs.ansible.com/apt_repository_module.html) which has additional dependencies. I highly recommend to use [bootstrap-debian](https://github.com/cederberg/ansible-bootstrap-debian) role to setup common Ansible requirements on Debian-based systems.

You can use `default_release` option for [apt module](http://docs.ansible.com/apt_module.html) to install package from backports. For example:

```yaml
tasks:
  - apt: name=mosh state=present default_release={{ansible_distribution_release}}-backports
```

`ansible_distribution_release` variable contains release name, i.e. `precise` or `wheezy`.

## Variables

- `backports_uri`: URI of the backports repository; change this if you want to use a particular mirror.
    + Debian: `http://ftp.debian.org/debian`
    + Ubuntu: `http://archive.ubuntu.com/ubuntu`
- `backports_components`: Release and components for sources.list
    + Debian: `{{backports_distribution}}-backports backports main contrib non-free`
    + Ubuntu: `{{backports_distribution}}-backports main restricted universe multiverse`
