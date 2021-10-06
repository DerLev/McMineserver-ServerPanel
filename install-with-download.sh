#!/bin/bash
echo "updating installer..."
apt update >/dev/null 2>&1
apt install -y curl jq >/dev/null 2>&1
echo "installer updated. beginning installation."

#Go into main direction
if [ ! -d /mnt/server ]; then
    mkdir /mnt/server
fi

cd /mnt/server

IGNORE=.pteroignore
if [ -f "$IGNORE" ]; then
    echo "$IGNORE exists"
else 
    echo "$IGNORE does not exist. Creating one..."
    curl -o .pteroignore https://raw.githubusercontent.com/DerLev/McMineserver-ServerPanel/bd2587ccda4d6c20cde8eb1fec5eaa515b90e3a8/.pteroignore >/dev/null 2>&1
fi

if [ "${SERVER_TYPE}" == "forge" ] ; then

    if [ ! -z ${FORGE_VERSION} ]; then
        DOWNLOAD_LINK=https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION}/forge-${FORGE_VERSION}
        FORGE_JAR=forge-${FORGE_VERSION}*.jar
    else
        JSON_DATA=$(curl -sSL https://files.minecraftforge.net/maven/net/minecraftforge/forge/promotions_slim.json)

        if [ "${SERVER_VERSION}" == "latest" ] || [ "${SERVER_VERSION}" == "" ] ; then
            echo -e "getting latest recommended version of forge."
            SERVER_VERSION=$(echo -e ${JSON_DATA} | jq -r '.promos | del(."latest-1.7.10") | del(."1.7.10-latest-1.7.10") | to_entries[] | .key | select(contains("recommended")) | split("-")[0]' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1)
            FORGE_TYPE=recommended
        fi

        if [ "${FORGE_TYPE}" != "recommended" ] && [ "${FORGE_TYPE}" != "latest" ]; then
            FORGE_TYPE=recommended
        fi

        echo -e "minecraft version: ${SERVER_VERSION}"
        echo -e "build type: ${FORGE_TYPE}"

        ## some variables for getting versions and things
        FILE_SITE=https://maven.minecraftforge.net/net/minecraftforge/forge/
        VERSION_KEY=$(echo -e ${JSON_DATA} | jq -r --arg SERVER_VERSION "${SERVER_VERSION}" --arg FORGE_TYPE "${FORGE_TYPE}" '.promos | del(."latest-1.7.10") | del(."1.7.10-latest-1.7.10") | to_entries[] | .key | select(contains($SERVER_VERSION)) | select(contains($FORGE_TYPE))')

        ## locating the forge version
        if [ "${VERSION_KEY}" == "" ] && [ "${FORGE_TYPE}" == "recommended" ]; then
            echo -e "dropping back to latest from recommended due to there not being a recommended version of forge for the mc version requested."
            VERSION_KEY=$(echo -e ${JSON_DATA} | jq -r --arg SERVER_VERSION "${SERVER_VERSION}" '.promos | del(."latest-1.7.10") | del(."1.7.10-latest-1.7.10") | to_entries[] | .key | select(contains($SERVER_VERSION)) | select(contains("recommended"))')
        fi

        ## Error if the mc version set wasn't valid.
        if [ "${VERSION_KEY}" == "" ] || [ "${VERSION_KEY}" == "null" ]; then
            echo -e "The install failed because there is no valid version of forge for the version on minecraft selected."
            exit 1
        fi

        FORGE_VERSION=$(echo -e ${JSON_DATA} | jq -r --arg VERSION_KEY "$VERSION_KEY" '.promos | .[$VERSION_KEY]')

        if [ "${SERVER_VERSION}" == "1.7.10" ] || [ "${SERVER_VERSION}" == "1.8.9" ]; then
            DOWNLOAD_LINK=${FILE_SITE}${SERVER_VERSION}-${FORGE_VERSION}-${SERVER_VERSION}/forge-${SERVER_VERSION}-${FORGE_VERSION}-${SERVER_VERSION}
            FORGE_JAR=forge-${SERVER_VERSION}-${FORGE_VERSION}-${SERVER_VERSION}.jar
            if [ "${SERVER_VERSION}" == "1.7.10" ]; then
                FORGE_JAR=forge-${SERVER_VERSION}-${FORGE_VERSION}-${SERVER_VERSION}-universal.jar
            fi
        else
            DOWNLOAD_LINK=${FILE_SITE}${SERVER_VERSION}-${FORGE_VERSION}/forge-${SERVER_VERSION}-${FORGE_VERSION}
            FORGE_JAR=forge-${SERVER_VERSION}-${FORGE_VERSION}.jar
        fi
    fi


    #Adding .jar when not eding by SERVER_JARFILE
    if [[ ! $SERVER_JARFILE = *\.jar ]]; then
    SERVER_JARFILE="$SERVER_JARFILE.jar"
    fi

    #Downloading jars
    echo -e "Downloading forge version ${FORGE_VERSION}"
    echo -e "Download link is ${DOWNLOAD_LINK}"
    if [ ! -z "${DOWNLOAD_LINK}" ]; then 
        if curl --output /dev/null --silent --head --fail ${DOWNLOAD_LINK}-installer.jar; then
            echo -e "installer jar download link is valid."
        else
            echo -e "link is invalid closing out"
            exit 2
        fi
    else
        echo -e "no download link closing out"
        exit 3
    fi

    curl -s -o installer.jar -sS ${DOWNLOAD_LINK}-installer.jar

    #Checking if downloaded jars exist
    if [ ! -f ./installer.jar ]; then
        echo "!!! Error by downloading forge version ${FORGE_VERSION} !!!"
        exit
    fi

    #Installing server
    echo -e "Installing forge server.\n"
    java -jar installer.jar --installServer || { echo -e "install failed"; exit 4; }

    mv $FORGE_JAR $SERVER_JARFILE

    #Deleting installer.jar
    echo -e "Deleting installer.jar file.\n"
    rm -rf installer.jar
    rm -rf installer.jar.log

fi

if [ "${SERVER_TYPE}" == "paper" ] ; then

    VER_EXISTS=`curl -s https://papermc.io/api/v2/projects/paper | jq -r --arg VERSION $SERVER_VERSION '.versions[] | contains($VERSION)' | grep true`
    SERVER_VERSION=`curl -s https://papermc.io/api/v2/projects/paper | jq -r '.versions' | jq -r '.[-1]'`

    if [ "${VER_EXISTS}" == "true" ]; then
        echo -e "Version is valid. Using version ${SERVER_VERSION}"
    else
        echo -e "Using the latest paper version"
        SERVER_VERSION=${LATEST_VERSION}
    fi
    
    BUILD_NUMBER=`curl -s https://papermc.io/api/v2/projects/paper/versions/${SERVER_VERSION} | jq -r '.builds' | jq -r '.[-1]'`
    
    JAR_NAME=paper-${SERVER_VERSION}-${BUILD_NUMBER}.jar
    
    echo "Version being downloaded"
    echo -e "MC Version: ${SERVER_VERSION}"
    echo -e "Build: ${BUILD_NUMBER}"
    echo -e "JAR Name of Build: ${JAR_NAME}"
    DOWNLOAD_URL=https://papermc.io/api/v2/projects/paper/versions/${SERVER_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}

    echo -e "Running curl"

    curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL} >/dev/null 2>&1

fi

if [ "${SERVER_TYPE}" == "vanilla" ] ; then

    LATEST_VERSION=`curl https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release'`

    echo -e "latest version is $LATEST_VERSION"

    if [ -z "$SERVER_VERSION" ] || [ "$SERVER_VERSION" == "latest" ]; then
        MANIFEST_URL=$(curl -sSL https://launchermeta.mojang.com/mc/game/version_manifest.json | jq --arg VERSION $LATEST_VERSION -r '.versions | .[] | select(.id== $VERSION )|.url')
    else
        MANIFEST_URL=$(curl -sSL https://launchermeta.mojang.com/mc/game/version_manifest.json | jq --arg VERSION $SERVER_VERSION -r '.versions | .[] | select(.id== $VERSION )|.url')
    fi

    DOWNLOAD_URL=$(curl ${MANIFEST_URL} | jq .downloads.server | jq -r '. | .url')

    echo -e "running curl"
    curl -o ${SERVER_JARFILE} $DOWNLOAD_URL >/dev/null 2>&1

fi

echo "Installation done! You can run the server!"