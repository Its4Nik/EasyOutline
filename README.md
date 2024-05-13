# EasyOutline
A quick start for Outline WIKI and iFramely
![image](https://github.com/Its4Nik/EasyOutline/assets/106100177/15932c08-e701-4d84-98f1-f240f01f3338)

# Requirements:

- google developer OpenID (once while setting up): [OpenID Setup](https://github.com/Its4Nik/EasyOutline/blob/main/README-google.md)
- SMTP Server (or you use google)
- git
- docker + docker-compose / docker compose commands

## How to?
```bash
# 1.
git clone https://github.com/Its4Nik/EasyOutline/

# 2.
cd EasyOutline

# 3.
bash setup.sh
```

This will generate random passwords for encryption using `openssl rand -hex 32`
For more info on how to setup google developer OICD look at this: https://github.com/Its4Nik/EasyOutline/blob/main/README-google.md

### Why google?

Well we first have to create a user using OpenID, and google is pretty easy to setup.
After we logged in with google we are going to invite a new member.

## iFramely setup

This pulls a Dockerfile (directly from the iframe repo)
And builds it as iframely:latest

## Outline Setup

This is a shell script which ask you for a SMTP Credentials and configures local storage inside the docker.env file, that outline uses.

## Why did I do this?

I struggled with the setup of Outline TBH and wanted it to make it as easy as it can get.
