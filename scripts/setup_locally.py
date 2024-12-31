import subprocess
import os
from pathlib import Path

def run_command(command):
    """Run a shell command and return its output"""
    try:
        result = subprocess.run(command, shell=True, check=True, 
                              capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{command}': {e}")
        return None

def setup_solana_wallet():
    # Install Solana CLI (Note: this step might require user interaction)
    print("Installing Solana CLI...")
    install_cmd = 'sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"'
    run_command(install_cmd)

    version = run_command("solana --version")
    if not version:
        print("Failed to verify Solana installation")
        return

    print(f"Solana CLI installed: {version}")

    print("Setting network to devnet...")
    run_command("solana config set --url https://api.devnet.solana.com")

    print("Creating new wallet...")
    run_command("solana-keygen new --no-bip39-passphrase")

    public_key = run_command("solana-keygen pubkey")
    if not public_key:
        print("Failed to get public key")
        return

    print(f"Generated public key: {public_key}")

    balance = run_command("solana balance")
    print(f"Wallet balance: {balance}")

    env_path = Path('../.env')
    env_content = ""
    
    if env_path.exists():
        with open(env_path, 'r') as f:
            env_content = f.read()

    if 'SOLANA_WALLET_DEVNET_PUBLIC_KEY' in env_content:
        env_lines = env_content.splitlines()
        new_lines = []
        for line in env_lines:
            if line.startswith('SOLANA_WALLET_DEVNET_PUBLIC_KEY='):
                new_lines.append(f'SOLANA_WALLET_DEVNET_PUBLIC_KEY={public_key}')
            else:
                new_lines.append(line)
        env_content = '\n'.join(new_lines)
    else:
        env_content += f'\nSOLANA_WALLET_DEVNET_PUBLIC_KEY={public_key}'

    with open(env_path, 'w') as f:
        f.write(env_content)

    print(f"\nSuccessfully updated .env file with public key")

if __name__ == "__main__":
    setup_solana_wallet()