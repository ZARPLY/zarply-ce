# Zarply Setup on Windows (with Ubuntu)

**Contents**
1. [Install VMware and Ubuntu]
1. [Create and Configure the VM]
2. [Base System Update]
3. [Install FLutter & Andriod Studio]
4. [Install & Launch Cursor AI]
5. [Generate SSH Keys & Clone Repo]s


1. **Install VMware Workstation & Ubuntu ISO**

    - Download & install VMware Workstation from https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion
    - Download Ubuntu Desktop ISO from https://ubuntu.com/download/desktop

2. **Create & Configure the VM**  

    - Open VMware Workstation and select 'Create a New Virtual Machine'.  
    - Choose the downloaded Ubuntu ISO as the installer disc image.  
    - Name the VM 
    - Allocate CPU/RAM
    - Complete the wizard and power on the VM.

3. **Base System Update**  

   Open a terminal and run:  
   ```bash
   sudo apt-get update
   sudo apt-get upgrade -y
   ```

4. **Install Flutter & Andriod Studio**

    ```bash
    sudo snap install flutter --classic
    sudo snap install android-studio --classic
    flutter doctor
    ```

    NOTE: Follow any prompts from flutter doctor to install missing dependencies.

5. **Install & Launch Cursor AI** 

    - In Firefox, download the Cursor AI AppImage from https://www.cursor.com/
    - Open a terminal and run: 

    ```bash
    cd ~/Downloads
    chmod a+x Cursor-*.AppImage
    ./Cursor-*.AppImage --no-sandbox
    ```

    NOTE: On first run, enable Privacy Mode when prompted and complete account setup.

6. **Generate SSH Key & Clone ZARPLY Repo On Windows**

    ```bash
    ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/<your_key_name>
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/<your_key_name>
    cat ~/.ssh/<your_key_name>.pub
    ```

    - In Gitea Web UI:
        - Go to Settings → SSH / GPG Keys → Add Public Key
        - Paste the contents of <your_key_name>.pub and save

    - In a terminal run: 

    ```bash
    mkdir -p ~/projects
    cd ~/projects
    git clone <ssh-clone-url-for-your-repo> <your_clone_directory>
    cd <your_clone_directory>
    ``` 

## Additional Resources 

Please refer to the setup doc in the docs directory. [here](docs/setup.md)
Please refer to the README doc. [here](/README.md)