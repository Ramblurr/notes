# Unifi UDR

To run scripts at boot install:

https://github.com/unifi-utilities/unifios-utilities/tree/main/on-boot-script

You can now place your scripts in `/data/on_boot.d`

Disable the CNI stuff it installs by default.

To persist `/root/.ssh/authorized_keys`, place the following in `/data/on_boot.d/15-add-root-ssh-keys.sh` and `chmod +x` it.

Place your `authorized_keys` file in `/data/on_boot.d/settings/ssh/authorized_keys`

```
#!/bin/bash

set -e

## Places public keys in ~/.ssh/authorized_keys

KEYS_SOURCE_FILE="/data/on_boot.d/settings/ssh/authorized_keys"
KEYS_TARGET_FILE="/root/.ssh/authorized_keys"

count_added=0
count_skipped=0
while read -r key; do
	# Places public key in ~/.ssh/authorized_keys if not present
	if ! grep -Fxq "$key" "$KEYS_TARGET_FILE"; then
		let count_added++ || true
		echo "$key" >> "$KEYS_TARGET_FILE"
	else
	   let count_skipped++ || true
	fi
done < "$KEYS_SOURCE_FILE"

echo "${count_added} keys added to ${KEYS_TARGET_FILE}"
if [ $count_skipped -gt 0 ]; then
    echo "${count_skipped} already added keys skipped"
fi
exit 0
```

