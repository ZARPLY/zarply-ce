**Considerations**
1. [Storage of BIP-39 Phrase]


1. **Storage of BIP-39 Phrase**

**Background**

    - The wallet writes the BIP‑39 recovery phrase to secure storage only when it is first    generated during onboarding. 
    - If a user restores the wallet with a private key instead of the mnemonic, the phrase is never persisted.

**Impact**

    - More Screen → BIP‑39 Recovery Phrase screen shows “No recovery phrase found.”
    - Users who restored via private key have no in‑app way to view / back‑up their 12‑word phrase






