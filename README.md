# EasyOutline
A quick start for Outline WIKI and iFramely

# Requirements:

- google developer OpenID (once while setting up)
- SMTP Server (or you use google)
- git
- docker + docker-compose / docker compose commands

### Why google?

Well we first have to create a user using OpenID, and google is pretty easy to setup.
After we logged in with google we are going to invite a new member.

## iFramely setup

This pulls a Dockerfile (hosted inside ./iframely/dockerfile)
And builds it as iframely:latest

## Outline Setup

This is a shell script which ask you for a SMTP Credentials and configures local storage inside the docker.env file, that outline uses.

## Why did I do this?

I struggled with the setup of Outline TBH and wanted it to make it as easy as it can get.
