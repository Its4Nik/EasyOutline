# EasyOutline v2
A quick start for [Outline Wiki](https://github.com/outline/outline)
![image](https://github.com/Its4Nik/EasyOutline/blob/dev-patch/docs/Asciicinema.gif)

# Requirements:
- bash
- mktemp
- docker
- openssl
- wget
- git
- awk
- sed
- cut

## How to?
A simple one liner :)
```bash
curl -fsSlo setup.sh https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/setup.sh && bash setup.sh
```

This will generate random passwords for encryption using `openssl rand -hex 32`
For more info on how to setup google developer OICD look at this: https://github.com/Its4Nik/EasyOutline/blob/main/README-google.md

This is a shell script which ask you for a SMTP Credentials and configures local storage inside the docker.env file, that outline uses.

## Why did I do this?

I struggled with the setup of Outline TBH and wanted it to make it as easy as it can get.
