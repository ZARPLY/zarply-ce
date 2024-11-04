# ZARPLY BRS
> a stablecoin account in your pocket

The design methodology taken with this non custodial ZARP(SOL) wallet is to be 100% offline except for direct calls to the Solana block chain for account information.

The application provides the following screens:

* Screen 1: login (light theme)
            ZARPLY logo
            mobile:
            password:
            
            [login]
            [register] --> redirect to screen 2
            [forget pw] --> you are screwed (suggest restoring wallet)
            [restore wallet] --> redirect to screen 6: restore
            
* screen 2: register
           handle/username:
           mobile:
           
           - send SMS (hash of the above) and read and confirm SMS (hash)
           :: Generate Wallet Step
                   generate account on SOL
                   generate account on ZARP
           stores this locally on phone
           generate BIP39 recovery word sequence
           show & write down SMS with the recovery BIP39 recover words**do not delete but write down
           ask to enter pw & confirm pw <-- save in TPM
           --> redirect to login
           
           
           
* screen 3: wallet
          [SOL | [ZARP]] toggle
          balance: lamport | R
          txns: ... /... /... /... :confirmed/pending/failed [open]
           
* screen 4: request to pay
          amount: amount to be requested (or no amount for any amount)
          description: <optional>
          [[[2D BARCODE with logo]] <- encodes your ZARP account & amount requested + tiny hash
            - must saveable/printable/sendable
          
* screen 5: pay & beneficiaries
          [ wallet | [RTP]]
          -- RTP:: scan the barcode (display the embedded amount, & <description>) 
          -- wallet
              wallet number:
              amount:
              reference :<memo field>
              [save as beneficiary]
          [Confirm]
          [SEND]
          
* screen 6: security & settings
          backup wallet <-- display barcode (BIP39) + 12 words
          restore wallet:
            - wipe the TPM (BEWARE notice)
            - BIP39 12 words + open the scanner + [restore]
            --> store the wallet id and redirect to Register (bypass the generate step)
*screen 7: About
          - link to github
          - link to OVEX.IO for those that want to fund their wallets
          - use at own risk ...

---

&copy; Copyright 2024, Cyber-Mint (Pty) Ltd, Kodezero (Pty) Ltd