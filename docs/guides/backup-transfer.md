# Backup and transfer

Admincraft can move all saved server profiles between computers, phones, and browsers without creating an account.

Exports contain server secret keys and may contain pinned certificates. Admincraft therefore encrypts every transfer with a passphrase before it reaches the clipboard or a file.

## Export profiles

1. Open **Settings → Backup & Transfer**.
2. Choose **Copy config** or **Export file**.
3. Enter the same passphrase twice.
4. Move the copied text or `admincraft-servers.json` file to the other device.

Use a long passphrase that you do not use elsewhere. The passphrase is not stored in the export and cannot be recovered.

## Import on another device

1. Open **Settings → Backup & Transfer**.
2. Choose **Paste config** or **Import file**.
3. Enter the export passphrase.
4. Review the number of profiles and confirm the import.

Profiles with matching internal IDs are updated. Profiles with different IDs are appended, and other profiles already on the device stay in place.

## What is protected?

The transfer envelope is versioned and uses:

- PBKDF2-HMAC-SHA256 to derive a key from the passphrase.
- AES-256-GCM to encrypt and authenticate the profile data.
- Fresh random salt and nonce values for every export.

The readable JSON wrapper identifies the format and contains the cryptographic parameters. Server addresses, aliases, keys, and certificates are inside the encrypted data.

!!! warning

    Anyone with both the export and its passphrase can recover the server secret keys. Delete transfers you no longer need, and do not send the passphrase through the same channel as the file.

## Import errors

| Message | What to do |
| --- | --- |
| Wrong passphrase, or the config is damaged | Check the passphrase and transfer the file again if necessary |
| Config is incomplete or damaged | Copy the entire text or choose the original file again |
| Made by a newer Admincraft version | Update Admincraft before importing |
| Not an Admincraft config | Choose the encrypted file created by Admincraft |
