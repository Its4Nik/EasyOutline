#!/bin/bash
# EasyOutline - A Bash script for setting up Outline Wiki
# Copyright (c) 2024 https://github.com/its4nik

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# <-------------------------------------------------------------------------->

# Initialize Array
dependencies=("mktemp" "docker" "openssl" "wget" "git" "awk" "sed" "cut")
missing_deps=()

#
compose_file="https://raw.githubusercontent.com/Its4Nik/EasyOutline/main/docker-compose.yaml"
local_ip="$(curl -4 https://ip.hetzner.com)"
guided_install="true"
TODO="$(mktemp)"

# Database defaults
POSTGRES_PASSWORD=""
POSTGRES_PORT="5432"
REDIS_PORT="6379"

# Colors:
lime="\033[38;5;10m"
red="\033[38;5;9m"
grey="\033[38;5;244m"
blue="\033[38;5;12m"
cyan="\033[38;5;50m"
nc="\033[0m"

hostname="$(hostname)"

# <-------------------------------------------------------------------------->
# "Splashscreen"
welcome() {
    clear
    if command -v figlet >/dev/null; then
        if command -v lolcat >/dev/null; then
            figlet -tc "EasyOutline V2" | lolcat
        else
            figlet -tc "EasyOutline V2"
        fi
    else
        echo "> > > EasOutline V2 < < <"
    fi

    echo -e "
EasyOutline aims to provide a smooth Outline Wiki Install.
This project is fully written in Bash and there are almost no Cloud Dependencies Involved.

Before we continue, do you have these Dependencies at reach?

${red}! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !${nc} 
${red}! ${nc}These are only needed for the installation shown on github.${red} !${nc}
${red}! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !${nc} 

- A SMTP Server for E-Mail 'Magic-SignIn'
- Google Developer Console, used for first SignIn
    
All other software dependencies have been checked and automagically installed.

EasyOutline is a Interactive Setup install, you can choose what you want and what not.

EasyOutline works inside a fully bash contained 'shell', it's not a real shell, you only have acces to some commands.

Type 'help' so them.

The installation is guided, to deactive run 'unguided'
"
}

# <-------------------------------------------------------------------------->
# Function to define the package manager

install_dependencies() {
    if [[ ! -f /etc/os-release ]]; then
        echo "Couldn't fetch operating system, please install dependencies manually."
        return 1
    fi

    os_release=$(cat /etc/os-release)

    local ID
    local ID_LIKE

    ID=$(echo "$os_release" | grep '^ID=' | cut -d'=' -f2 | tr -d '"')
    ID_LIKE=$(echo "$os_release" | grep '^ID_LIKE=' | cut -d'=' -f2 | tr -d '"')

    case "$ID" in
    ubuntu | debian) install_cmd="sudo apt-get install -y" ;;
    fedora) install_cmd="sudo dnf install -y" ;;
    centos | rhel) install_cmd="sudo yum install -y" ;;
    arch | manjaro) install_cmd="sudo pacman -S --noconfirm" ;;
    suse | opensuse) install_cmd="sudo zypper install -y" ;;
    alpine) install_cmd="sudo apk add" ;;
    *)
        case "$ID_LIKE" in
        debian) install_cmd="sudo apt-get install -y" ;;
        rhel | centos | fedora) install_cmd="sudo yum install -y" ;;
        arch) install_cmd="sudo pacman -S --noconfirm" ;;
        suse) install_cmd="sudo zypper install -y" ;;
        *)
            echo "Unknown OS, please install dependencies manually."
            return 1
            ;;
        esac
        ;;
    esac

    echo -e "Do you want to use this: '${red}$install_cmd${nc}' as install command? ${grey}(default: yes)${nc}"
    read -r -n 1 -p "(y/n): " conf
    echo
    case "$conf" in
    n | N)
        echo "Please install your dependencies manually."
        return 1
        ;;
    *) true ;;
    esac

    for dependency in "${missing_deps[@]}"; do
        $install_cmd "$dependency"
    done
}

# <-------------------------------------------------------------------------->
# Function to test if all dependencies are installed

get_dependencies() {
    clear
    echo "Checking dependencies:"
    local missing_dep="false"

    for dep in "${dependencies[@]}"; do
        if command -v "$dep" >/dev/null; then
            echo -e "${lime}✓ $dep found${nc}"
        else
            echo -e "${red}✗ $dep not found${nc}"
            missing_dep="true"
            missing_deps+=("$dep")
        fi
    done

    if [[ "$missing_dep" = "true" ]]; then
        echo -e "Do you want to install all missing dependencies? ${grey}(default: yes)${nc}"
        read -r -n 1 -p "(y/n): " conf
        echo

        case "$conf" in
        n | N) true ;;
        *) install_dependencies ;;
        esac
    fi
}

# <-------------------------------------------------------------------------->
# Shell prompt

outshell() {
    echo
    echo -e "${cyan}$USER${nc} ${grey}at${nc} ${blue}$hostname${nc} ${grey}in${nc} ${cyan}$(pwd)${nc}"
    echo -ne "${grey}> ${nc}"
    read -r input

    process_prompt "$input"
}

# <-------------------------------------------------------------------------->
# Help screen
help_prompts() {
    echo -e "Usage: [${cyan}command${nc}] [${blue}sub-command${nc}]
${nc}
${nc}Commands:
${nc}  ${cyan}unguided           ${grey}Deactivate Guided install
${nc}  ${cyan}cd                 ${grey}Change directories
${nc}  ${cyan}clear              ${grey}Clears the terminal
${nc}  ${cyan}ls                 ${grey}List directories
${nc}  ${cyan}mkdir              ${grey}Make directories
${nc}  ${cyan}rmdir              ${grey}Force remove directory with everything in it (unrecommended)
${nc}  ${cyan}install            ${grey}Install Outline in the current working directory
${nc}  ${cyan}configure${nc} [${blue}sub-command${nc}]
${nc}    ${blue}port             ${grey}Configure the local port of Outline
${nc}    ${blue}fqdn             ${grey}Configure the domain where Outline is reachable
${nc}
${nc}  ${cyan}oidc${nc} [${blue}sub-command${nc}]
${nc}    ${blue}id               ${grey}Set the ID of the OIDC client
${nc}    ${blue}secret           ${grey}Set the secret
${nc}    ${blue}auth             ${grey}Set the authentication URI
${nc}    ${blue}token            ${grey}Set the token URI
${nc}    ${blue}info             ${grey}Set the userinfo URI
${nc}    ${blue}logout           ${grey}Set the logout URI (can be blank)
${nc}    ${blue}remove           ${grey}Remove all OIDC lines from the configuration file
${nc}    ${blue}get              ${grey}Show all current OIDC parameters
${nc}
${nc}  ${cyan}smtp${nc} [${blue}sub-command${nc}]
${nc}    ${blue}host             ${grey}Set the SMTP host location (IP or domain)
${nc}    ${blue}port             ${grey}Set the SMTP port
${nc}    ${blue}user             ${grey}Set the user for sending mails
${nc}    ${blue}pass             ${grey}Set the password for the user
${nc}    ${blue}from             ${grey}Set the from email address
${nc}    ${blue}reply            ${grey}Set the reply email address
${nc}    ${blue}remove           ${grey}Remove all SMTP lines from the configuration file
${nc}    ${blue}get              ${grey}Get all SMTP configuration infos
${nc}"
}

# <-------------------------------------------------------------------------->
# Process the user's input
process_prompt() {
    local prompt
    local arg
    local input
    input="$1"
    prompt="$(echo "$input" | cut -d' ' -f1)"
    arg="$(echo "$input" | cut -d' ' -f2-)"

    case "$prompt" in
    configure) configure_outline "$arg" ;;
    oidc) configure_oidc "$arg" ;;
    smtp) configure_smtp "$arg" ;;
    install) install_docker_compose_and_postgres_and_redis ;;
    rmdir) rm -r "$arg" || echo -e "Not possible to delete $arg" ;;
    mkdir) mkdir "$arg" || echo -e "Creating $arg not possible" ;;
    clear) clear ;;
    quit | exit) exit 0 ;;
    ls) ls ;;
    cd) cd "$arg" || echo -e "${red} $arg not possible to cd into here.${nc}" ;;
    help | HELP | Help) help_prompts ;;
    unguided) guided_install=false ;;
    *)
        if [[ -z "$prompt" ]]; then
            true
        else
            echo -e "${red}Command not found, try '${nc}help${red}' for help.${nc}"
        fi
        ;;
    esac
}

# <-------------------------------------------------------------------------->
# Gives the user time to read the first "pop up"
wait_to_read() {
    local spinner=("/" "-" "\\" "|")
    local delay=0.1

    echo -n "Loading...  "
    for ((i = 0; i < 5; i++)); do
        for j in "${spinner[@]}"; do
            echo -ne "\b$j"
            sleep $delay
        done
    done
}

# <-------------------------------------------------------------------------->
# Basic "install" of the necessariy docker compose
install_docker_compose_and_postgres_and_redis() {
    wget -q "$compose_file"

    echo
    echo "Do you want to use a random generated password for postgres?"
    read -r -p "(y/n): " conf
    case "$conf" in
    n | N) get_postgres_key "n" ;;
    *) get_postgres_key "y" ;;
    esac

    echo "Do you want to use a custom postgres port? (Default: 5432)"
    read -r -p "(y/n): " conf
    if [[ ! "$conf" = "n" ]]; then
        echo
        read -r -p "Your port: " POSTGRES_PORT
        custom_postgres_docker_port "$POSTGRES_PORT"
    fi

    echo "Do you want to use a custom redis port? (Default: 6379)"
    read -r -p "(y/n): " conf
    if [[ ! "$conf" = "n" ]]; then
        echo
        read -r -p "Your port: " REDIS_PORT
        custom_redis_docker_port "$REDIS_PORT"
    fi

    run_default_env_install

    {
        echo "# ------------------------------ #"
        echo "# All of Postgres and Redis Conf #"
        echo "# ------------------------------ #"
        echo "POSTGRES_PASSWORD: '$POSTGRES_PASSWORD'"
        echo "POSTGRES_USER: 'outlinedb'"
        echo "POSTGRES_DB: 'outline'"
        echo "DATABASE_URL: postgres://outlinedb:${POSTGRES_PASSWORD}@${local_ip}:${POSTGRES_PORT}/outline"
        echo "DATABASE_CONNECTION_POOL_MIN=1"
        echo "DATABASE_CONNECTION_POOL_MAX="
        echo "PGSSLMODE=disable"
        echo "REDIS_URL=redis://${local_ip}:${REDIS_PORT}"
        echo
    } >>outline.env
}

# <-------------------------------------------------------------------------->
# Get postgres key
get_postgres_key() {
    local random="$1"

    touch outline.env

    if [[ "$random" = "y" ]]; then
        POSTGRES_PASSWORD="$(openssl rand -hex 32)"
    else
        read -r -p "Please enter your key: " POSTGRES_PASSWORD
    fi
}

# <-------------------------------------------------------------------------->
# default env config
run_default_env_install() {
    mkdir easy-outline
    local SECRET_KEY
    local UTILS_SECRET

    SECRET_KEY="$(openssl rand -hex 32)"
    UTILS_SECRET="$(openssl rand -hex 32)"

    {
        echo "# ------------------------------------------ #"
        echo "# Deafult configuration, please don't change #"
        echo "# ------------------------------------------ #"
        echo
        echo "# EasyOutline Specific, please don't edit these. Except if you know what you are doing"
        echo "EASY_OUTLINE_DOCKER_COMPOSE_FILE=./docker-compose.yaml"
        echo "EASY_OUTLINE_ENV_FILE=./outline.env"
        echo "EASY_OUTLINE_DATA_DIR=./easy-outline"
        echo
        echo "# ------------"
        echo "# File Storage"
        echo "FILE_STORAGE=local"
        echo "FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data"
        echo "FILE_STORAGE_UPLOAD_MAX_SIZE=262144000"
        echo "FILE_STORAGE_IMPORT_MAX_SIZE="
        echo "FILE_STORAGE_WORKSPACE_IMPORT_MAX_SIZE="
        echo
        echo "# ---"
        echo "# AWS"
        echo "AWS_ACCESS_KEY_ID="
        echo "AWS_SECRET_ACCESS_KEY="
        echo "AWS_REGION="
        echo "AWS_S3_ACCELERATE_URL="
        echo "AWS_S3_UPLOAD_BUCKET_URL="
        echo "AWS_S3_UPLOAD_BUCKET_NAME="
        echo "AWS_S3_FORCE_PATH_STYLE="
        echo "AWS_S3_ACL=public-read"
        echo
        echo "# -----"
        echo "# Slack"
        echo "SLACK_CLIENT_ID="
        echo "SLACK_CLIENT_SECRET="
        echo "SLACK_VERIFICATION_TOKEN="
        echo "SLACK_APP_ID="
        echo "SLACK_MESSAGE_ACTIONS="
        echo
        echo "# ------"
        echo "# Google"
        echo "GOOGLE_CLIENT_ID="
        echo "GOOGLE_CLIENT_SECRET="
        echo
        echo "# ---------------"
        echo "# Microsoft Azure"
        echo "AZURE_CLIENT_ID="
        echo "AZURE_CLIENT_SECRET="
        echo "AZURE_RESOURCE_APP_ID="
        echo
        echo "# -------------"
        echo "# OIDC Defaults"
        echo "OIDC_USERNAME_CLAIM=preferred_username"
        echo "OIDC_DISPLAY_NAME=OpenID Connect"
        echo "OIDC_SCOPES=openid profile email"
        echo
        echo "# ------"
        echo "# GitHub"
        echo "GITHUB_CLIENT_ID="
        echo "GITHUB_CLIENT_SECRET="
        echo "GITHUB_APP_NAME="
        echo "GITHUB_APP_ID="
        echo "GITHUB_APP_PRIVATE_KEY="
        echo
        echo "# ---------"
        echo "# SSL Stuff"
        echo "SSL_KEY="
        echo "SSL_CERT="
        echo "FORCE_HTTPS=false"
        echo
        echo "# ----------------"
        echo "# Outline Specific"
        echo "SECRET_KEY=$SECRET_KEY"
        echo "UTILS_SECRET=$UTILS_SECRET"
        echo "NODE_ENV=production"
        echo "URL="
        echo "PORT=3000"
        echo "COLLABORATION_URL="
        echo "ENABLE_UPDATES=false"
        echo "DEBUG=http"
        echo "DEFAULT_LANGUAGE=en_US"
        echo "LOG_LEVEL=silly"
        echo
        echo "# ------"
        echo "# Sentry"
        echo "SENTRY_DSN="
        echo "SENTRY_TUNNEL="
        echo
        echo "# ------------"
        echo "# Rate Limiter"
        echo "RATE_LIMITER_ENABLED=false"
        echo "RATE_LIMITER_REQUESTS=1000"
        echo "RATE_LIMITER_DURATION_WINDOW=10"
        echo
        echo "# --------"
        echo "# iFramely"
        echo "IFRAMELY_URL="
        echo "IFRAMELY_API_KEY="
        echo
        echo "# ----------- #"
        echo "# Custom OIDC #"
        echo "# ----------- #"
        echo "OIDC_CLIENT_ID="
        echo "OIDC_CLIENT_SECRET="
        echo "OIDC_AUTH_URI="
        echo "OIDC_TOKEN_URI="
        echo "OIDC_USERINFO_URI="
        echo "OIDC_LOGOUT_URI="
        echo
        echo "# ----------- #"
        echo "# Custom SMTP #"
        echo "# ----------- #"
        echo "SMTP_HOST="
        echo "SMTP_PORT="
        echo "SMTP_USERNAME="
        echo "SMTP_PASSWORD="
        echo "SMTP_FROM_EMAIL="
        echo "SMTP_REPLY_EMAIL="
        echo "SMTP_TLS_CIPHERS="
        echo "SMTP_SECURE=false"
    } >outline.env
}

# <-------------------------------------------------------------------------->
# Customize docker ports
custom_postgres_docker_port() {
    local custom_port="$1"
    sed -i "s/.*# POSTGRES PORT/      - \"${custom_port}:5432\" # POSTGRES PORT/" "./docker-compose.yaml"
}

custom_redis_docker_port() {
    local custom_port="$1"
    sed -i "s/.*# REDIS PORT/      - \"${custom_port}:6379\" # REDIS PORT/" "./docker-compose.yaml"
}

# <-------------------------------------------------------------------------->
# Outline specific public access data
configure_outline() {
    local cmd
    local arg
    cmd="$1"

    case "$cmd" in
    port) set_custom_outline_port ;;
    fqdn) set_custom_fqdn ;;
    esac
}

# <-------------------------------------------------------------------------->
# Custom docker port for outline
set_custom_outline_port() {
    local custom_port

    echo "Please enter the port on which Outline should be reachable."
    read -r -p "Port: " custom_port
    sed -i "s/.*# OUTLINE PORT/      - \"${custom_port}:3000\" # OUTLINE PORT/" "./docker-compose.yaml"
}

# <-------------------------------------------------------------------------->
# Custom fqdn to make outline reachable
set_custom_fqdn() {
    local fqdn
    local line_to_replace='URL='

    echo "Please enter the Domain or Subdomain where Outline should be reached."
    echo -e "${grey}Please provide it like this: https://outline.example.com${nc}"

    read -r -p "FQDN: " fqdn
    sed -i "s|^URL=.*|URL=$fqdn|" "./outline.env"
}

# <-------------------------------------------------------------------------->
# OIDC helper
configure_oidc() {
    local cmd="$1"
    local line_to_replace=""
    local input=""
    local all_oidc=("OIDC_CLIENT_ID=" "OIDC_CLIENT_SECRET=" "OIDC_AUTH_URI=" "OIDC_TOKEN_URI=" "OIDC_USERINFO_URI=" "OIDC_LOGOUT_URI=")

    case "$cmd" in
    id)
        line_to_replace="OIDC_CLIENT_ID="
        echo "Please enter your client id."
        read -r -p "ID: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    secret)
        line_to_replace="OIDC_CLIENT_SECRET="
        echo "Please enter the OIDC secret."
        read -r -p "Secret: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    auth)
        line_to_replace="OIDC_AUTH_URI="
        echo "Please enter the OIDC auth URI."
        read -r -p "Secret: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    token)
        line_to_replace="OIDC_TOKEN_URI="
        echo "Please enter the OIDC Token URI."
        read -r -p "Secret: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    info)
        line_to_replace="OIDC_USERINFO_URI="
        echo "Please enter the OIDC User-Info URI."
        read -r -p "Secret: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    logout)
        line_to_replace="OIDC_LOGOUT_URI="
        echo "Please enter the OIDC Logout URI."
        read -r -p "Secret: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    remove)
        input=""
        for element in "${all_oidc[@]}"; do
            line_to_replace="$element"
            sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        done
        ;;
    get)
        grep "OIDC_" "./outline.env"
        ;;
    esac
}

# <-------------------------------------------------------------------------->
# Configures smtp if needed
configure_smtp() {
    local cmd="$1"
    local line_to_replace=""
    local input=""
    local all_smtp=("SMTP_HOST=" "SMTP_PORT=" "SMTP_USERNAME=" "SMTP_PASSWORD=" "SMTP_FROM_EMAIL=" "SMTP_REPLY_EMAIL=")

    case "$cmd" in
    host)
        line_to_replace="SMTP_HOST="
        echo "Please enter your SMTP Host."
        echo -e "${grey}Like this: https://smtp.example.com${nc}"
        read -r -p "Host: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    port)
        line_to_replace="SMTP_PORT="
        echo "Please enter the SMTP port."
        read -r -p "Port: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    user)
        line_to_replace="SMTP_USERNAME="
        echo "Please enter the SMTP user."
        read -r -p "User: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    pass)
        line_to_replace="SMTP_PASSWORD="
        echo "Please enter the SMTP password of the desired user."
        read -r -p "Password: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    from)
        line_to_replace="SMTP_FROM_EMAIL="
        echo "Please enter the from E-Mail adress."
        read -r -p "From: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    logout)
        line_to_replace="SMTP_REPLY_EMAIL="
        echo "Please enter the replay E-Mail."
        read -r -p "Reply to: " input
        sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        ;;
    remove)
        input=""
        for element in "${all_smtp[@]}"; do
            line_to_replace="$element"
            sed -i "s|^${line_to_replace}.*|${line_to_replace}$input|" "./outline.env"
        done
        ;;
    get)
        grep "SMTP_" "./outline.env"
        ;;
    esac
}

# <-------------------------------------------------------------------------->
# Logic for guided install
guide() {
    set +x
    if [[ ! -f ./outline.env ]]; then
        echo "To begin the installation run: 'install'"
    else
        grep "OIDC_\|SMTP_" ./outline.env >"$TODO"
    fi

    while read -r line; do
        if [[ -z "$(echo "$line" | cut -d'=' -f2-)" ]]; then
            case "$(echo "$line" | cut -d'=' -f1)" in
            OIDC_CLIENT_ID)
                echo -e "[ ${blue}OIDC${nc} ]: You have to set an OIDC Client ID, to do this type: 'oidc id'"
                ;;
            OIDC_CLIENT_SECRET)
                echo -e "[ ${blue}OIDC${nc} ]: You have to set an client secret, to do this type: 'oidc secret'"
                ;;
            OIDC_AUTH_URI)
                echo -e "[ ${blue}OIDC${nc} ]: You have to set an OIDC Auth URI, to do this type: 'oidc auth'"
                ;;
            OIDC_TOKEN_URI)
                echo -e "[ ${blue}OIDC${nc} ]: You have to set the token URI, to do this type: 'oidc token'"
                ;;
            OIDC_USERINFO_URI)
                echo -e "[ ${blue}OIDC${nc} ]: You have to set the User Info URI, to do this type: 'oidc info'"
                ;;
            OIDC_LOGOUT_URI)
                echo -e "[ ${blue}OIDC${nc} ]: You don't have to set a logout URI, if you want to, use: 'oidc logout'"
                ;;
            SMTP_HOST)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add an SMTP host, to this type: 'smtp host'"
                ;;
            SMTP_PORT)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add an SMTP port, to this type: 'smtp port'"
                ;;
            SMTP_USERNAME)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add an SMTP User, to do this type: 'smtp user'"
                ;;
            SMTP_PASSWORD)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add the password for your user: 'smtp pass'"
                ;;
            SMTP_FROM_EMAIL)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add the from E-Mail Adress, type: 'smtp from'"
                ;;
            SMTP_REPLY_EMAIL)
                echo -e "[ ${cyan}SMTP${nc} ]: Please add the reply E-Mail Adress, it can be the same as the from E-Mail, 'smtp reply'"
                ;;
            esac
        else
            true
        fi
    done <"$TODO"

    set +x
}

# <-------------------------------------------------------------------------->
# Main flow

# Retrieve dependencies and install them if needed
get_dependencies

# Give user time to read the output ~3 seconds
wait_to_read

# Show welcome splash screen
welcome

# Start initial shell prompt
outshell

# <-------------------------------------------------------------------------->
# Main loop with logic for guided installs
while true; do
    if [[ "$guided_install" = "true" ]]; then
        read -r -p "Press enter to continue. "
        guide
    fi
    outshell
done
