# Move Wuthering Waves to an External Disk on macOS

[English](./README.md) | [繁體中文](./README.zh-TW.md)

## Summary

- Wuthering Waves version: `3.2.0`
- macOS version: `26.4 (25E246)`
- External disk: `Samsung T7 1TB`

```text
T7
├── Applications
│   └── WutheringWaves.app
│       └── Contents
│           ├── _CodeSignature
│           ├── _MASReceipt
│           ├── Frameworks
│           └── ...
└── WuwaData
    └── Resources
        ├── 3.1.0
        │   ├── Diff
        │   ├── Launcher
        │   │   └── 3.1.17
        │   ├── Mount
        │   ├── ResManifest
        │   └── Resource
        │       └── 3.1.18
        └── 3.2.0
            ├── Launcher
            │   └── 3.2.8
            ├── Mount
            ├── ResManifest
            └── Resource
                ├── 3.2.10
                └── Base (downloading...)
```

The game may use two resource paths:

1. `~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0`
2. `~/Library/Client/Saved/Resources/3.2.0`

> [!note]
> App Store builds normally run in the macOS app sandbox, so resources are written under the first container path. If the app is re-signed with a plain ad-hoc signature, the sandbox entitlement is usually removed, and the game may start using the second path instead.

> [!warning]
> The internal disk may still need enough free space to start the download, about 80GB. This appears to be a pre-download space check and may happen before the game follows the final symlink target.

## Recommended Order

### Option 1: Codesign First, Then Link the Resource Version

This is the recommended path for a fresh App Store install on an external disk:

1. Install `WutheringWaves.app` to the external disk from the App Store.
2. Before downloading the large in-game resources, re-sign the app.
3. Let the game use the unsandboxed path: `~/Library/Client`.
4. Keep `~/Library/Client/Saved/Resources` as a real local folder.
5. Only symlink the version folder, such as `3.2.0` or `3.4.0`, to the external disk.

Re-sign the app:

```shell
sudo codesign --sign - --force --deep "/Volumes/T7/Applications/WutheringWaves.app"
```

> [!note]
> This command uses an ad-hoc signature. Because it does not pass `--preserve-metadata=entitlements`, it usually does not keep the original App Store entitlements.
>
> The important entitlement is: `com.apple.security.app-sandbox`
>
> App Sandbox mainly depends on that entitlement. If it is removed, macOS no longer treats Wuthering Waves as a sandboxed app. In that state, the game usually stops writing to the container path: `~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client`
>
> and starts writing to the regular user Library path: `~/Library/Client`
>
>That is why this is the first recommended method. If you plan to re-sign the app immediately after installing it, and you confirm the sandbox entitlement is gone, the container resource symlink is usually unnecessary.

You can inspect the current entitlements with:

```shell
codesign -d --entitlements :- "/Volumes/T7/Applications/WutheringWaves.app"
```

If `com.apple.security.app-sandbox` is gone, use only the `~/Library/Client` path:

```shell
mkdir -p "$HOME/Library/Client/Saved/Resources"
mkdir -p "/Volumes/T7/WuwaData/Resources/3.2.0"
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Client/Saved/Resources/3.2.0"
```

> [!warning]
> If `~/Library/Client/Saved/Resources/3.2.0` already exists as a real folder, move or copy its contents to `/Volumes/T7/WuwaData/Resources/3.2.0` before creating the symlink.

### Option 2: Symlink the Whole Client Folder

This is the second choice. It is cleaner after re-signing because all future `Client` data is created on the external disk automatically, but it moves more than just downloaded resources.

Use this only after the app has been re-signed and the game is fully closed:

```shell
mkdir -p "/Volumes/T7/WuwaData/Client"
mv "$HOME/Library/Client" "$HOME/Library/Client.old"
ln -s "/Volumes/T7/WuwaData/Client" "$HOME/Library/Client"
```

If you already have useful data under `~/Library/Client`, copy or move it into `/Volumes/T7/WuwaData/Client` before creating the symlink.

If an App Store update restores the original sandboxed signature, Wuthering Waves may go back to the container path and ignore this link until you re-sign it again.

### Option 3: Conservative Fallback

Use this if:

- you already started the game before re-signing
- `com.apple.security.app-sandbox` is still present
- you are not sure whether the game is using the container path or `~/Library/Client`
- an App Store update restored the original signature

This fallback links the version folder in both possible locations.

Keep the parent `Resources` folder as a real local folder, and only symlink the version folders inside it:

```text
Resources/
├── 3.1.0 -> /Volumes/T7/WuwaData/Resources/3.1.0
├── 3.2.0 -> /Volumes/T7/WuwaData/Resources/3.2.0
└── 3.4.0 -> /Volumes/T7/WuwaData/Resources/3.4.0
```

Do not symlink the whole `Resources` folder unless you are experimenting. Reports from large updates suggest that Wuthering Waves may create the new version folder but fail its patch or space detection when `Resources` itself is a symlink.

## Conservative Fallback Steps

### Step 0: Fully close the game first

Close all of the following before changing symlinks:

- Wuthering Waves
- Any active downloader process

Do not modify symlinks while the game is downloading.

### Step 1: Prepare target folder on external SSD

Create the destination folder:

```shell
mkdir -p "/Volumes/T7/WuwaData/Resources/3.2.0"
```

This is where game resources should actually live.

If some files were already downloaded locally, either remove them or move them to T7.

### Step 2: Symlink the first resource entry

Remove existing local folder or move it to T7:

```shell
rm -rf "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
mv "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0" "/Volumes/T7/WuwaData/Resources/3.2.0"
```

Create symlink:

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

### Step 3: Symlink the second resource entry as well

Remove existing local folder:

```shell
rm -rf "$HOME/Library/Client/Saved/Resources/3.2.0"
```

Create symlink:

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Client/Saved/Resources/3.2.0"
```

### Step 4: Verify both links

Run:

```shell
ls -l "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
ls -l "$HOME/Library/Client/Saved/Resources/3.2.0"
```

Expected output should look like:

```shell
$ ls -l
total 0
lrwxr-xr-x@ 1 yuva  staff   36 Feb 13 14:41 3.1.0 -> /Volumes/T7/WuwaData/Resources/3.1.0
lrwxr-xr-x@ 1 yuva  staff   36 Mar 29 04:02 3.2.0 -> /Volumes/T7/WuwaData/Resources/3.2.0
```

As long as both entries point to the same external folder, it is correct.

### Step 5: Reopen game and continue download

Start the game again.

Whether it uses:

- `~/Library/Containers/.../3.2.0`
- `~/Library/Client/.../3.2.0`

it should eventually write to:

`/Volumes/T7/WuwaData/Resources/3.2.0`

### Step 6: Confirm files are being downloaded to T7

Open this folder in Finder:

`/Volumes/T7/WuwaData/Resources/3.2.0`

or

```shell
cd "/Volumes/T7/WuwaData/Resources/3.2.0"
du -hd 1 | sort -hr
```

If files keep increasing, the setup is working.

### Rules of thumb

If you see these two prompts after launching Wuthering Waves, setup is likely successful:

![img](./assets/Screenshot%202026-03-29%20at%2003.51.06.png)
![img](./assets/Screenshot%202026-03-29%20at%2003.52.21.png)

### Codesign Screenshot

![error_message_in_game](./assets/error_message_in_game.png)
![time_spent](./assets/time_spent.png)

In this case, the app was installed to external storage through the App Store, so the path is:

`/Volumes/T7/Applications/WutheringWaves.app`

If your app is on internal storage, it is usually:

`/Applications/WutheringWaves.app`

### Clean old data

If you've already started downloading additional resources, the data from the previous version is no longer important. You can delete the files and corresponding symlinks to free up your Mac's limited built-in storage space.

In fact, even if you don't delete them, after the additional resources finish downloading, the folder from the previous version will only have a few KB of data left, taking up almost no space. However, if you want to completely remove it, you can execute:

```shell
rm -rf "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.1.0"
rm -rf "$HOME/Library/Client/Saved/Resources/3.1.0"
rm -rf /Volumes/T7/WuwaData/Resources/3.1.0
```

## References

1. [Moving Resources Into External Drive to Save Storage (Mac Case)](https://www.reddit.com/r/WutheringWaves/comments/1q16kio/moving_resources_into_external_drive_to_save/)
