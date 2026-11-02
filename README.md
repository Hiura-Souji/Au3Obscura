# Obscura — AutoIt 原始碼保護工具

> 一款繁體中文的 AutoIt（AU3）原始碼保護工具：整合、精簡、混淆你的腳本，讓成品更難被還原與逆向閱讀。

![version](https://img.shields.io/badge/version-1.0.0-007AFF)
![platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![language](https://img.shields.io/badge/AutoIt-v3-5EA4D4)
![license](https://img.shields.io/badge/license-Unlicense-green)

Obscura 是 [格雷資訊 (grayfree.tw)](https://grayfree.tw) 開發的 AutoIt 原始碼保護工具，介面採蘋果風、支援高 DPI。它把 AutoIt 腳本做來源層級（source-level）的整合與混淆，並提供多語言抽字、自我校驗樣板、FileInstall 取代、行號對照等實用輔助。

> ⚠️ **正當用途聲明**
> Obscura 只做**合法的原始碼層級保護**，用於保護你自己（或你有權保護）的 AutoIt 專案，避免成品被輕易還原、閱讀或抄襲。
> 請勿用於製作惡意程式、規避防毒偵測、隱藏可疑行為，或混淆任何你無權處理的程式碼。使用者需自行為其用途負全部責任。

---

<img width="1225" height="927" alt="2026-11-03_034817" src="https://github.com/user-attachments/assets/4b097f45-2809-44e5-a6aa-04306fedf570" />

## ✨ 功能特色

### 程式碼檢測
- 一鍵檢測腳本中的**函式 / 變數 / 字串 / 特殊變數函式**，或全部一起檢測。
- 清單可雙擊以 SciTE 跳到來源行、複製選取列、匯出全部結果。

### 腳本整合
- 依腳本中 `#include` 命令的位置整合，或快速整合（置於第一個 `#include` 位置）。
- 清除註解、空行與行首尾空白、`#Region` / `#EndRegion`。
- 合併由 `" _"` 連接的續行、變數函式分類整理。
- 偵測「當 Dll 內建函式與 UDF 函式同名」並重新命名 UDF。
- 啟發式清除未使用的函式／變數（可選，請務必測試）。
- 整合完成後可做「單行最大字元長度限制」檢測。

### 腳本混淆
- **UDF 函式混淆**（含進階、亂序排列）。
- **變數混淆**（含進階）。
- **內建函式混淆**：以隨機名稱包裝 AutoIt 內建函式（安全白名單）。
- **數字加密**（可選連負號一起隱藏）。
- **字串處理**：不處理／簡單處理／加密處理；加密可讓金鑰隨位置變動。
- **密文處理**：密文置於腳本內部，或置於 RC 資源段。
- 易混淆名稱（`l/I/1/O/0`）、亂數名稱長度設定。
- 名稱對照表輸出（原名→混淆名，便於除錯）。
- 忽略清單（函式／變數，支援正則），會與腳本內 `#Obfuscator_Ignore_*` 合併。
- 一鍵預設：**最強保護** / **標準**。

### 多語言處理
- 從腳本抽出字串產生語言檔，支援多種抽取模式（只有中文、包含中文、由引號包含等）與過濾。
- 可指定語言檔欄位名稱、合併到既有語言檔。

### 自我校驗
- 產生自我校驗樣板，貼進腳本即可使用。
- 以 `WinVerifyTrust` 檢查 EXE 是否已簽章且未被竄改。
- 讀取 EXE 憑證資訊（序號／簽署者）回填欄位。

### 程式碼轉換（取代 FileInstall）
- 將檔案轉成 AU3 釋放用的二進位／文字檔程式碼，或單一二進位變數／常數。
- 可設定每行位元組組數、每個變數行數，支援釋放為隨機檔名（`~TmpXXXX`）。
- 結果以內嵌 **Scintilla** 檢視器顯示（大檔也順），可直接複製或另存為 `.au3`。

### 除錯輔助
- 建立「實際行號 → 內部行號（近似）」對照表，雙擊以 SciTE 開啟該行。
- 可匯出對照表為 CSV。

### 其他
- 介面語言繁體／简体切換；腳本內容繁簡互轉（`<檔名>_SC.au3` / `_TC.au3`）。
- 輸出編碼可選（UTF-8 含/無 BOM、UTF-16 LE、ANSI）。
- 可整合 AU3Check，於整合／混淆後自動檢查輸出。
- 設定一鍵匯出／匯入 `.ini`，方便備份與分享。
- 蘋果風介面、主題色可選、視窗置頂、支援高 DPI。

---

## 📦 系統需求

- Windows
- AutoIt v3（以原始碼執行或自行編譯時需要）
- **`Scintilla.dll`**：程式碼轉換頁的內嵌檢視器需要它。
  - 以原始碼（F5）執行：請確認 `Scintilla.dll` 在 `Obscura.au3` 同資料夾，或可從 AutoIt 的 SciTE 資料夾載入。
  - 編譯成 EXE：程式會以 `FileInstall` 把 `Scintilla.dll` 內嵌進 EXE，首次執行自動釋放到 EXE 同資料夾。
  - 若載不到 DLL，轉換結果會自動改用獨立視窗顯示，不影響使用。

---

## 🚀 使用方式

### 直接執行原始碼
1. 安裝 AutoIt v3。
2. 把 `Obscura.au3`、`Obscura.ico`、`Scintilla.dll`、`_Ini.au3` 放在同一資料夾。
3. 用 SciTE 開啟 `Obscura.au3`，按 **F5** 執行（或直接以 AutoIt 執行）。

### 編譯成執行檔
1. 確認 `Obscura.au3` 同資料夾有 `Scintilla.dll`（`FileInstall` 會從這裡內嵌）。
2. 用 Aut2Exe（或 SciTE 的 Compile）編譯。
3. 編譯後的 EXE 首次執行會自動釋放 `Scintilla.dll`。

> 建議以 AutoIt3Wrapper 編譯，並確認圖示 `Obscura.ico` 一併套用。

---

## 🖥️ 介面導覽

左側為功能分頁：

| 分頁 | 用途 |
| --- | --- |
| 程式碼檢測 | 檢測函式／變數／字串／特殊變數函式 |
| 執行情況 | 顯示整合＋混淆各步驟進度 |
| 腳本整合 | 整合設定與精簡選項 |
| 腳本混淆 | 混淆各項開關與強度預設 |
| 多語言處理 | 抽字產生語言檔 |
| 自我校驗 | 簽章驗證與樣板產生 |
| 除錯輔助 | 行號對照 |
| 程式碼轉換 | 取代 FileInstall |
| 設定 | 語言、繁簡轉換、備份、外觀 |
| 關於 | 版本與連結 |

---

## 📁 專案檔案

| 檔案 | 說明 |
| --- | --- |
| `Obscura.au3` | 主程式 |
| `_Ini.au3` | 設定存檔用的 INI 函數庫 |
| `Obscura.ico` | 程式圖示 |
| `Scintilla.dll` | 轉換頁內嵌檢視器所需（編譯時由 FileInstall 內嵌） |

---

## 📜 授權

本專案以 [Unlicense](https://unlicense.org/) 釋出 — 你可以自由使用、修改、散布，無需標註來源。

---

## ❤️ 支持作者

如果這個工具對你有幫助，歡迎贊助：

- 贊助連結：<https://portaly.cc/grayfree/support>
- 官網：<https://grayfree.tw>

---

## 👤 作者

**格雷資訊 (grayfree.tw)**
GitHub：[@Hiura-Souji](https://github.com/Hiura-Souji)
