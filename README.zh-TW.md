# 在 macOS 上把鳴潮移到外接硬碟

[English](./README.md) | [繁體中文](./README.zh-TW.md)

## 摘要

- 鳴潮版本：`3.2.0`
- macOS 版本：`26.4 (25E246)`
- 外接硬碟：`Samsung T7 1TB`

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

遊戲可能會使用兩個資源路徑：

1. `~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0`
2. `~/Library/Client/Saved/Resources/3.2.0`

> [!note]
> App Store 版本預設會跑在 macOS app sandbox 裡，所以資源通常會寫到第一個 container 路徑。如果用普通 ad-hoc 簽章重新 codesign，通常會移除原本的 sandbox entitlement，遊戲之後可能改用第二個路徑。

> [!warning]
> 內建硬碟可能仍然要有足夠空間才能啟動下載動作，大概 80GB。這看起來像下載前的空間檢查，可能發生在遊戲跟到最終 symlink 目標之前。

## 建議順序

### 選項 1：先 Codesign，再連結資源版本資料夾

這是 App Store 全新安裝到外接硬碟時最推薦的路線：

1. 先用 App Store 把 `WutheringWaves.app` 安裝到外接硬碟。
2. 在下載大量遊戲內資源前，先重新 codesign。
3. 讓遊戲改走 unsandbox 後的路徑：`~/Library/Client`。
4. 讓 `~/Library/Client/Saved/Resources` 保持本機實體資料夾。
5. 只把版本號資料夾，例如 `3.2.0` 或 `3.4.0`，symlink 到外接硬碟。

重新簽 app：

```shell
sudo codesign --sign - --force --deep "/Volumes/T7/Applications/WutheringWaves.app"
```

> [!note]
> 這個指令會用 ad-hoc 簽章重新簽 app。因為沒有加 `--preserve-metadata=entitlements`，通常不會保留原本 App Store 簽章裡的 entitlements。
>
> 關鍵 entitlement 是： com.apple.security.app-sandbox
>
> App Sandbox 主要就是靠這個 entitlement。當它被移除後，macOS 就不再把鳴潮當成 sandbox app 執行。這時遊戲通常不再寫到 container 路徑： `~/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client`
>
> 而是改寫到一般使用者 Library 路徑： `~/Library/Client`
>
> 這就是為什麼這份文件把它放在第一推薦。如果你一開始就打算在安裝完後立刻 codesign，而且確認 sandbox entitlement 已經消失，通常就不需要再替 container 資源路徑建立 symlink。

可以用這個指令檢查目前 entitlements：

```shell
codesign -d --entitlements :- "/Volumes/T7/Applications/WutheringWaves.app"
```

如果已經看不到 `com.apple.security.app-sandbox`，只處理 `~/Library/Client` 路徑即可：

```shell
mkdir -p "$HOME/Library/Client/Saved/Resources"
mkdir -p "/Volumes/T7/WuwaData/Resources/3.2.0"
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Client/Saved/Resources/3.2.0"
```

> [!warning]
> 如果 `~/Library/Client/Saved/Resources/3.2.0` 已經是實體資料夾，請先把內容搬移或複製到 `/Volumes/T7/WuwaData/Resources/3.2.0`，再建立 symlink。

### 選項 2：把整個 Client 資料夾做成 symlink

這是第二選擇。重新簽名後這個方法比較省事，因為之後所有新的 `Client` 資料都會自動建立在外接硬碟，但它移動的不只是下載資源。

請只在 app 已重新 codesign，而且遊戲已完全關閉後執行：

```shell
mkdir -p "/Volumes/T7/WuwaData/Client"
mv "$HOME/Library/Client" "$HOME/Library/Client.old"
ln -s "/Volumes/T7/WuwaData/Client" "$HOME/Library/Client"
```

如果 `~/Library/Client` 裡已經有重要資料，請先複製或搬到 `/Volumes/T7/WuwaData/Client`，再建立 symlink。

如果 App Store 更新恢復原本 sandbox 簽章，鳴潮可能又回去使用 container 路徑，直到你再次 codesign。

### 選項 3：最保守的備援方法

以下情況再用這個方法：

- 你已經在重新 codesign 前啟動過遊戲
- `com.apple.security.app-sandbox` 仍然存在
- 你不確定遊戲目前使用 container 路徑還是 `~/Library/Client`
- App Store 更新恢復了原本簽章

這個備援方法會同時處理兩個可能位置裡的版本號資料夾。

讓上一層 `Resources` 保持本機實體資料夾，只把裡面的版本號資料夾做成 symlink：

```text
Resources/
├── 3.1.0 -> /Volumes/T7/WuwaData/Resources/3.1.0
├── 3.2.0 -> /Volumes/T7/WuwaData/Resources/3.2.0
└── 3.4.0 -> /Volumes/T7/WuwaData/Resources/3.4.0
```

除非是在實驗，否則不建議把整個 `Resources` 資料夾做成 symlink。其他使用者回報，大版本更新時鳴潮可能會建立新的版本資料夾，但 patch 或空間偵測會失敗。

## 最保守備援步驟

### Step 0：先完全關掉遊戲

先關掉：

- 鳴潮
- 任何還在下載的程序

不要在遊戲下載途中修改 symlink。

### Step 1：建立外接 SSD 目的資料夾

先建立外接硬碟上的目標路徑：

```shell
mkdir -p "/Volumes/T7/WuwaData/Resources/3.2.0"
```

這個資料夾就是之後真正存放資源的位置。

如果本機已經下載了一部分資料，請先刪除或搬移到 T7。

### Step 2：把第一個入口改成 symlink

先刪除本機原本的 `3.2.0` 或搬到 T7：

```shell
rm -rf "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
mv "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0" "/Volumes/T7/WuwaData/Resources/3.2.0"
```

再建立連結：

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

### Step 3：把第二個入口也改成 symlink

先刪除本機原本的 `3.2.0`：

```shell
rm -rf "$HOME/Library/Client/Saved/Resources/3.2.0"
```

再建立連結：

```shell
ln -s "/Volumes/T7/WuwaData/Resources/3.2.0" "$HOME/Library/Client/Saved/Resources/3.2.0"
```

### Step 4：檢查兩條路徑是否都正確

執行：

```shell
ls -l "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.2.0"
```

```shell
ls -l "$HOME/Library/Client/Saved/Resources/3.2.0"
```

理想結果會像：

```shell
$ ls -l
total 0
lrwxr-xr-x@ 1 yuva  staff   36 Feb 13 14:41 3.1.0 -> /Volumes/T7/WuwaData/Resources/3.1.0
lrwxr-xr-x@ 1 yuva  staff   36 Mar 29 04:02 3.2.0 -> /Volumes/T7/WuwaData/Resources/3.2.0
```

只要兩邊都指向同一個外接資料夾就正確。

### Step 5：重新開遊戲繼續下載

重新啟動遊戲。

不論它走：

- `~/Library/Containers/.../3.2.0`
- `~/Library/Client/.../3.2.0`

最後都應該寫到：

`/Volumes/T7/WuwaData/Resources/3.2.0`

### Step 6：確認真的下載到 T7

在 Finder 直接打開：

`/Volumes/T7/WuwaData/Resources/3.2.0`

或是

```shell
cd "/Volumes/T7/WuwaData/Resources/3.2.0"
du -hd 1 | sort -hr
```

如果檔案持續增加，代表已成功下載到外接 SSD。

### 判斷是否成功

開啟鳴潮後如果出現以下兩個請求，通常表示設定成功：

![img](./assets/Screenshot%202026-03-29%20at%2003.51.06.png)
![img](./assets/Screenshot%202026-03-29%20at%2003.52.21.png)

### Codesign 截圖

![error_message_in_game](./assets/error_message_in_game.png)
![time_spent](./assets/time_spent.png)

這裡的路徑是因為透過 App Store 安裝到外接硬碟：

`/Volumes/T7/Applications/WutheringWaves.app`

如果你是安裝在內建硬碟，通常會是：

`/Applications/WutheringWaves.app`

### 清除舊資料

如果已經開始下載額外資源，上一個版本的資料也不再重要，可以刪除檔案和對應的 symlink，釋放 Mac 可憐的內建儲存空間。

實際上就算不刪除，最後額外資源下載完後，上一個版本的資料夾也會只剩下幾 KB 的資料，不佔空間，但如果想徹底清除，可以執行：

```shell
rm -rf "$HOME/Library/Containers/com.kurogame.wutheringwaves.global/Data/Library/Client/Saved/Resources/3.1.0"
rm -rf "$HOME/Library/Client/Saved/Resources/3.1.0"
rm -rf /Volumes/T7/WuwaData/Resources/3.1.0
```

## 參考資料

1. [Moving Resources Into External Drive to Save Storage (Mac Case)](https://www.reddit.com/r/WutheringWaves/comments/1q16kio/moving_resources_into_external_drive_to_save/)
