#!/bin/bash

FILE_LOCATION=""
RANDKEY1="$(openssl rand -hex 32)"
RANDKEY2="$(openssl rand -hex 32)"

iframely_url="http://127.0.0.1:8061"
iframely_api=""


#----------------------------------------------------------------------------------------

echo "# –––––––––––––––– REQUIRED ––––––––––––––––

NODE_ENV=production" > docker.env

clear

echo "
Welcome to EasyOutline Setup
"

getFileLocation(){
    echo "Please enter your location where all files should be placed. (FULL PATH)"
    read -p "$ " location
    echo "> $location, is this correct? "

    confirm getFileLocation
        
    FILE_LOCATION="$location"
}

confirm(){
    echo
    read -p "(y/n) " -n 1 confirm 
    case $confirm in 
        y|Y)
        echo
        echo "OK"
        ;;
        n|N)
        echo
        echo "Try again."
        $1
        ;;
    esac
    echo "----------------------------------------"
}

randomKey(){
    echo "UwU"
    echo "SECRET_KEY=$RANDKEY1 # Generate a hex-encoded 32-byte random key. You should use \`openssl rand -hex 32\`" >> docker.env
    echo "UTILS_SECRET=$RANDKEY2 # Generate a hex-encoded 32-byte random key. You should use \`openssl rand -hex 32\`" >> docker.env
}

getUrlAndPort(){
    echo "Please enter the URL as FQDN where Outline is reachable."
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

defaultParams(){
    cat default-params.txt >> docker.env
    echo "" >> docker.env
    echo "# ---------- GENERATED -----------" >> docker.env
    echo "" >> docker.env
}

getSMTP(){
    echo "Please enter your SMTP Credentials"
    read -p "SMTP Host: " host
    read -p "SMTP Port: " port
    read -p "SMTP Username: " user
    read -p "SMTP Password: " passwd
    read -p "SMTP From E-Mail: " email
    read -p "SMTP Reply E-Mail: " reply 
    echo
    echo
    echo
    echo "###################"
    echo "### Your Values ###"
    echo "###################"
    echo "SMTP Server: $host:$port"
    echo "User: $user - $passwd"
    echo "E-Mail: $email - Reply: $reply"

    confirm getSMTP

    addToConf "# --------- EMAIL ----------"
    addToConf SMTP_HOST=$host
    addToConf SMTP_PORT=$port
    addToConf SMTP_USERNAME=$user
    addToConf SMTP_PASSWORD=$passwd
    addToConf SMTP_FROM_EMAIL=$email
    addToConf SMTP_REPLY_EMAIL=$reply
}

getIframeLy(){
    echo "Do you want to use the defaults?"
    addToConf "# -------- iFramely --------"
    confirm customIframely 
    addToConf IFRAMELY_URL=$iframely_url
    addToConf IFRAMELY_API_KEY=$iframely_api
    
}

customIframely(){
    read -p "iFramely URL: " iframely_url
    read -p "iFramely API: " iframely_api
    confirm customIframely
}

addToConf(){
    echo "" >> docker.env
    echo "$@" >> docker.env
}

defaultParams
getFileLocation
randomKey
getUrlAndPort
getSMTP
getIframeLy

echo
echo "Continuing..."
sleep 3

docker build -t iframely:latest .

rm ./Dockerfile
rm -rf ./iframely
