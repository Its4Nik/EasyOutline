#!/bin/bash
# Set Bash flags
set -euo pipefail

# Remove unnecessary files
rm -rf LICENSE README.md configs README-google.md *.png README-Code-explanation.md

# Initialize variables
FILE_LOCATION=""
RANDKEY1="$(openssl rand -hex 32)"
RANDKEY2="$(openssl rand -hex 32)"
RANDKEY3="$(openssl rand -hex 32)"

# ANSI color codes for formatting output
NC="\033[0m"        # No color
BLU="\033[0;34m"    # Blue
GRN="\033[0;32m"    # Green
YLW="\033[1;33m"    # Yellow
RED="\033[0;31m"    # Red

# Function to get the public IP address
IP="$(curl -4 https://ip.hetzner.com)"

# Define iFramely variables
iframely_url="http://$IP:8061"
iframely_api=""

# Print welcome message
echo -e "${BLU}Welcome to EasyOutline Setup${NC}"

# Function to confirm user input
confirm(){
    echo
    read -p "(y/n) " -n 1 confirm 
    case $confirm in 
        y|Y)
        echo
        echo -e "${GRN}OK${NC}"
        ;;
        n|N)
        echo
        echo -e "${YLW}Try again.${NC}"
        $1
        ;;
    esac
    echo "----------------------------------------"
}

# Check docker dependency
getDockerInstall() {
    echo "Checking dependencies..."
    if command -v docker > /dev/null; then
        echo "${GRN}Docker is installed.${NC}"
    else
        echo -e "${RED}Please install docker:${NC} ${YLW}https://get.docker.com${NC}"
    fi
}

# Function to display a dynamic progress bar
progressBar() {
    local width=50
    local progress=$(( $1 * $width / 100 ))
    printf "\r[${GRN}%-${width}s${NC}] ${1}%%" "$(< /dev/zero tr '\0' '#')"
}

# Generate random keys and write to docker.env
randomKey(){
    echo "SECRET_KEY=$RANDKEY1 # Generate a hex-encoded 32-byte random key. You should use \`openssl rand -hex 32\`" >> docker.env
    echo "UTILS_SECRET=$RANDKEY2 # Generate a hex-encoded 32-byte random key. You should use \`openssl rand -hex 32\`" >> docker.env
}

# Function to get URL and port for Outline
getUrlAndPort(){
    echo "Please enter the URL as FQDN WITH HTTP(S) where Outline is reachable."
    read -p "$ " URL
    confirm getUrlAndPort

    echo "Please enter the local port of outline (default 3000)"
    read -p "$ " PORT
    confirm getUrlAndPort

    echo "
URL=$URL
PORT=$PORT
" >> docker.env
}

# Set default parameters by copying from a file
defaultParams(){
    cat default-params.txt >> docker.env
    rm default-params.txt
    echo "" >> docker.env
    echo -e "${BLU}# ---------- GENERATED -----------${NC}" >> docker.env
    echo "" >> docker.env
}

# Function to get SMTP credentials
getSMTP(){
    echo -e "${BLU}Please enter your SMTP Credentials${NC}"
    echo -ne "${YLW}SMTP Host: ${NC}"
    read -r host
    echo -ne "${YLW}SMTP Port: ${NC}"
    read -r  port
    echo -ne "${YLW}SMTP Username: ${NC}"
    read -r  user
    echo -ne "${YLW}SMTP Password: ${NC}"
    read -r  passwd
    echo -ne "${YLW}SMTP From E-Mail: ${NC}"
    read -r  email
    echo -ne "${YLW}SMTP Reply E-Mail: ${NC}"
    read -r  reply 
    echo
    echo
    echo
    echo -e "${GRN}###################${NC}"
    echo -e "${GRN}### ${NC}Your Values${GRN} ###${NC}"
    echo -e "${GRN}###################${NC}"
    echo -e "${GRN}SMTP Server: ${YLW}$host:$port${NC}"
    echo -e "${GRN}User: ${YLW}$user - $passwd${NC}"
    echo -e "${GRN}E-Mail: ${YLW}$email - Reply: $reply${NC}"

    confirm getSMTP

    addToConf "${BLU}# --------- EMAIL ----------${NC}"
    addToConf SMTP_HOST=$host
    addToConf SMTP_PORT=$port
    addToConf SMTP_USERNAME=$user
    addToConf SMTP_PASSWORD=$passwd
    addToConf SMTP_FROM_EMAIL=$email
    addToConf SMTP_REPLY_EMAIL=$reply
}

# Function to set iFramely configuration
getIframeLy(){
    echo "Do you want to use the default iFramely values?"
    addToConf "${BLU}# -------- iFramely --------${NC}"
    confirm customIframely 
    addToConf IFRAMELY_URL=$iframely_url
    addToConf IFRAMELY_API_KEY=$iframely_api
    
}

# Function to customize iFramely configuration
customIframely(){
    echo -ne "${YLW}iFramely URL: ${NC}"
    read -r  iframely_url
    echo -ne "${YLW}iFramely API: ${NC}"
    read -r iframely_api
    echo -e "\n"
    confirm customIframely
}

# Function to add configuration parameters to docker.env
addToConf(){
    echo "" >> docker.env
    echo "$@" >> docker.env
}

# Function to set up PostgreSQL and Redis configurations
redisLoginData(){
    addToConf "DATABASE_URL=postgres://user:$RANDKEY3@$IP:5432/outline"
    
    addToConf "REDIS_URL=redis://$IP:6379"

    echo "
  postgres:
    container_name: postgres
    image: postgres
    env_file: ./docker.env
    ports:
      - "5432:5432"
    volumes:
      - ./database-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-d", "outline", "-U", "user"]
      interval: 30s
      timeout: 20s
      retries: 3
    environment:
      POSTGRES_USER: 'user'
      POSTGRES_PASSWORD: '$RANDKEY3'
      POSTGRES_DB: 'outline'
" >> docker-compose.yaml

}

# Function to set up OpenID configuration
openId(){
    echo
    echo -e "${BLU}Please provide your Google OpenID credentials${NC}"
    echo -e "${YLW}(More Info here https://github.com/Its4Nik/EasyOutline/blob/main/README-google.md)${NC}"
    echo -ne "${YLW}OIDC clien id: ${NC}"
    read -r  oicd_id
    echo
    echo -ne "${YLW}Client Secret: ${NC}"
    read -r  client_secret 
    echo
    
    echo "


# REMOVE BELOW HERE:
OIDC_CLIENT_ID=$oicd_id
OIDC_CLIENT_SECRET=$client_secret
OIDC_AUTH_URI=https://accounts.google.com/o/oauth2/v2/auth
OIDC_TOKEN_URI=https://oauth2.googleapis.com/token
OIDC_USERINFO_URI=https://openidconnect.googleapis.com/v1/userinfo
OIDC_LOGOUT_URI=    
    " >> docker.env
}

# Run setup functions
getDockerInstall
defaultParams
randomKey
getUrlAndPort
getSMTP
getIframeLy
redisLoginData
openId

echo
echo -e "${GRN}Continuing...${NC}"

# Build Docker image with dynamic progress bar
echo "Building Docker image..."
docker build -t iframely:latest . --progress=plain | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^\ \[([0-9]+)%\].* ]]; then
            progressBar "${BASH_REMATCH[1]}"
        fi
    done
printf "\n"

# Clone iFramely repository
git clone https://github.com/itteco/iframely

# Copy configuration file to iFramely directory
cp config.local.js ./iframely/config.local.js

# Start Docker containers
docker compose up -d

echo -e "${GRN}Thanks for trying this!${NC}"

# Remove setup script
rm setup.sh
