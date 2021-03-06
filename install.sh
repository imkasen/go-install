#!/usr/bin/env bash

# Install the latest go version

# echo text with color
RED="31m"
GREEN="32m"
YELLOW="33m"

colorEcho(){
    COLOR=$1
    echo -e "\033[$COLOR${*:2}\033[0m"
}

# Check system architecture
arch(){
    ARCH=$(uname -m)
    SYS=$(uname -s)
    SYSDIS=$(< /etc/os-release head -n 1)

    if [[ $ARCH == "x86_64" ]] && [[ $SYS == "Linux" ]]; then
        DIS="linux-amd64"
        FMT="tar.gz"

        # curl is not installed 
        if [[ $SYSDIS =~ "Ubuntu" || $SYSDIS =~ "Debian" ]] && ! curl --help &> /dev/null; then
            colorEcho $YELLOW "Installing 'curl'..."
            sudo apt install curl
        fi
    fi
}

# Check network
checkNet(){
    if [[ $(ping -c2 -i0.3 -W1 "google.com" &> /dev/null) ]]; then
        CNM=0
    else
        CNM=1 # China mainland
    fi
}

# Check area
setURL(){
    if [[ $CNM -eq 0 ]]; then
        URL="https://go.dev/dl/"
    else
        URL="https://golang.google.cn/dl/"
    fi
}

# Download
downloadGo(){
    colorEcho $GREEN "Start downloading go:"

    VERSION=$(curl -s $URL | grep "downloadBox" | grep "src" | grep -oP '\d+\.\d+(\.\d+)?' | head -n 1)
    CUR_VERSION=$(go version 2> /dev/null | grep -oP '\d+\.\d+\.?\d*' | head -n 1)
    PACKAGE="go$VERSION.$DIS.$FMT"
    
    if [[ "$CUR_VERSION" != "$VERSION" ]]; then
        if [[ ! -e $PACKAGE ]]; then
            colorEcho $YELLOW "Downloading '$PACKAGE' from '$URL'..." 
            curl -LJ "$URL$PACKAGE" -o "$PACKAGE" --progress-bar
        else
            colorEcho $YELLOW "The package already exists, skip downloading..."
        fi
    else
        colorEcho $RED "The latest version is already installed, exit!" >& 2
        exit 1 
    fi

    clear
}

# Install
installGo(){
    colorEcho $GREEN "Start installing go:"

    if [[ -d /usr/local/go/ ]]; then
        colorEcho $YELLOW "Deleting '/usr/local/go/'..."
        sudo rm -rf /usr/local/go/
    fi
    colorEcho $YELLOW "Unpacking '$PACKAGE'..."
    sudo tar -C /usr/local -xzf "$PACKAGE"
    rm "$PACKAGE"

    clear
}

# Configure Path
configPath(){
    colorEcho $GREEN "Start configuring path:"

    SHPATH=$(env | grep "SHELL=")
    if [[ $SHPATH =~ "zsh" ]]; then
        SHFILE=".zshrc"
    elif [[ $SHPATH =~ "bash" ]]; then
        SHFILE=".bashrc"
    fi

    if [[ -e ~/$SHFILE && $(grep -c "/usr/local/go" ~/$SHFILE) -eq 0 ]]; then
        colorEcho $YELLOW "Configuring path..."
        {
            echo
            echo "# Go"
            echo "export GOROOT=/usr/local/go"
            echo "export PATH=\$PATH:\$GOROOT/bin"
            echo
        } >> ~/$SHFILE
        configProxy
    else
        colorEcho $YELLOW "Go configuration already exists, skip..."
    fi

    clear
}

# Configure proxy
configProxy(){
    colorEcho $GREEN "Start configuring proxy:"

    if [[ $CNM -eq 1 ]]; then
        colorEcho $YELLOW "Configuring proxy..."
        {
            echo "# Go Proxy"
            echo "# https://goproxy.cn"
            echo "export GO111MODULE=on"
            echo "export GOPROXY=https://goproxy.cn,direct"
            echo
        } >> ~/$SHFILE
    fi
}

main(){
    arch
    checkNet
    setURL
    downloadGo
    installGo
    configPath
    colorEcho $GREEN "Finish Installation."
    colorEcho $YELLOW "Please SOURCE your '$SHFILE' file!"
}

main
