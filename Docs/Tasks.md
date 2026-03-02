# ZeroType — 任務列表

> 標記說明：`[前置]` = 此任務必須先完成才能進行後續任務

---

## 🏗️ 一、專案設定 (Project Setup)

> 其他所有任務的前置條件，優先完成。

- [x] **[前置]** 建立 Flutter 多平台專案（macOS + Windows）
- [x] **[前置]** 設定套件依賴（`pubspec.yaml`）
  - `riverpod` / `flutter_riverpod` — 狀態管理
  - `freezed` / `json_serializable` — UI state model
  - `get_it` — DI
  - `auto_route` — 路由
  - `flutter_secure_storage` — API Key 安全儲存
  - `record` — 錄音
  - `hotkey_manager` — 全局快捷鍵
  - `tray_manager` — 系統列常駐
  - `launch_at_startup` — 開機啟動
  - `dio` — API 呼叫
  - `path_provider` — 暫存音檔路徑
  - `package_info_plus` — 取得 App 資訊（開機啟動用）
- [x] **[前置]** 建立 Clean Architecture 資料夾結構（`features/`, `core/`, `shared/`）
- [x] **[前置]** 設定 `GetIt` 依賴注入容器（`SharedPreferences` + `FlutterSecureStorage`）
- [x] **[前置]** 建立 providers config JSON 設定檔（語音辨識 & AI 精修的 Provider/Model 清單）
- [x] **[前置]** 設定 `auto_route` 路由（`MainShellPage` + 4 個子頁面）

---

## ⚙️ 二、系統層 / OS 整合 (System Integration)

> 依賴：專案設定完成

- [x] **[前置]** 麥克風權限請求（macOS `Info.plist` 加入 `NSMicrophoneUsageDescription`；`DebugProfile.entitlements` 加入 `audio-input`）
- [ ] **[前置]** 輔助使用 (Accessibility) 權限請求流程（macOS：貼上用 `CGEvent` 模擬 `Cmd+V` 所需）
  - 目前 `AppDelegate.swift` 已實作 `CGEvent` 貼上，但需引導使用者到系統設定 > 隱私權 > 輔助使用 開啟權限
- [x] 全局快捷鍵監聽（`HotkeyService`，預設 `Alt+Space`，`hotkey_manager`）
- [x] 錄音後模擬鍵盤貼上（`Cmd+V`）到游標位置
  - macOS：`AppDelegate.swift` 使用 `CGEvent` 模擬
  - Windows：待實作
- [x] System Tray / Menu Bar 常駐（`TrayService`，`tray_manager`）
  - [x] 主視窗關閉時縮小（hide）而非退出（`onWindowClose` → `windowManager.hide()`）
  - [x] Tray 選單：顯示視窗 / 結束
- [ ] 開機啟動開關（`launch_at_startup`，已設定初始化，UI 開關待設定頁實作）

---

## 🎙️ 三、核心業務邏輯 (Core Logic)

> 依賴：專案設定、系統層麥克風權限

### 3.1 錄音模組
- [x] **[前置]** 開始/停止錄音邏輯（`RecordingService`，儲存至系統暫存資料夾，16kHz M4A）
- [x] **[前置]** 音訊振幅取樣（100ms 頻率，正規化至 0.0~1.0，提供給 overlay UI）
- [x] 取消錄音 → 刪除暫存音檔（`cancelRecording()`）
- [x] 錄音完成後自動刪除暫存音檔（辨識/精修完成後 `deleteFile()`）
- [x] 取消旗標（`_cancelled`）：`cancel()` 可中斷任意階段的 async 流程

### 3.2 語音辨識模組（OpenAI / Transcribe）
- [x] **[前置]** 建立 `ModelConfigRepository` 介面（含語音辨識 Provider/Model/Key 存取）
- [x] 實作 OpenAI Transcribe API 串接（`SpeechRecognitionService`，multipart 上傳，回傳純文字）
- [x] API Key 儲存與讀取（`FlutterSecureStorage`，per-provider key）
- [x] 錯誤處理：未設定 API Key / Provider/Model 時顯示錯誤 overlay

### 3.3 AI 精修模組（Gemini）
- [x] **[前置]** 建立 `TextRefinementRepository` 介面（含精修 Provider/Model/Key 存取）
- [x] 實作 Gemini API 串接（`TextRefinementService`，`generateContent` endpoint，支援 `systemInstruction`）
- [x] API Key 儲存與讀取
- [x] 精修可選：`isRefinementEnabled` 開關；Key 或 Model 未設定時直接回傳辨識結果

### 3.4 字典檔模組
- [x] 讀取/寫入字典 txt 檔案（存於 `applicationSupportDirectory`）
- [x] 新增字詞（輸入框 + Enter / 按鈕），重複字詞自動略過
- [x] 字詞列表依字母排序
- [x] 組合字典檔內容至 Prompt（`buildDictionaryPrompt()`，與語音辨識 Prompt 合併）

---

## 🖥️ 四、主視窗 UI (Main Window)

> 依賴：核心業務邏輯、專案設定

### 4.1 Layout 架構
- [x] **[前置]** 左側 `NavigationRail` 導航欄 + 右側內容區 Shell Layout（`MainShellPage`）
- [x] **[前置]** `ThemeData` 深色主題定義（`AppTheme.darkTheme`，主色 `#6C63FF`）

### 4.2 模型設定頁（`ModelConfigPage`）
- [x] 可收合的「語音辨識」Section（`[必填]` 紅標，預設展開）
- [x] 可收合的「AI 精修」Section（Switch 開關控制啟用，停用時半透明）
- [x] Provider 選擇（`ChoiceChip`）→ 展開對應 Model 下拉選單
- [x] API Key 輸入框（密碼遮罩、眼睛圖示切換顯示、儲存至 Keychain）

### 4.3 字典檔頁（`DictionaryPage`）
- [x] 輸入框 + 加入按鈕 / Enter 新增
- [x] 字詞列表（字母排序）+ 刪除按鈕
- [x] 空狀態 UI（書本圖示 + 提示文字）

### 4.4 提示詞修改頁（`PromptPage`）
- [x] 語音辨識系統提示詞編輯區（含中文預設提示詞）
- [x] AI 精修系統提示詞編輯區（含中文預設提示詞）
- [x] Dirty tracking（有修改才啟用儲存按鈕）
- [x] 還原預設按鈕（`resetToDefault()`）

### 4.5 設定頁（`SettingsPage`）
- [x] 開機啟動開關（`launch_at_startup`）
- [x] 全局快捷鍵錄製設定（顯示當前快捷鍵、點擊後進入錄製模式）

---

## 🎛️ 五、浮動錄音 Overlay (Floating Overlay)

> 依賴：核心業務邏輯（錄音、辨識、精修）
> 實作方式：macOS `NSPanel`（AppKit），透過 `MethodChannel 'com.zerotype.app/overlay'` 控制

- [x] **[前置]** 浮動視窗基礎（`NSPanel`，無邊框、`level = .floating`，浮在所有視窗之上，不搶 focus）
- [x] 位置：x 軸螢幕置中，y 軸底部往上 60px（`NSRect` 定位，跟隨主螢幕）
- [x] 狀態一：**錄音中** — 脈衝圓點動畫 + 波形視覺化（`WaveformView`，AppKit 繪製）
- [x] 狀態二：**辨識中** — 藍色文字「語音辨識中…」
- [x] 狀態三：**AI 精修中** — 藍色文字「AI 精修中…」
- [x] 狀態四：**錯誤** — 紅色文字，自動 3 秒後隱藏
- [x] 完成後自動隱藏（綠色「完成！」2 秒後消失）
- [x] `Esc` / 點擊任何地方 → `cancel()` 中止整個流程並隱藏 overlay
- [x] 啟動錄音音效（Tink）、停止音效（Pop）、取消音效（Basso）

---

## ✅ 建議開發順序

```
專案設定
  → 系統層（權限、Tray、快捷鍵）
    → 核心邏輯（錄音 → 語音辨識 → AI 精修 → 貼上）
      → 浮動錄音 Overlay（與核心邏輯同步驗證）
        → 主視窗 UI（設定頁、模型設定、字典檔、提示詞）
```

## 📋 待辦清單（尚未實作）

- [x] 設定頁：開機啟動開關 UI
- [x] 設定頁：全局快捷鍵錄製 UI
- [x] Accessibility 權限引導 UI（貼上功能必須）
- [x] Windows 貼上功能（`SendInput`）
- [ ] 錯誤處理細化（網路失敗重試、API 額度不足提示）

---

## 🪟 六、Windows 跨平台兼容（Cross-Platform Windows）

> 跨平台分析發現的 macOS 專屬 API 移植清單。
> macOS 現有流程完全不動，所有修改均透過 `Platform.isWindows` / if-else 分支新增。

### P0 — 必須修復（否則 Windows 核心功能失效）

- [x] **Windows 貼上功能（`com.zerotype.app/keyboard` → `SendInput`）**
  - 建立 `windows/runner/channel_handler.h / .cpp`
  - 實作 `simulatePaste` → Win32 `SendInput` 模擬 `Ctrl+V`
  - macOS 繼續使用 `CGEvent` 模擬 `Cmd+V`（不動）
- [x] **Windows MethodChannel stubs（overlay / permission / control）**
  - 同一 `channel_handler.cpp` 加入所有 channel 的 Windows handler
  - `permission.checkAccessibility` → 回傳 `true`（Windows `SendInput` 不需授權）
  - `overlay`, `control` → 回傳 `nil` stub（避免 `MissingPluginException`）

### P1 — 應修復（功能受損或 UI 缺失）

- [x] **Settings Controller：Windows 輔助使用權限判斷**
  - `_checkAccessibility()` 加入 `Platform.isWindows` guard，直接回傳 `true`
- [x] **Windows 錄音狀態 Overlay（Flutter Widget）**
  - 實作 `recording_overlay.dart`（原為空 stub）
  - `Platform.isWindows` 時顯示 Flutter Widget overlay（底部置中，狀態色 + 波形 + 取消按鈕）
  - macOS 保持原有 NSPanel 行為（`SizedBox.shrink()`）
  - 在 `main_shell.dart` 以 `Stack` 包裹，疊加於主視窗之上

### P2 — 建議修復（穩定性）

- [ ] **Prompt 檔案路徑**：改用 `path_provider` 取得絕對路徑（目前相對路徑在 Windows 可能讀取失敗）
