#!/bin/bash
WORDLIST_PATH=~/wordlists
TOOL_PATH=~/ctf-tools
BIN_PATH=~/.local/bin

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"
TITLE="\e[34m"
INSTALLING="\e[35m"

title () {
    echo -e "${TITLE}$1${ENDCOLOR}"
}

installing () {
    echo -ne "${INSTALLING}Installing $1 ... ${ENDCOLOR}"
}

installed () {
    echo -e "${GREEN}done${ENDCOLOR}"
}

skipping () {
    echo -e "${YELLOW}already installed, skipping${ENDCOLOR}"
}

git_clone () {
    git clone -q $1 $2
}

pip2 () {
    python2.7 -m pip install -q --upgrade $1
}

pip3 () {
    python3 -m pip install -q --upgrade $1
}

install_pip2_requirements () {
    python2.7 -m pip install -q -r $1/requirements.txt
}

install_pip3_requirements () {
    python3 -m pip install -q -r $1/requirements.txt
}

create_python3_wrapper () {
    cat <<EOF > $1
#!/bin/bash
python3 $2 \$@
EOF
}

create_python2_wrapper () {
    cat <<EOF > $1
#!/bin/bash
python2.7 $2 \$@
EOF
}

create_directories () {
    title "Creating directories"
    mkdir $WORDLIST_PATH 2>/dev/null
    mkdir $TOOL_PATH 2>/dev/null
    mkdir $TOOL_PATH/steg 2>/dev/null
    mkdir $TOOL_PATH/forensics 2>/dev/null
    mkdir $TOOL_PATH/web 2>/dev/null
    mkdir $TOOL_PATH/crypto 2>/dev/null
    mkdir $TOOL_PATH/misc 2>/dev/null
}

install_tools () {
    installing "Python 2.7 and Python 3"
    sudo apt-get -qq install python2.7 python3
    installed

    installing "java"
    sudo apt-get -qq install openjdk-11-jre openjdk-11-jre-headless default-jre default-jre-headless -y
    installed

    installing "codium"
    sudo apt-get -qq install codium -y
    installed

    installing "Wireshark"
    sudo apt-get -qq install wireshark -y
    installed

    installing "docker"
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get -qq update -y
        sudo groupadd docker 2>/dev/null
        sudo usermod -aG docker $USER 2>/dev/null
        newgrp docker
    fi
    sudo apt-get -qq install docker-ce docker-ce-cli containerd.io -y
    installed

    installing "common tools"
    sudo apt-get -qq install wget curl git fcrackzip -y
    installed
}

install_wordlists () {
    title "Installing wordlists in $WORDLIST_PATH"
    installing "rockyou"
    if [ -f "$WORDLIST_PATH/rockyou.txt" ]; then
        skipping
    else
        curl -s https://raw.githubusercontent.com/praetorian-inc/Hob0Rules/master/wordlists/rockyou.txt.gz | gunzip > $WORDLIST_PATH/rockyou.txt
        installed
    fi

    installing "SecLists"
    if [ -d "$WORDLIST_PATH/SecLists" ]; then
        skipping
    else
        git_clone https://github.com/danielmiessler/SecLists.git $WORDLIST_PATH/SecLists
        installed
    fi
}

install_steg_tools () {
    title "Installing stegano tools in $TOOL_PATH/steg"
    installing "zsteg"
    sudo gem install --silent zsteg
    installed
    installing "stegsnow, steghide, stegseek"
    sudo apt-get -qq install stegsnow steghide stegseek -y
    installed
    installing "Audacity"
    sudo apt-get -qq install audacity -y
    installed

    installing "Stegsolve"
    if [ -d "$TOOL_PATH/steg/stegsolve" ]; then
        skipping
    else
        mkdir $TOOL_PATH/steg/stegsolve
        wget http://www.caesum.com/handbook/Stegsolve.jar -O $TOOL_PATH/steg/stegsolve/stegsolve.jar -q
        echo "#!/bin/bash" > $TOOL_PATH/steg/stegsolve/stegsolve.sh
        echo "java -jar $TOOL_PATH/steg/stegsolve/stegsolve.jar" >> $TOOL_PATH/steg/stegsolve/stegsolve.sh
        chmod +x $TOOL_PATH/steg/stegsolve/stegsolve.sh
        ln -s $TOOL_PATH/steg/stegsolve/stegsolve.sh $BIN_PATH/stegsolve
        installed
    fi
}

install_forensics_tools () {
    title "Installing forensics tools in $TOOL_PATH/forensics"

    installing "PDF tools"
    if [ -d "$TOOL_PATH/forensics/pdftools" ]; then
        skipping
    else
        mkdir $TOOL_PATH/forensics/pdftools
        wget http://didierstevens.com/files/software/pdf-parser_V0_7_4.zip -O $TOOL_PATH/forensics/pdftools/pdf-parser.zip -q
        wget http://didierstevens.com/files/software/pdfid_v0_2_7.zip -O $TOOL_PATH/forensics/pdftools/pdfid.zip -q
        wget http://didierstevens.com/files/software/pdftool_V0_0_1.zip -O $TOOL_PATH/forensics/pdftools/pdftool.zip -q
        unzip -qq $TOOL_PATH/forensics/pdftools/pdf-parser.zip -d $TOOL_PATH/forensics/pdftools/
        unzip -qq $TOOL_PATH/forensics/pdftools/pdfid.zip -d $TOOL_PATH/forensics/pdftools/
        unzip -qq $TOOL_PATH/forensics/pdftools/pdftool.zip -d $TOOL_PATH/forensics/pdftools/
        rm $TOOL_PATH/forensics/pdftools/pdf-parser.zip $TOOL_PATH/forensics/pdftools/pdfid.zip $TOOL_PATH/forensics/pdftools/pdftool.zip
        chmod +x $TOOL_PATH/forensics/pdftools/*.py
        ln -s $TOOL_PATH/forensics/pdftools/pdf-parser.py $BIN_PATH/pdf-parser
        ln -s $TOOL_PATH/forensics/pdftools/pdfid.py $BIN_PATH/pdfid
        ln -s $TOOL_PATH/forensics/pdftools/pdftool.py $BIN_PATH/pdftool
        installed
    fi

    installing "oletools"
    pip3 oletools
    installed

    installing "Volatility 2"
    if [ -d "$TOOL_PATH/forensics/volatility" ]; then
        skipping
    else
        git_clone https://github.com/volatilityfoundation/volatility.git $TOOL_PATH/forensics/volatility
        create_python2_wrapper $BIN_PATH/vol2 $TOOL_PATH/forensics/volatility/vol.py
        chmod +x $BIN_PATH/vol2
        installed
    fi

    installing "Volatility 3"
    if [ -d "$TOOL_PATH/forensics/volatility3" ]; then
        skipping
    else
        git_clone https://github.com/volatilityfoundation/volatility3.git $TOOL_PATH/forensics/volatility3
        create_python3_wrapper $BIN_PATH/vol3 $TOOL_PATH/forensics/volatility3/vol.py
        chmod +x $BIN_PATH/vol3
        installed
    fi

    installing "Firepwd"
    if [ -d "$TOOL_PATH/forensics/firepwd" ]; then
        skipping
    else
        git_clone https://github.com/lclevy/firepwd.git $TOOL_PATH/forensics/firepwd
        install_pip3_requirements $TOOL_PATH/forensics/firepwd
        create_python3_wrapper $BIN_PATH/firepwd $TOOL_PATH/forensics/firepwd/firepwd.py
        chmod +x $BIN_PATH/firepwd
        installed
    fi

    installing "Binwalk"
    sudo apt-get -qq install binwalk -y
    installed

    installing "Foremost"
    sudo apt-get -qq install foremost -y
    installed
}

install_web_tools () {
    WEB_TOOL_PATH=$TOOL_PATH/web
    title "Installing web tools in $WEB_TOOL_PATH"

    installing "JWT Tool"
    if [ -d "$WEB_TOOL_PATH/jwt_tool" ]; then
        skipping
    else
        git_clone https://github.com/ticarpi/jwt_tool.git $WEB_TOOL_PATH/jwt_tool
        install_pip3_requirements $WEB_TOOL_PATH/jwt_tool
        ln -s $WEB_TOOL_PATH/jwt_tool/jwt_tool.py $BIN_PATH/jwt_tool
        chmod +x $BIN_PATH/jwt_tool
        installed
    fi
}

install_crypto_tools () {
    CRYPTO_TOOL_PATH=$TOOL_PATH/crypto
    title "Installing crypto tools in $CRYPTO_TOOL_PATH"

    installing "RsaCtfTool"
    if [ -d "$CRYPTO_TOOL_PATH/RsaCtfTool" ]; then
        skipping
    else
        git_clone https://github.com/Ganapati/RsaCtfTool.git $CRYPTO_TOOL_PATH/RsaCtfTool
        install_pip3_requirements $CRYPTO_TOOL_PATH/RsaCtfTool
        ln -s $CRYPTO_TOOL_PATH/RsaCtfTool/RsaCtfTool.py $BIN_PATH/RsaCtfTool
        chmod +x $BIN_PATH/RsaCtfTool
        installed
    fi

    installing "cribdrag"
    if [ -d "$CRYPTO_TOOL_PATH/cribdrag" ]; then
        skipping
    else
        git_clone https://github.com/SpiderLabs/cribdrag.git $CRYPTO_TOOL_PATH/cribdrag
        create_python2_wrapper $BIN_PATH/cribdrag $CRYPTO_TOOL_PATH/cribdrag/cribdrag.py
        create_python2_wrapper $BIN_PATH/xorstrings $CRYPTO_TOOL_PATH/cribdrag/xorstrings.py
        chmod +x $BIN_PATH/cribdrag
        chmod +x $BIN_PATH/xorstrings
        installed
    fi

    installing "Ciphey"
    pip3 ciphey
    installed
}

install_misc_tools () {
    MISC_TOOL_PATH=$TOOL_PATH/misc
    title "Installing misc tools in $MISC_TOOL_PATH"

    installing "GitTools"
    if [ -d "$MISC_TOOL_PATH/GitTools" ]; then
        skipping
    else
        git_clone https://github.com/internetwache/GitTools.git $MISC_TOOL_PATH/GitTools
        ln -s $MISC_TOOL_PATH/GitTools/Extractor/extractor.sh $BIN_PATH/gitextractor
        chmod +x $BIN_PATH/gitextractor
        ln -s $MISC_TOOL_PATH/GitTools/Dumper/gitdumper.sh $BIN_PATH/gitdumper
        chmod +x $BIN_PATH/gitdumper
        installed
    fi
}

install_osint_tools () {
    OSINT_TOOL_PATH=$TOOL_PATH/osint
    title "Installing osint tools in $OSINT_TOOL_PATH"

    installing "sherlock"
    if [ -d "$OSINT_TOOL_PATH/sherlock" ]; then
        skipping
    else
        git_clone https://github.com/sherlock-project/sherlock.git $OSINT_TOOL_PATH/sherlock
        docker build -t sherlock $OSINT_TOOL_PATH/sherlock 1>/dev/null
        cat <<EOF > $BIN_PATH/sherlock
#!/bin/bash
docker run --rm -t -v "$PWD/results:/opt/sherlock/results" sherlock -o /opt/sherlock/results/\$@.txt \$@
EOF
        chmod +x $BIN_PATH/sherlock
        installed
    fi
}

install_rev_tools () {
    REV_TOOL_PATH=$TOOL_PATH/rev
    title "Installing rev tools in $REV_TOOL_PATH"

    installing "Ghidra"
    GHIDRA_VERSION="ghidra_10.0.3_PUBLIC"
    if [ -d "$REV_TOOL_PATH/$GHIDRA_VERSION" ]; then
        skipping
    else
        wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.0.3_build/ghidra_10.0.3_PUBLIC_20210908.zip -O /tmp/ghidra.zip -q
        unzip -qq /tmp/ghidra.zip -d $REV_TOOL_PATH
        rm /tmp/ghidra.zip
        ln -s $REV_TOOL_PATH/$GHIDRA_VERSION/ghidraRun $BIN_PATH/ghidra
        installed
    fi

    installing "IDA"
    IDA_VERSION="idafree-7.6"
    if [ -d "$REV_TOOL_PATH/$IDA_VERSION" ]; then
        skipping
    else
        wget https://out7.hex-rays.com/files/idafree76_linux.run -O /tmp/ida.run -q
        chmod +x /tmp/ida.run
        /tmp/ida.run --unattendedmodeui minimal --prefix $REV_TOOL_PATH/$IDA_VERSION --mode unattended
        rm /tmp/ida.run
        installed
    fi

    installing "Jadx"
    if [ -d "$REV_TOOL_PATH/jadx" ]; then
        skipping
    else
        wget https://github.com/skylot/jadx/releases/download/v1.2.0/jadx-1.2.0.zip -O /tmp/jadx.zip -q
        unzip -qq /tmp/jadx.zip -d $REV_TOOL_PATH/jadx
        rm /tmp/jadx.zip
        ln -s $REV_TOOL_PATH/jadx/bin/jadx $BIN_PATH/jadx
        ln -s $REV_TOOL_PATH/jadx/bin/jadx-gui $BIN_PATH/jadx-gui
        installed
    fi

    installing "Apktool"
    sudo apt-get -qq install apktool -y
    installed

    installing "ILSpy"
    if [ -d "$REV_TOOL_PATH/ILSpy" ]; then
        skipping
    else
        wget https://github.com/icsharpcode/AvaloniaILSpy/releases/download/v7.0-rc2/linux-x64.zip -O /tmp/ilspy.zip -q
        unzip -qq /tmp/ilspy.zip -d /tmp
        rm /tmp/ilspy.zip
        unzip -qq /tmp/ILSpy-linux-x64-Release.zip -d $REV_TOOL_PATH/ilspy
        rm /tmp/ILSpy-linux-x64-Release.zip
        ln -s $REV_TOOL_PATH/ilspy/artifacts/linux-x64/ILSpy $BIN_PATH/ILSpy
        installed
    fi
}

# create_directories
# install_tools
# install_wordlists
# install_steg_tools
# install_forensics_tools
# install_web_tools
# install_crypto_tools
# install_misc_tools
# install_osint_tools
install_rev_tools
