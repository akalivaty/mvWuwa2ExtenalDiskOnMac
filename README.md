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

The game uses two resource paths:

1. `~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0`
2. `~/Library/Client/Saved/Resources/3.2.0`

Initially, Wuthering Waves usually downloads additional resources to the first path. If a symlink is found, it will download to the second path. Therefore, a single symlink is usually not enough.

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

It may still write to the second path afterward.

Final conclusion: the most reliable method is to symlink **both paths** to the same external folder.

## Full Steps

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
rm -rf "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
mv "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0" "/Volumes/T7/WuwaData/Resources/3.2.0"
```

Create symlink:

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

### Step 3: Symlink the second resource entry as well

Remove existing local folder:

```shell
rm -rf "~/Library/Client/Saved/Resources/3.2.0"
```

Create symlink:

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "~/Library/Client/Saved/Resources/3.2.0"
```

### Step 4: Verify both links

Run:

```shell
ls -l "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
ls -l "~/Library/Client/Saved/Resources/3.2.0"
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

### Codesign

If you get a launch error like `Failed to ...` after moving app resources, run:

```shell
sudo codesign --sign - --force --deep "/Volumes/T7/Applications/WutheringWaves.app"
```

In this case, the app was installed to external storage through the App Store, so the path is:

`/Volumes/T7/Applications/WutheringWaves.app`

If your app is on internal storage, it is usually:

`/Applications/WutheringWaves.app`

If the game already launches fine and only resource path is the problem, you can skip this step.

### Clean old data

If you've already started downloading additional resources, the data from the previous version is no longer important. You can delete the files and corresponding symlinks to free up your Mac's limited built-in storage space.

In fact, even if you don't delete them, after the additional resources finish downloading, the folder from the previous version will only have a few KB of data left, taking up almost no space. However, if you want to completely remove it, you can execute:

```shell
rm -rf "~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.1.0"
rm -rf "~/Library/Client/Saved/Resources/3.1.0"
rm -rf /Volumes/T7/WuwaData/Resources/3.1.0
```

## Script (Testing... Don't use yet)

Usage:

```bash
chmod +x wuwa_symlink_menu.sh
./wuwa_symlink_menu.sh
```

The first time you run it, it's recommended to select:

```text
4) 重新設定版本號與路徑
```

Then input your settings:

```text
版本號: 3.2.0
外接硬碟名稱: T7
外接資料夾名稱: WuwaData
App container ID: com.kurogame.wutheringwaves.global
```

Then usually it's just:

- 1 Create / update symlink
- 2 Check status

These two are the most commonly used.

Note that option 3) Remove symlink will only change the two entries back to local empty folders. It will not move data back from T7, nor will it delete data on T7.

## References

1. [Moving Resources Into External Drive to Save Storage (Mac Case)](https://www.reddit.com/r/WutheringWaves/comments/1q16kio/moving_resources_into_external_drive_to_save/)
