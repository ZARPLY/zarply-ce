# Run the App (with VS Code)

To run your Flutter application using Visual Studio Code (VS Code), follow these steps:

1. **Set up VS Code**:

   Refer to the [official Flutter documentation](https://docs.flutter.dev/get-started/editor?tab=vscode) for
   instructions on setting up VS Code for Flutter development.

2. **Run the app with VS Code**:

   Follow the instructions provided in
   the [official Flutter documentation](https://docs.flutter.dev/get-started/test-drive?tab=vscode) to run your Flutter
   app using VS Code.


# Run the App

You can run your Flutter application on various platforms, including emulators and real devices. Follow the instructions
below:

1. **Check available devices**:

   Before running the app, ensure that you have devices/emulators available by executing the following command:

    ```bash
    flutter devices
    ```

2. **Check if flutter is install**:

    ```bash
    flutter doctor
    ```

    NOTE: if the logs indicate you need to setup XCode and Andriod Studio please install the tools and accept its license terms. 
    Install Andriod Studio emulators and make sure they are running if you want to test the app on those emulators.

3. **Install dependencies**

   ```bash
    flutter pub get
    ```

4. **Run the app on different devices**:

    On Chrome
    ```bash
    flutter run -d chrome
    ```

    On Andriod
    ```bash
    flutter run -d android
    ```

    On IOS
    ```bash
    flutter run -d ios
    ```

    NOTE: look at the connected devices and specify the names you see in that list to run your flutter app on the device you need.

5. **How to test app locally**

   Configure the .env file with the correct solana_wallet_devnet_public_key value. Create a new wallet on your terminal.

   ```bash
   # install solana cli
   sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

   # confirm solana cli is installed
   solana --version

   # set network to devnet
   solana config set --url https://api.devnet.solana.com

   # create a new wallet
   solana-keygen new --no-bip39-passphrase

   # get the public key
   solana-keygen pubkey

   # check the balance
   solana balance
   ```

   Copy the public key and paste it in the .env file.

   There is a script to do this for you.

   ```bash
   python3 scripts/setup-locally.py
   ```
