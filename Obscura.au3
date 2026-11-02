#Region ;**** 由 AutoIt3Wrapper_GUI 建立的指令 ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=Obscura.ico
#AutoIt3Wrapper_Outfile=Au3Obscura.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Comment=Obscura — AutoIt 原始碼保護工具
#AutoIt3Wrapper_Res_Description=Obscura — AutoIt 原始碼保護工具
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=Obscura
#AutoIt3Wrapper_Res_ProductVersion=2026.11.02
#AutoIt3Wrapper_Res_CompanyName=格雷資訊
#AutoIt3Wrapper_Res_LegalCopyright=grayfree.tw 2026 Unlicense.
#AutoIt3Wrapper_Res_LegalTradeMarks=grayfree.tw
#AutoIt3Wrapper_Res_requestedExecutionLevel=highestAvailable
#AutoIt3Wrapper_Res_CLASS=gWinUI
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** 由 AutoIt3Wrapper_GUI 建立的指令 ****
#Region ;**** 由 AutoIt3Wrapper_GUI 建立的指令 ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=Obscura.ico
#AutoIt3Wrapper_OutFile=Au3Obscura_Apple.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Obscura — AutoIt 原始碼保護工具
#AutoIt3Wrapper_Res_Description=Obscura — AutoIt 原始碼保護工具
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_ProductName=Obscura
#AutoIt3Wrapper_Res_ProductVersion=1.0.0.0
#AutoIt3Wrapper_Res_CompanyName=格雷資訊
#AutoIt3Wrapper_Res_LegalCopyright=grayfree.tw 2026 Unlicense.
#AutoIt3Wrapper_Res_LegalTradeMarks=grayfree.tw
#AutoIt3Wrapper_Res_Language=1028
#AutoIt3Wrapper_Res_requestedExecutionLevel=highestAvailable
#AutoIt3Wrapper_Res_CLASS=gWinUI
#AutoIt3Wrapper_Res_HiDpi=y
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** 由 AutoIt3Wrapper_GUI 建立的指令 ****
#NoTrayIcon ;不顯示系統匣圖示
#RequireAdmin ;請求管理員權限

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <ButtonConstants.au3>
#include <StaticConstants.au3>
#include <ComboConstants.au3>
#include <GuiListView.au3>
#include <GuiListBox.au3> ;;檢測清單改用 owner-draw ListBox(走 WM_DRAWITEM,避開會卡的 ListView 自繪)
#include <GuiTreeView.au3>
#include <WinAPI.au3>
#include <WinAPIFiles.au3>
#include <WinAPITheme.au3> ;;_WinAPI_SetWindowTheme(深色主題)
#include <Array.au3>
#include <GuiComboBox.au3>
#include <GuiMenu.au3> ;;下拉選擇器改用 Apple 按鈕 + 彈出選單(原生 combo 在無邊框自繪視窗顯示異常)
#include <GuiEdit.au3> ;;輸入框提示佔位字(Cue Banner)
#include <Crypt.au3> ;;讀取 EXE 憑證指紋(_Crypt_HashData)
#include "_Ini.au3" ;;設定存檔用的 INI 函數庫(需與本檔同資料夾)
#include <GDIPlus.au3> ;;左側自繪「蘋果風」側欄(圓角選取膠囊)
#include <Misc.au3> ;;_IsPressed(側欄點擊偵測)

; ==================================================================
;  Obscura — AutoIt 原始碼保護工具(繁體中文 / 台灣用語)  版本 1.2
;  格雷資訊 grayfree.tw
; ------------------------------------------------------------------
;  用途:保護你自己撰寫的 AutoIt 原始碼(整合 + 混淆 + 加密)。
;
;  需求:AutoIt v3.3.14 以上(使用了三元運算子)。
;
;  已完整實作:
;    整合(合併 #include)、清除註解/空行/#Region、函式/變數混淆、
;    進階字串內名稱替換、UDF 亂序、字串(簡單/加密)、數字加密、
;    忽略指令(#Obfuscator_Ignore_Funcs / _Variables)、
;    FileInstall 首參保護、程式碼檢測、程式碼轉換(取代 FileInstall)、
;    執行情況表、多語言偵測、除錯行號對照、自校驗樣板。
;
;  受限(介面保留、已標示):
;    密文置於 RC 資源段、數位憑證簽署 —— 需編譯期/
;    簽章配合,本版僅提供提示或樣板。
;  精簡未使用函式/變數為啟發式,預設關閉,開啟後務必測試。
; ==================================================================

Opt("GUIOnEventMode", 0)
Global $g_nameCounter = 0
Global $g_cntStr = 0 ;；本次實際處理（加密／簡單處理）的字串段數，供完成統計使用
Global $g_lnkBrand = 0, $g_lnkGit = 0, $g_lnkSpon = 0 ;；關於頁可點擊連結控制項 id
Global $g_nameLen = 6 ;;混淆後識別字的亂數段長度(執行時由介面帶入)
Global $g_inNameLen  ;;亂數名稱長度輸入欄

; --- 全域字型 ---
Global $fontsize = 12, $font_xing = 400, $font_var = Default, $font_quality = 5, $font_name = 'Microsoft JhengHei'

; --- 分頁常數 ---
Global Enum $PG_MAIN, $PG_DETECT, $PG_EXEC, $PG_PARAM, $PG_INTEG, $PG_OBFUS, _
		$PG_ML, $PG_SELF, $PG_DEBUG, $PG_CONV, $PG_LANG, $PG_ABOUT, $PG_REG, $PG_COUNT
Global $g_pg[$PG_COUNT]


; --- 主要狀態 ---
Global $g_script = ""
Global $hMain
Global $g_cfg = @ScriptDir & "\Obscura.ini" ;;設定存檔路徑
Global $g_cfgReady = False ;;載入完成前不觸發存檔
Global $g_uiSimp = False ;;介面語言是否為简体(啟動時依設定決定)
Global $g_hBrushDark = 0 ;;深色主題背景筆刷(供 WM_CTLCOLOR 使用)
Global $g_log = "", $g_logOn = False ;;處理日誌(勾選「輸出日誌」時啟用)
Global $g_stepT0 = 0, $g_stepPrev = 0 ;;每步驟耗時紀錄
Global $g_btnCfgExport, $g_btnCfgImport ;;設定匯出/匯入鈕
Global $g_batch = False  ;;批次處理中(抑制逐檔完成對話框)
Global $g_bLastRunOk = False ; 每次處理的真正輸出結果，供批次計數
Global $g_sLastOutputError = "" ; 最近一次安全寫檔 / 檢查失敗原因
Global $g_sLastAu3CheckOutput = "" ; AU3Check 診斷
Global $g_iLastAu3CheckExit = -1
Global $g_doBatch = False ;;主迴圈待處理的批次旗標
Global $g_batchFiles[0] ;;待批次處理的檔案清單

; --- 控制項 id ---
Global $g_inMain, $g_chkTop
Global $g_lvDetect, $g_inLocate
Global $g_detData[0][3] ;;檢測清單虛擬資料(顯示索引|內容|來源行號)
Global $g_lvExec
; v18.3.7：Win32 通知回呼只讀取 HWND 快取，不呼叫 GUICtrlGetHandle。
; 子視窗建立完成即設定；頁面切換不會重新建立 ListView HWND。
Global $g_hLvDet = 0, $g_hLvML = 0, $g_hLvDbg = 0, $g_hLvExec = 0
Global $g_iHeaderCheckPage = -1
Global $g_inSciTE, $g_inStd, $g_chkLog, $g_cboEnc
Global $g_cboInteg, $g_iCmt, $g_iBlank, $g_iRegion, $g_iDelFunc, $g_iDelVar, _
		$g_iJoin, $g_iDllRen, $g_iSort, $g_iMaxLen
Global $g_oUseInteg, $g_oOutInteg, $g_oUdf, $g_oUdfAdv, $g_oUdfShuf, _
		$g_oVar, $g_oVarAdv, $g_oNum, $g_rStrNone, $g_rStrSimple, $g_rStrEnc, $g_oStrAdv, $g_oConfName, $g_oNegNum, $g_oNameMap, $g_rCipherIn, $g_rCipherRc
Global $g_rcMode = False ;;密文置於 RC 資源段模式(處理時由選項帶入)
Global $g_blob = "" ;;RC 模式:累積密文 blob
Global $g_negNum = False ;;數字加密:連負號一起隱藏(處理時由選項帶入)
Global $g_confName = False ;;易混淆名稱(l/I/1/O/0 相近字元):處理時由選項帶入
Global $g_strAdvMode = False ;;進階字串/數字加密:位置相依滾動金鑰(處理時由選項帶入)
Global $g_inConvFile, $g_rConvBin, $g_rConvTxt, $g_rConvVar, $g_chkTmpName, _
		$g_inBytesPerLine, $g_inLinesPerVar
Global $g_sConvCode = "" ;;最近一次轉換結果
Global $g_hSci = 0, $g_hSciDll = 0 ;;轉換輸出改用內嵌 Scintilla 控件(SciTE 編輯器核心);載不到 DLL 時退回獨立視窗
Global $g_oBuiltinCase = 0 ;;內建函式隨機名稱包裝（混淆設定頁，位於整合輸出右側）
Global $g_inIgnFunc, $g_inIgnVar ;;介面上的忽略清單輸入欄
Global $g_lvML, $g_inMLField, $g_cboMLMode, $g_cboMLFilter, $g_chkMLMerge, $g_inMLLocate
Global $g_mlData[0][3] ;;多語言清單虛擬資料(顯示索引|字串|來源行號)
Global $g_inCertIssuer, $g_inCertSigner, $g_inCertSerial
Global $g_inDbgFile, $g_lvDbg
Global $g_dbgData[0][3] ;;除錯清單的虛擬資料來源(實際行號|內部行號|內容)
Global $g_iPendingSidePage = -1 ;;側欄點擊先排入主迴圈，避免在滑鼠狀態處理中切換子視窗
Global $g_cboLang
Global $g_btnLangDrop = 0, $g_btnAccentDrop = 0 ;;語言/主題色「下拉」改用 Apple 按鈕+彈出選單顯示(combo 隱藏只存值)
Global $g_btnEncDrop = 0, $g_btnIntegDrop = 0, $g_btnMLModeDrop = 0, $g_btnMLFilterDrop = 0 ;;其餘下拉框同樣改按鈕+選單
Global $g_aLogoBmp[8], $g_iLogoBmp = 0 ;;_LogoPic 產生的 HBITMAP,離開時統一釋放

; --- 按鈕群組(先宣告,避免執行順序問題)---
Global $g_btn[7]
Global $g_detBtn[6] ;;0=輸出 1=函式 2=變數 3=字串 4=特殊 5=全部
Global $g_mlBtn[3] ;;0=檢測 1=執行 2=還原
Global $g_dbgBtn[4] ;;0=選檔 1=檢測 2=匯出對照表 3=開啟診斷 LOG
Global $g_convBtn[7] ;;0=選檔 1=載入 2=清空 3=轉換 4=複製 5=另存 6=開啟結果視窗
Global $g_selBtn, $g_selBtnChk, $g_selBtnRead ;;自我校驗頁按鈕
Global $g_btnPreMax, $g_btnPreStd ;;混淆頁:強度一鍵預設(最強/標準)
Global $g_btnBrowseSciTE, $g_btnBrowseStd ;;參數設定頁的「…」瀏覽鈕
Global $g_inAu3Check, $g_oAutoCheck, $g_btnBrowseAu3Check ;;輸出後自動 AU3Check
Global $g_btnTC2SC, $g_btnSC2TC ;;設定頁:繁↔简 腳本轉換
Global $g_mnuDetCopy, $g_mnuDetExport, $g_mnuDetOpen ;;檢測清單右鍵選單
Global $g_mnuMLCopy, $g_mnuMLRestore, $g_mnuMLOpen ;;多語言清單右鍵選單
Global $g_status        ;;底部狀態列
Global $g_lblTitle, $g_btnMin, $g_btnClose, $g_divTitle ;;自訂標題列(無邊框)
Global $g_tbarStrips[17] ;;標題列漸層細帶(純 GDI 淡色垂直漸層)
Global $g_iTitleMouseDown = 0 ;;記錄滑鼠按下時命中的標題列按鈕
Global $g_bTitleWasDown = False ;;追蹤滑鼠由按下到放開的完整過程
Global $g_titleHover = 0 ;;目前游標所在的標題按鈕(0=無 1=最小化 2=關閉)
Global $g_titleVisual = -1 ;;標題按鈕目前視覺狀態(避免每圈重畫閃爍)
Global Const $OB_TITLE_BG = 0xF1F2F5 ; 單一實色避免標題列切焦時拼接縫與反覆重繪
Global Const $OB_VER = "1.0.0" ;;版本號集中於此;執行期字串一律引用(Res_Fileversion/ProductVersion 為編譯指示只能用字面值,改版時一併同步)
Global $g_bSideNeedsRepaint = False ; WM_PAINT 預設繪製結束後，再由主迴圈補畫側欄
Global $g_winActive = True ;;主視窗是否為作用中(焦點)狀態
Global $g_stop = False  ;;中止旗標
Global $g_stopBtn = 0   ;;目前作為「中止」的按鈕 id
Global $g_execActive = 0 ;;執行情況目前顯示箭頭的列(1-13)

; --- 自繪側欄(蘋果風,取代原生 TreeView) ---
Global $g_sX, $g_sY, $g_sW, $g_sH, $g_rowH, $g_topPad, $g_pillL, $g_pillR, $g_rad, $g_sIndent
Global $g_srows[12][5]   ;;列資料:text|level|isParent|expanded|pageConst
Global $g_sVis[0]        ;;目前可見列(索引清單)
Global $g_sSelRow = 2, $g_sHover = -1, $g_sWasDown = False, $g_sPressRow = -1
Global $g_sMemDC = 0, $g_sMemBmp = 0, $g_sGfx = 0
Global $g_sFam = 0, $g_sFont = 0, $g_sSF = 0
Global $g_sBrSel = 0, $g_sBrHov = 0, $g_sBrSelTxt = 0, $g_sBrTxt = 0, $g_sBrTxt2 = 0, $g_sBrChev = 0
Global $g_accent = 0xFF007AFF ;;選取膠囊色(ARGB),由「主題色」設定帶入
Global $g_cboAccent          ;;主題色下拉

; --- 蘋果風按鈕(擁有者自繪)資源 ---
Global $g_btnFam = 0, $g_btnFont = 0, $g_btnSF = 0
Global Const $tagDRAWITEMSTRUCT_APPLE = "uint CtlType;uint CtlID;uint itemID;uint itemAction;uint itemState;hwnd hItem;handle hDC;long rL;long rT;long rR;long rB;ulong_ptr itemData"

; --- 蘋果風核取方塊/單選鈕(子類別化重繪;保留原生狀態) ---
Global $g_appleChk = True ;;若此功能異常,改為 False 即退回系統原生核取方塊
Global $g_hCbCb = 0, $g_pCbProc = 0 ;;子類別回呼(需全域保存,否則會被釋放)
Global $g_cbFont = 0, $g_cbSF = 0

; --- 清單選取列追蹤(供自繪上色;避免在繪製中發訊息造成當掉) ---
Global $g_selDet = -1, $g_selML = -1, $g_selDbg = -1
; v17: 已實測正確的 LVM_GETITEMSTATE/LVIS_SELECTED 反白判斷。
; 只在主事件迴圈查詢真正的選取狀態；WM_NOTIFY 繪製回呼只讀取快取，
; 避免在 OWNERDATA 的 NM_CUSTOMDRAW 回呼中 SendMessage 造成更多巢狀通知。
Global $g_bLvSelectionDirty = True, $g_tLvSelectionPoll = 0
Global Const $OB_LVM_GETNEXTITEM = 0x100C, $OB_LVM_GETITEMSTATE = 0x102C
Global Const $OB_LVNI_SELECTED = 0x0002, $OB_LVIS_SELECTED = 0x0002
Global Const $OB_CDIS_SELECTED = 0x0001, $OB_CDIS_FOCUS = 0x0010
Global Const $OB_CDRF_NEWFONT = 0x0002
Global $g_bListMenuDirty = True, $g_bDebugPageGuard = False
; 防止 WM_NOTIFY 自訂繪製的巢狀進入；切頁時避免重複釋放/重建繪製資源。
Global $g_bListCustomDrawBusy = False
Global $g_bRunBusy = False ; 防止 GUIGetMsg/WM_COMMAND 備援重複啟動處理流程
; v18.2: BN_CLICKED 雙事件防誤判。第一筆啟動點擊的 GUIGetMsg 回音不可當作「中止」。
; 只有混淆開始之後 *新增* 的 BN_CLICKED 才是使用者按下中止。
Global $g_iRunStopClickSerial = 0
Global $g_iRunIgnoredLaunchEcho = 0
Global $g_iActivePage = -1
Global $g_bDebugTrace = False ;;正式用:關閉診斷記錄(原 True 時每迴圈/每通知開檔寫硬碟,捲動會被 I/O 卡死)
Global $g_sDebugTracePath = @TempDir & "\Obscura_DebugCrash.log"
Global $g_bDiagLogBusy = False ;;記錄時防止意外重入
Global $g_iDiagNotifyCount = 0 ;;只記錄前 100 次清單通知，避免大量繪製造成 LOG 暴增
Global $g_iDiagDrawCount = 0 ;;自繪按鈕只記錄除錯分頁前 15 次
Global $g_iDiagLoopRemain = 0 ;;切入除錯頁後追蹤前 12 次主迴圈
Global $g_iDiagSerial = 0
Global $g_bDiagPageActive = False
; v13: 4 個清單的虛擬文字由程式保有，避免直接寫入 Windows 提供的指標。
; 必須以全域持有結構，確保通知處理結束後指標不會立刻失效。
Global $g_lvTextDetW = 0, $g_lvTextDetA = 0
Global $g_lvTextMLW = 0, $g_lvTextMLA = 0
Global $g_lvTextDbgW = 0, $g_lvTextDbgA = 0
; v16 方案 A：三組虛擬 ListView 獨立的固定多槽文字緩衝區。
; 預先配置；WM_NOTIFY 裡不建立/釋放 DllStruct、不記錄磁碟 LOG。
Global $g_aLvTextW[3][64], $g_aLvTextA[3][64]
Global $g_aLvCursorW[3], $g_aLvCursorA[3]
Global $g_bLvTextBuffersReady = False
Global $g_bLvSafeDraw = False ;;舊「安全繪製模式」旗標,清單全改 ListBox 後固定為 False,僅供 _OnNotify 繪製守衛相容
Global $g_iLvDrawDepth = 0, $g_iLvTextRequests = 0, $g_iLvNestedText = 0
Global $g_iLvDrawRequests = 0, $g_iLvDroppedDraw = 0
Global $g_iLvPendingDouble = 0
Global $g_tLvDiagFlush = 0
Global $g_bListPopulating = False
; v14: 頁面切換使用單一交易，避免同時隱藏/顯示子視窗期間重入。
Global $g_bPageSwitchBusy = False
Global $g_iPageSwitchSerial = 0
Global $g_iHottrackTotal = 0
Global $g_iDiagCustomDrawLogs = 0
; v15: Apple OwnerDraw 按鈕 Win32 BN_CLICKED → 主迴圈事件備援。
; 子 GUI 由 ShowWindow 顯示時，繪製與 AutoIt GUIGetMsg 事件接收可能不同步。
; 在 WM_COMMAND 回呼只排隊，實際功能仍由原本的 Switch $msg 執行。
Global $g_aBtnBridge[64][2] ;; [i][0]=HWND, [i][1]=AutoIt Control ID
Global $g_iBtnBridgeCount = 0
Global $g_aBtnPending[32][2] ;; [i][0]=control ID, [i][1]=WM_COMMAND serial
Global $g_iBtnPendingCount = 0
Global $g_iBtnCommandSerial = 0
Global $g_iBtnLastFallbackId = 0
Global $g_iBtnLastFallbackSerial = 0
Global $g_tBtnLastFallback = 0


Global $g_scale = _DpiInit() ;;DPI 縮放倍率(96dpi=1.0)
_DiagStart() ;;盡早建立獨立 LOG；即使切頁後立即閃退也保留前面的線索
OnAutoItExitRegister("_DiagOnExit")
_SciEnsureDll() ;;編譯版:若同資料夾沒有 Scintilla.dll,從 EXE 內釋放出來(FileInstall 在 _SciEnsureDll 內)
; 退回卡片前:強制亮色、不載入主題旗標
_BuildGui()
_Loop()

; ==================================================================
;  建立主視窗
; ==================================================================
Func _BuildGui()
	_DebugTrace("BUILDGUI begin")
	_AppleInit() ;;啟動 GDI+ 與按鈕字型,並註冊 WM_DRAWITEM(需在建立/顯示控制項前)
	; 先讀取上次關閉時的視窗座標,於建立時直接帶入,避免「先置中顯示→再 WinMove」造成的跳動
	Local $wx = -1, $wy = -1
	If FileExists($g_cfg) Then
		Local $rx = Int(_IniRead($g_cfg, "Window", "X", -99999, 128))
		Local $ry = Int(_IniRead($g_cfg, "Window", "Y", -99999, 128))
		If $rx <> -99999 And $ry <> -99999 Then
			If $rx < 0 Then $rx = 0
			If $ry < 0 Then $ry = 0
			If $rx > @DesktopWidth - 100 Then $rx = @DesktopWidth - 100
			If $ry > @DesktopHeight - 100 Then $ry = @DesktopHeight - 100
			$wx = $rx
			$wy = $ry
		EndIf
	EndIf
	$hMain = GUICreate("Obscura — AutoIt 原始碼保護  v" & $OB_VER, S(980), S(742), $wx, $wy, BitOR($WS_POPUP, $WS_MINIMIZEBOX), BitOR($WS_EX_TOPMOST, $WS_EX_ACCEPTFILES, $WS_EX_APPWINDOW))
	_Font($hMain)
	GUISetBkColor(0xF5F5F7, $hMain) ;;亮色(Apple 風)底
	; 刻意不呼叫 WinSetTrans：即使透明度為 255，仍可能讓 WS_EX_LAYERED 影響 ListView/標題列重繪。

	; ---- 自訂標題列(無邊框,純 GDI 淡色垂直漸層,靜態不殘影)----
	; 以多條細橫帶堆疊模擬漸層;拖曳用 $GUI_WS_EX_PARENTDRAG(控制項屬性,免攔 PRIMARYDOWN),
	; 按鈕由 _TitleButtonsPoll 以座標命中(按鈕不加 PARENTDRAG,才能正常點擊)。
	Local $iH = S(34), $iN = 17, $iy0, $iy1, $i
	For $i = 0 To $iN - 1
		$iy0 = Int($i * $iH / $iN)
		$iy1 = Int(($i + 1) * $iH / $iN)
		; 漸層+可拖曳只到 x896(按鈕之前);PARENTDRAG 若蓋到按鈕會讓按鈕變成拖曳區而點不到
		$g_tbarStrips[$i] = GUICtrlCreateLabel("", S(0), $iy0, S(896), $iy1 - $iy0 + 1, -1, $GUI_WS_EX_PARENTDRAG)
		GUICtrlSetBkColor($g_tbarStrips[$i], _TitleGrad($i / ($iN - 1), True))
	Next
	_LogoPic(S(12), S(9), S(18), S(18), 0xFFF1F2F5) ;;標題列左側小圖示(GDI+ 載入,底色同標題列)
	$g_lblTitle = GUICtrlCreateLabel("Obscura  ·  AutoIt 原始碼保護工具   v" & $OB_VER, S(38), S(5), S(748), S(26), $SS_NOTIFY, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetFont($g_lblTitle, 11, 700, 0, "Microsoft JhengHei UI", 5) ; 清楚的深色粗體，避免 DPI 字型頂部遭裁切
	GUICtrlSetColor($g_lblTitle, 0x15151B)
	GUICtrlSetBkColor($g_lblTitle, $OB_TITLE_BG) ; 和整條標題列完全同色，不產生拼接線
	; − / ✕ 由 _TitleButtonsPoll 統一判斷「按下→放開」，不依賴標籤通知。
	; 不在按鈕區加 PARENTDRAG，避免滑鼠點擊被視為拖曳視窗。
	$g_btnMin = GUICtrlCreateLabel(ChrW(0x2212), S(902), S(5), S(34), S(24), BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetBkColor($g_btnMin, $OB_TITLE_BG)
	GUICtrlSetColor($g_btnMin, 0x1D1D1F)
	GUICtrlSetFont($g_btnMin, 13, 400, 0, $font_name, $font_quality)
	$g_btnClose = GUICtrlCreateLabel(ChrW(0x2715), S(940), S(5), S(34), S(24), BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetBkColor($g_btnClose, $OB_TITLE_BG)
	GUICtrlSetColor($g_btnClose, 0x1D1D1F)
	GUICtrlSetFont($g_btnClose, 12, 400, 0, $font_name, $font_quality)
	$g_divTitle = GUICtrlCreateLabel("", S(0), S(34), S(980), S(1))
	GUICtrlSetBkColor($g_divTitle, 0xD6D6DB)

	_LogoPic(S(10), S(44), S(44), S(44), 0xFFF5F5F7) ;;程式自身圖示(GDI+ 載入,底色同主視窗)
	$g_inMain = GUICtrlCreateInput("將要整合或混淆的腳本拖放至此處（可一次拖入多個檔案批次混淆）", S(64), S(46), S(794), S(40), $ES_READONLY)
	GUICtrlSetState($g_inMain, $GUI_DROPACCEPTED)
	GUICtrlSetFont($g_inMain, 12, $font_xing, $font_var, $font_name, $font_quality)
	Local $btnPick = _AppleBtn("...", S(866), S(46), S(104), S(40))

	Local $tbDetect = _AppleBtn("程式碼檢測", S(8), S(94), S(236), S(38))
	Local $tbInteg = _AppleBtn("腳本整合", S(250), S(94), S(236), S(38))
	Local $tbObf = _AppleBtn("執行混淆", S(492), S(94), S(236), S(38))
	Local $tbExec = _AppleBtn("執行情況", S(734), S(94), S(238), S(38))
	GUICtrlSetFont($tbDetect, 12, 700, 0, $font_name, $font_quality)
	GUICtrlSetFont($tbInteg, 12, 700, 0, $font_name, $font_quality)
	GUICtrlSetFont($tbObf, 12, 700, 0, $font_name, $font_quality)
	GUICtrlSetFont($tbExec, 12, 700, 0, $font_name, $font_quality)
	; macOS 風:工具列下方細分隔線
	Local $divTop = GUICtrlCreateLabel("", S(0), S(137), S(980), S(1))
	GUICtrlSetBkColor($divTop, 0xD6D6DB)

	; 左側導覽改為 GDI+ 自繪「蘋果風」側欄(圓角選取膠囊/hover/可折疊箭頭);
	; 內容與點擊由 _SideInit 建立、_PollTree 輪詢,換頁仍沿用 _ShowPage。
	Local $divSide = GUICtrlCreateLabel("", S(196), S(142), S(1), S(560)) ;;macOS 風:側欄與內容間的直向分隔線
	GUICtrlSetBkColor($divSide, 0xD6D6DB)

	Local $divBottom = GUICtrlCreateLabel("", S(0), S(702), S(980), S(1)) ;;macOS 風:底部細分隔線
	GUICtrlSetBkColor($divBottom, 0xD6D6DB)
	$g_status = GUICtrlCreateLabel("就緒。（v" & $OB_VER & "）", S(10), S(714), S(738), S(22))
	GUICtrlSetColor($g_status, 0x007AFF)

	Local $btnOpenDir = _AppleBtn("開啟資料夾", S(758), S(708), S(104), S(30))
	Local $btnOpenScr = _AppleBtn("開啟腳本", S(868), S(708), S(104), S(30))

	_DebugTrace("BUILDGUI before BuildPages")
	_BuildPages()
	_DebugTrace("BUILDGUI after BuildPages")
	_LvTextBuffersInit() ;;必須在顯示任何虛擬清單前完成配置
	_ShowPage($PG_EXEC) ;;開啟時首頁為執行情況(經典)
	GUISetState(@SW_SHOW, $hMain)
	; 亮色主題:不使用整窗半透明(會連文字一起變淡),保持清爽白底
	_SideInit() ;;建立 GDI+ 自繪側欄(預設選取:執行情況)
	_AllowDrop() ;;#RequireAdmin 下放行拖放訊息
	GUIRegisterMsg(0x0233, "_OnDropFiles") ;;接收拖到主視窗任一區域的檔案(含空白處)
	DllCall("shell32.dll", "none", "DragAcceptFiles", "hwnd", $hMain, "bool", True)
	; 不在 WM_CONTEXTMENU 回呼中改變選單狀態，避免首開選單時的重入與狀態延遲。
	$g_hLvDet = GUICtrlGetHandle($g_lvDetect)
	$g_hLvML = GUICtrlGetHandle($g_lvML)
	$g_hLvDbg = GUICtrlGetHandle($g_lvDbg)
	$g_hLvExec = GUICtrlGetHandle($g_lvExec)
	GUIRegisterMsg($WM_NOTIFY, "_OnNotify") ;;雙擊清單列 → 以 SciTE 跳到來源行
	GUIRegisterMsg($WM_COMMAND, "_OnAppleCommand") ;;v15: 保留 AutoIt 原生 WM_COMMAND 處理，僅備援擷取 Apple 按鈕點擊
	GUIRegisterMsg(0x0006, "_OnActivate") ;;WM_ACTIVATE:標題列隨焦點變色
	GUIRegisterMsg($WM_PAINT, "_OnPaintSide") ;;側欄重繪(視窗被遮擋/還原時貼回緩衝)
	; 亮色(Apple 風):不覆寫控制項前景/背景,沿用系統預設黑字淺底

	$g_btn[0] = $btnPick
	$g_btn[1] = $tbDetect
	$g_btn[2] = $tbInteg
	$g_btn[3] = $tbObf
	$g_btn[4] = $tbExec
	$g_btn[5] = $btnOpenDir
	$g_btn[6] = $btnOpenScr

	_BeautifyLv($g_lvDetect) ;;清單美化
	_BeautifyLv($g_lvML)
	_BeautifyLv($g_lvExec)
	_BeautifyLv($g_lvDbg)

	_BackupConfigSnapshot() ;;啟動前保留上一份完整設定，避免本次設定變更無法還原
	_CfgLoad() ;;載入先前存檔的設定
	$g_uiSimp = (GUICtrlRead($g_cboLang) = "简体中文") ;;介面語言
	If $g_uiSimp Then _LocalizeUI() ;;一次性把已建立的繁體介面轉為简体
	_UpdateToolbar() ;;尚未載入腳本 → 功能鈕先停用
	_LightControls() ;;亮色(Apple 風):淺色標題列,控制項沿用系統預設
	_SyncDeps() ;;依主選項勾選狀態,將未啟用的子選項反灰
	_SideSetAccent() ;;套用已存檔的主題色到側欄選取膠囊
	_DropSync() ;;語言/主題色下拉按鈕文字同步成載入後的值
	_AppleHookChecks() ;;核取方塊/單選鈕掛上蘋果風重繪
	_ButtonBridgeInit() ;;v15: 全部分頁 Apple 按鈕註冊事件備援（不改變外觀）
	_LvUpdMenus() ;;起始:無選取 → 右鍵「複製/開啟」先停用
	_DebugTrace("BUILDGUI end")
EndFunc   ;==>_BuildGui

; 亮色(Apple 風):確保標題列為淺色(關閉 immersive dark),控制項維持系統預設淺色外觀
Func _LightControls()
	Local $hUx = _WinAPI_LoadLibrary("uxtheme.dll")
	If $hUx Then
		Local $pApp = _WinAPI_GetProcAddress($hUx, 135) ;;SetPreferredAppMode
		If $pApp Then DllCallAddress("int", $pApp, "int", 3) ;;3 = ForceLight
		Local $pFlush = _WinAPI_GetProcAddress($hUx, 136)
		If $pFlush Then DllCallAddress("none", $pFlush)
	EndIf
	Local $tLight = DllStructCreate("int")
	DllStructSetData($tLight, 1, 0) ;;DWMWA_USE_IMMERSIVE_DARK_MODE = 0(淺色標題列)
	DllCall("dwmapi.dll", "int", "DwmSetWindowAttribute", "hwnd", $hMain, "dword", 20, "ptr", DllStructGetPtr($tLight), "dword", 4)
EndFunc   ;==>_LightControls

; 執行期介面文字轉換:简体模式時把繁體文字轉简体(腳本內容不走此函式)
Func TR($s)
	Return $g_uiSimp ? _CnConvert($s, True) : $s
EndFunc   ;==>TR

; 啟動時把「已建立的靜態介面」整批繁→简(控制項、樹狀、下拉、清單標題、執行情況項目、標題列)
Func _LocalizeUI()
	Local $aChild = _WinAPI_EnumChildWindows($hMain)
	If IsArray($aChild) Then
		Local $i
		For $i = 1 To $aChild[0][0]
			Local $cls = $aChild[$i][1]
			If StringInStr($cls, "Combo") Or StringInStr($cls, "SysListView") Or StringInStr($cls, "SysTreeView") Then ContinueLoop
			Local $t = _WinAPI_GetWindowText($aChild[$i][0])
			If $t <> "" And StringRegExp($t, "[\x{4e00}-\x{9fff}]") Then _WinAPI_SetWindowText($aChild[$i][0], _CnConvert($t, True))
		Next
	EndIf
	_LocalizeTree()
	; 註:下拉清單(整合模式/編碼/多語言模式/過濾)的「值」會被程式邏輯比對,
	;     若轉简体會導致比對失敗,故刻意保留繁體,不在此轉換。
	_LocalizeLvHeaders($g_lvDetect)
	_LocalizeLvHeaders($g_lvML)
	_LocalizeLvHeaders($g_lvExec)
	_LocalizeLvHeaders($g_lvDbg)
	_LocalizeExecItems()
	WinSetTitle($hMain, "", _CnConvert(WinGetTitle($hMain), True))
	GUICtrlSetData($g_status, _CnConvert(GUICtrlRead($g_status), True))
EndFunc   ;==>_LocalizeUI

Func _LocalizeTree()
	; 自繪側欄:把列文字轉為简体後重繪
	For $i = 0 To UBound($g_srows) - 1
		$g_srows[$i][0] = _CnConvert($g_srows[$i][0], True)
	Next
	If $g_sMemDC Then
		_SideRender()
		_SideBlit()
	EndIf
EndFunc   ;==>_LocalizeTree

Func _LocalizeLvHeaders($lv)
	Local $n = _GUICtrlListView_GetColumnCount($lv), $i
	For $i = 0 To $n - 1
		Local $col = _GUICtrlListView_GetColumn($lv, $i)
		If IsArray($col) Then _GUICtrlListView_SetColumn($lv, $i, _CnConvert($col[2], True)) ;;[2]=欄位標題文字
	Next
EndFunc   ;==>_LocalizeLvHeaders

Func _LocalizeExecItems()
	Local $n = _GUICtrlListView_GetItemCount($g_lvExec), $i
	For $i = 0 To $n - 1
		_GUICtrlListView_SetItemText($g_lvExec, $i, _CnConvert(_GUICtrlListView_GetItemText($g_lvExec, $i, 1), True), 1)
	Next
EndFunc   ;==>_LocalizeExecItems

; 以主視窗為擁有者顯示訊息框,確保在置頂主視窗之上(不被遮住)
; 將 MsgBox 旗標對應到 Apple 風自訂對話框,維持原本回傳碼(1=確定,6=是,7=否,2=取消)。
Func _Msg($flag, $title, $text)
	Local $icon
	Switch BitAND($flag, 0x70)
		Case 16
			$icon = "x" ;；錯誤(紅)
		Case 32
			$icon = "?" ;；詢問(藍)
		Case 48
			$icon = "!" ;；警告(橙)
		Case Else
			$icon = "i" ;；資訊(藍)
	EndSwitch
	Local $bt = BitAND($flag, 0x0F)
	If $bt = 4 Then ;；是 / 否
		Local $b[2] = ["否", "是"]
		Return (_AppleDlg($title, $text, $icon, $b, 2) = 2) ? 6 : 7
	ElseIf $bt = 1 Then ;；確定 / 取消
		Local $b[2] = ["取消", "確定"]
		Return (_AppleDlg($title, $text, $icon, $b, 2) = 2) ? 1 : 2
	Else ;；僅確定
		Local $b[1] = ["確定"]
		_AppleDlg($title, $text, $icon, $b, 1)
		Return 1
	EndIf
EndFunc   ;==>_Msg

; 三按鈕自訂對話框(按鈕標籤清楚)。回傳 1/2/3,關閉或 Esc 回傳 0。首顆為主要動作(藍)。
Func _Choose3($title, $text, $b1, $b2, $b3)
	Local $b[3] = [$b1, $b2, $b3]
	Return _AppleDlg($title, $text, "", $b, 1)
EndFunc   ;==>_Choose3

; Apple 風自訂對話框引擎:無邊框白卡片、彩色圓角圖示、label 式按鈕(可完全控色,與主 UI 成套)。
;  $icon : "i"資訊 / "!"警告 / "x"錯誤 / "?"詢問 / "" 無
;  $btns : 按鈕文字陣列(由左至右);$pri = 主要(藍底)按鈕序號(1 起,0=最後一顆),Enter 觸發它
;  回傳 : 被按的按鈕序號 1..N;關閉 / Esc 回傳 0
Func _AppleDlg($title, $text, $icon, ByRef $btns, $pri = 0)
	Local $n = UBound($btns)
	If $n < 1 Then Return 0
	If $pri < 1 Or $pri > $n Then $pri = $n
	Local $tt = TR($text), $i

	; 估算文字顯示行數(硬換行 + 約略自動折行)
	Local $arr = StringSplit(StringReplace($tt, @CRLF, @LF), @LF, 1)
	Local $lines = 0
	For $i = 1 To $arr[0]
		Local $w = Ceiling(StringLen($arr[$i]) / 24)
		$lines += ($w < 1 ? 1 : $w)
	Next
	If $lines < 1 Then $lines = 1
	If $lines > 20 Then $lines = 20

	; 版面(邏輯座標,輸出時以 S() 縮放)
	Local $dw = 460, $pad = 24, $lineH = 20
	Local $hasIcon = ($icon <> "")
	Local $tx = $hasIcon ? 84 : $pad
	Local $ty = 52, $th = $lines * $lineH
	Local $cBot = $hasIcon ? (($ty + $th) > 96 ? ($ty + $th) : 96) : ($ty + $th)
	Local $btnH = 34, $btnY = $cBot + 20
	Local $dh = $btnY + $btnH + 20

	Local $dlg = GUICreate(TR($title), S($dw), S($dh), -1, -1, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST, $hMain)
	GUISetFont($fontsize, $font_xing, $font_var, $font_name)
	GUISetBkColor(0xFFFFFF, $dlg)

	; 標題
	Local $lt = GUICtrlCreateLabel(TR($title), S($pad), S(14), S($dw - $pad * 2), S(24))
	GUICtrlSetFont($lt, 12, 700, 0, $font_name, $font_quality)
	GUICtrlSetColor($lt, 0x1D1D1F)

	; 彩色圖示(填色方塊 + 白色字元,跨字型可靠)
	If $hasIcon Then
		Local $glyph = "i", $bg = 0x007AFF
		Switch $icon
			Case "x"
				$glyph = Chr(0xD7) ;；×
				$bg = 0xFF3B30
			Case "!"
				$glyph = "!"
				$bg = 0xFF9F0A
			Case "?"
				$glyph = "?"
				$bg = 0x007AFF
			Case Else
				$glyph = "i"
				$bg = 0x007AFF
		EndSwitch
		Local $li = GUICtrlCreateLabel($glyph, S($pad), S($ty - 2), S(44), S(44), BitOR($SS_CENTER, $SS_CENTERIMAGE))
		GUICtrlSetFont($li, 18, 700, 0, $font_name, $font_quality) ;；用字型真有的 700 粗細,避免 800 合成粗體把半形符號斜切
		GUICtrlSetBkColor($li, $bg)
		GUICtrlSetColor($li, 0xFFFFFF)
	EndIf

	; 內文
	Local $lm = GUICtrlCreateLabel($tt, S($tx), S($ty), S($dw - $tx - $pad), S($th))
	GUICtrlSetColor($lm, 0x3A3A3C)

	; 按鈕(label 式,右對齊,主要動作藍底白字;不加 $SS_NOTIFY,改以滑鼠放開邊緣觸發)
	Local $ids[$n], $bw[$n], $bgNorm[$n], $bgDown[$n]
	For $i = 0 To $n - 1
		Local $cand = 28 + StringLen(TR($btns[$i])) * 16
		$bw[$i] = ($cand < 96) ? 96 : $cand
	Next
	Local $cur = $dw - $pad
	For $i = $n - 1 To 0 Step -1
		Local $bx = $cur - $bw[$i]
		$ids[$i] = GUICtrlCreateLabel(TR($btns[$i]), S($bx), S($btnY), S($bw[$i]), S($btnH), BitOR($SS_CENTER, $SS_CENTERIMAGE))
		GUICtrlSetFont($ids[$i], 11, 600, 0, $font_name, $font_quality)
		If ($i + 1) = $pri Then
			$bgNorm[$i] = 0x007AFF
			$bgDown[$i] = 0x0062CC ;；按下變深藍
			GUICtrlSetColor($ids[$i], 0xFFFFFF)
		Else
			$bgNorm[$i] = 0xF0F0F2
			$bgDown[$i] = 0xDADADE ;；按下變深灰
			GUICtrlSetColor($ids[$i], 0x1D1D1F)
		EndIf
		GUICtrlSetBkColor($ids[$i], $bgNorm[$i])
		$cur = $bx - 10
	Next

	GUISetState(@SW_DISABLE, $hMain) ;;模態:暫停主視窗
	GUISetState(@SW_SHOW, $dlg)
	Local $r = 0, $armed = False ;；鍵需先放開一次才接受,避免觸發當下 Enter/Esc 仍按著就瞬關
	Local $wasDown = False, $downIdx = -1 ;；滑鼠左鍵狀態與按下所在的按鈕
	While 1
		Local $m = GUIGetMsg()
		If $m = $GUI_EVENT_CLOSE Then ExitLoop ;；r=0

		; 滑鼠:按下記住所在按鈕並變深色;放開且在同一顆才觸發(放開才執行)
		Local $ci = GUIGetCursorInfo($dlg)
		If IsArray($ci) Then
			Local $over = -1, $j
			For $j = 0 To $n - 1
				If $ci[4] = $ids[$j] Then
					$over = $j
					ExitLoop
				EndIf
			Next
			Local $nowDown = ($ci[2] = 1)
			If $nowDown And Not $wasDown Then
				$downIdx = $over
				If $over >= 0 Then GUICtrlSetBkColor($ids[$over], $bgDown[$over])
			ElseIf Not $nowDown And $wasDown Then
				If $downIdx >= 0 Then GUICtrlSetBkColor($ids[$downIdx], $bgNorm[$downIdx]) ;；還原
				If $over >= 0 And $over = $downIdx Then
					$r = $over + 1
					ExitLoop
				EndIf
				$downIdx = -1
			EndIf
			$wasDown = $nowDown
		EndIf

		; Esc = 取消(0);Enter = 主要按鈕
		Local $kEsc = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x1B)
		Local $kEnt = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x0D)
		Local $dEsc = IsArray($kEsc) And BitAND($kEsc[0], 0x8000)
		Local $dEnt = IsArray($kEnt) And BitAND($kEnt[0], 0x8000)
		If Not $armed Then
			If Not $dEsc And Not $dEnt Then $armed = True
		Else
			If $dEsc Then
				$r = 0
				ExitLoop
			EndIf
			If $dEnt Then
				$r = $pri
				ExitLoop
			EndIf
		EndIf
		Sleep(10)
	WEnd
	GUISetState(@SW_ENABLE, $hMain)
	GUIDelete($dlg)
	WinActivate($hMain)
	Return $r
EndFunc   ;==>_AppleDlg

; 圖示來源:編譯後用 EXE 內嵌的圖示;未編譯時用同資料夾的 .ico
Func _IcoSrc()
	Return @Compiled ? @AutoItExe : @ScriptDir & "\Obscura.ico"
EndFunc   ;==>_IcoSrc

; 以 GDI+ 載入圖示(可正確解碼 PNG 壓縮的 .ico 幀),先填底色消除透明黑邊,
; 縮放畫到指定尺寸後塞進 Pic 控制項。比 GUICtrlCreateIcon 穩定(後者無法顯示本專案的 .ico)。
Func _LogoPic($x, $y, $w, $h, $bg)
	Local $pic = GUICtrlCreatePic("", $x, $y, $w, $h)
	Local $sIco = _IcoSrc()
	If Not FileExists($sIco) Then Return $pic
	Local $hImg = _GDIPlus_ImageLoadFromFile($sIco)
	If @error Or Not $hImg Then Return $pic
	Local $hBmp = _GDIPlus_BitmapCreateFromScan0($w, $h)
	Local $g = _GDIPlus_ImageGetGraphicsContext($hBmp)
	_GDIPlus_GraphicsClear($g, $bg)
	_GDIPlus_GraphicsSetInterpolationMode($g, 7) ;;HighQualityBicubic
	_GDIPlus_GraphicsSetSmoothingMode($g, 2)
	_GDIPlus_GraphicsDrawImageRect($g, $hImg, 0, 0, $w, $h)
	Local $hHB = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBmp)
	Local $hOld = GUICtrlSendMsg($pic, 0x0172, 0, $hHB) ;;STM_SETIMAGE, IMAGE_BITMAP=0
	If $hOld Then _WinAPI_DeleteObject($hOld)
	If $g_iLogoBmp < UBound($g_aLogoBmp) Then ;;記下 HBITMAP,離開時釋放(Pic 控制項不會自動釋放)
		$g_aLogoBmp[$g_iLogoBmp] = $hHB
		$g_iLogoBmp += 1
	EndIf
	_GDIPlus_GraphicsDispose($g)
	_GDIPlus_BitmapDispose($hBmp)
	_GDIPlus_ImageDispose($hImg)
	Return $pic
EndFunc   ;==>_LogoPic

; ==================================================================
;  設定存檔(使用 _Ini 函數庫,所有變更寫入同資料夾的 INI)
; ==================================================================
; 回傳設定控制項對應表:[鍵名, 控制項 id, 類型]。c=核取/單選狀態, t=文字輸入, m=下拉清單
Func _CfgCtrls()
	Local $a[][3] = [ _
		["Top", $g_chkTop, "c"], ["Log", $g_chkLog, "c"], _
		["Cmt", $g_iCmt, "c"], ["Blank", $g_iBlank, "c"], ["Region", $g_iRegion, "c"], _
		["DelFunc", $g_iDelFunc, "c"], ["DelVar", $g_iDelVar, "c"], ["Join", $g_iJoin, "c"], _
		["DllRen", $g_iDllRen, "c"], ["Sort", $g_iSort, "c"], ["MaxLen", $g_iMaxLen, "c"], _
		["UseInteg", $g_oUseInteg, "c"], ["OutInteg", $g_oOutInteg, "c"], _
		["Udf", $g_oUdf, "c"], ["UdfAdv", $g_oUdfAdv, "c"], ["UdfShuf", $g_oUdfShuf, "c"], _
		["Var", $g_oVar, "c"], ["VarAdv", $g_oVarAdv, "c"], ["Num", $g_oNum, "c"], _
		["StrNone", $g_rStrNone, "c"], ["StrSimple", $g_rStrSimple, "c"], ["StrEnc", $g_rStrEnc, "c"], _
		["StrAdv", $g_oStrAdv, "c"], ["BuiltinWrap", $g_oBuiltinCase, "c"], ["ConfName", $g_oConfName, "c"], ["NegNum", $g_oNegNum, "c"], ["NameMap", $g_oNameMap, "c"], ["CipherRc", $g_rCipherRc, "c"], ["Au3Check", $g_inAu3Check, "t"], ["AutoCheck", $g_oAutoCheck, "c"], _
		["ConvBin", $g_rConvBin, "c"], ["ConvTxt", $g_rConvTxt, "c"], ["ConvVar", $g_rConvVar, "c"], _
		["TmpName", $g_chkTmpName, "c"], ["MLMerge", $g_chkMLMerge, "c"], _
		["MLMode", $g_cboMLMode, "m"], ["MLFilter", $g_cboMLFilter, "m"], ["MLField", $g_inMLField, "t"], _
		["NameLen", $g_inNameLen, "t"], _
		["Std", $g_inStd, "t"], ["SciTE", $g_inSciTE, "t"], ["IgnFunc", $g_inIgnFunc, "t"], _
		["IgnVar", $g_inIgnVar, "t"], ["BytesPerLine", $g_inBytesPerLine, "t"], ["LinesPerVar", $g_inLinesPerVar, "t"], _
		["CertIssuer", $g_inCertIssuer, "t"], ["CertSigner", $g_inCertSigner, "t"], ["CertSerial", $g_inCertSerial, "t"], _
		["Enc", $g_cboEnc, "m"], ["Integ", $g_cboInteg, "m"], ["Lang", $g_cboLang, "m"], _
		["Accent", $g_cboAccent, "m"] ]
	Return $a
EndFunc   ;==>_CfgCtrls

; v18.3.7：設定讀入前留存上一份；備份失敗不影響工具啟動。
Func _BackupConfigSnapshot()
    If Not FileExists($g_cfg) Then Return
    Local $copy = $g_cfg & ".obscura-previous.ini"
    If FileCopy($g_cfg, $copy, 1) Then
        _DebugTrace("CONFIG backup prepared " & $copy)
    Else
        _DebugTrace("CONFIG warning: backup failed " & $copy)
    EndIf
EndFunc   ;==>_BackupConfigSnapshot

; 讀取 INI,套用到各控制項
Func _CfgLoad()
	$g_cfgReady = False
	If FileExists($g_cfg) Then
		Local $a = _CfgCtrls()
		Local $key, $id, $ty, $v, $i
		For $i = 0 To UBound($a) - 1
			$key = $a[$i][0]
			$id = $a[$i][1]
			$ty = $a[$i][2]
			Switch $ty
				Case "c"
					$v = _IniRead($g_cfg, "Settings", $key, "", 128)
					If $v <> "" Then GUICtrlSetState($id, (Number($v) = $GUI_CHECKED) ? $GUI_CHECKED : $GUI_UNCHECKED)
				Case "t"
					$v = _IniRead($g_cfg, "Settings", $key, Chr(1), 128)
					If $v <> Chr(1) Then GUICtrlSetData($id, $v)
				Case "m"
					$v = _IniRead($g_cfg, "Settings", $key, "", 128)
					If $v <> "" Then _GUICtrlComboBox_SelectString($id, $v)
			EndSwitch
		Next
		WinSetOnTop($hMain, "", (GUICtrlRead($g_chkTop) = $GUI_CHECKED) ? 1 : 0) ;;套用置頂狀態
		; 視窗位置已於 _BuildGui 建立視窗時直接帶入舊座標,此處不再 WinMove(避免顯示後再跳動)
		; 自動載入上次的腳本(若仍存在)
		Local $last = _IniRead($g_cfg, "Recent", "Last", "", 128)
		If $last <> "" And FileExists($last) Then _SetScript($last, False) ;;啟動自動載入不提示
	EndIf
	$g_bLvSafeDraw = False ;;安全繪製模式已移除(清單全改 owner-draw ListBox,不再需要);保留變數供繪製守衛相容
	$g_cfgReady = True
EndFunc   ;==>_CfgLoad

; 以單次 _IniWriteSection 將全部設定寫入 INI(效率高,一次寫檔)
Func _CfgSave()
	If Not $g_cfgReady Then Return
	Local $a = _CfgCtrls()
	Local $d[UBound($a)][2]
	Local $i
	For $i = 0 To UBound($a) - 1
		$d[$i][0] = $a[$i][0]
		$d[$i][1] = GUICtrlRead($a[$i][1])
	Next
	_IniWriteSection($g_cfg, "Settings", $d, 0, 128)
	; 路徑類設定改以 _IniWrite 單筆覆寫:此函式會正確轉義反斜線,避免區段寫入把路徑的 \ 吃掉
	; (即使日後連到未修正的 _Ini.au3,這三條路徑也能保證保留反斜線)
	_IniWrite($g_cfg, "Settings", "SciTE", GUICtrlRead($g_inSciTE), 128)
	_IniWrite($g_cfg, "Settings", "Std", GUICtrlRead($g_inStd), 128)
	_IniWrite($g_cfg, "Settings", "Au3Check", GUICtrlRead($g_inAu3Check), 128)
	; 視窗位置另存於 [Window] 區段
	Local $pos = WinGetPos($hMain)
	If IsArray($pos) Then
		_IniWrite($g_cfg, "Window", "X", $pos[0], 128)
		_IniWrite($g_cfg, "Window", "Y", $pos[1], 128)
	EndIf
	If $g_script <> "" Then _IniWrite($g_cfg, "Recent", "Last", $g_script, 128) ;;記住上次腳本
EndFunc   ;==>_CfgSave

; 匯出目前設定為獨立 .ini(含 [Settings] 與 [Window])
Func _CfgExport()
	_CfgSave() ;;先確保最新設定已寫入主 INI
	Local $dst = FileSaveDialog("匯出設定", @ScriptDir, "設定檔 (*.ini)", 16, "Obscura_設定.ini", $hMain)
	If @error Then Return
	If StringRight($dst, 4) <> ".ini" Then $dst &= ".ini"
	If FileCopy($g_cfg, $dst, 1) Then
		_Msg(64, "完成", "已匯出設定：" & @CRLF & $dst)
	Else
		_Msg(16, "失敗", "無法寫入：" & @CRLF & $dst)
	EndIf
EndFunc   ;==>_CfgExport

; 從 .ini 匯入設定並套用
Func _CfgImport()
	Local $src = FileOpenDialog("匯入設定", @ScriptDir, "設定檔 (*.ini)|所有檔案 (*.*)", 3, "", $hMain)
	If @error Then Return
	If FileCopy($src, $g_cfg, 1) Then
		_CfgLoad() ;;套用到各控制項
		_CfgSave() ;;回寫(統一格式)
		_Msg(64, "完成", "已匯入並套用設定。" & @CRLF & "（介面語言若有變更需重新啟動）")
	Else
		_Msg(16, "失敗", "無法讀取設定檔。")
	EndIf
EndFunc   ;==>_CfgImport

; ==================================================================
;  建立所有分頁(子視窗)
; ==================================================================
Func _BuildPages()
	; ---------- 整合與混淆（主說明）----------
	; v18.3.7: 舊的唯讀多行 Edit 在切頁 / Windows 重繪後會出現文字殘影、
	;           重複的「忽略指令」和圓形焦點殘影。此頁只需展示固定說明，
	;           改用不接受焦點的靜態 Label，並分區定位，避免 Edit 捲動重繪。
	$g_pg[$PG_MAIN] = _NewPage()
	_Head("整合與混淆")
	_BuildMainHelpStatic()

	; ---------- 程式碼檢測 ----------
	$g_pg[$PG_DETECT] = _NewPage()
	_Head("程式碼檢測")
	; 診斷記錄存於 %TEMP%\Obscura_DebugCrash.log（同時輸出 SciTE）。
	Local $dOut = _AppleBtn("輸出檢測結果", S(10), S(40), S(150), S(30))
	Local $dFn = _AppleBtn("函式", S(360), S(40), S(92), S(30))
	Local $dVar = _AppleBtn("變數", S(456), S(40), S(92), S(30))
	Local $dStr = _AppleBtn("字串", S(552), S(40), S(92), S(30))
	Local $dSp = _AppleBtn("特殊變數函式", S(648), S(40), S(114), S(30))
	Local $dAll = _AppleBtn("全部檢測", S(190), S(40), S(150), S(30))
	; 試點:檢測清單改用 owner-draw ListBox(走 WM_DRAWITEM,與 Apple 按鈕同路徑,避開會卡的 ListView 自繪)
	_LvHeader(10, 78, 752, "序號|內容", "8|70") ;;欄位標題列(ListBox 無原生表頭)
	$g_lvDetect = GUICtrlCreateList("", S(10), S(100), S(752), S(408), BitOR($LBS_OWNERDRAWFIXED, $LBS_HASSTRINGS, $LBS_NOTIFY, $WS_VSCROLL, $WS_BORDER))
	_GUICtrlListBox_SetItemHeight(GUICtrlGetHandle($g_lvDetect), S(22)) ;;owner-draw 固定列高
	Local $mnuDet = GUICtrlCreateContextMenu($g_lvDetect) ;;右鍵選單
	$g_mnuDetCopy = GUICtrlCreateMenuItem("複製選取列", $mnuDet)
	$g_mnuDetOpen = GUICtrlCreateMenuItem("以 SciTE 開啟該行", $mnuDet)
	GUICtrlCreateMenuItem("", $mnuDet)
	$g_mnuDetExport = GUICtrlCreateMenuItem("匯出全部…", $mnuDet)
	GUICtrlCreateLabel("定位：", S(10), S(518), S(48), S(24))
	$g_inLocate = GUICtrlCreateInput("", S(62), S(514), S(700), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inLocate), "點選顯示行號，雙擊以 SciTE 開啟該行")
	$g_detBtn[0] = $dOut
	$g_detBtn[1] = $dFn
	$g_detBtn[2] = $dVar
	$g_detBtn[3] = $dStr
	$g_detBtn[4] = $dSp
	$g_detBtn[5] = $dAll

	; ---------- 執行情況 ----------
	$g_pg[$PG_EXEC] = _NewPage()
	_Head("執行情況")
	_LvHeader(10, 40, 752, "索引|項目|執行情況", "8|64|534") ;;改用手繪標題列,與其他清單一致(原生表頭在本視窗顯示異常)
	$g_lvExec = GUICtrlCreateListView("索引|項目|執行情況", S(10), S(62), S(752), S(486), BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $LVS_SINGLESEL, $LVS_NOCOLUMNHEADER))
	_GUICtrlListView_SetColumnWidth($g_lvExec, 0, S(56))
	_GUICtrlListView_SetColumnWidth($g_lvExec, 1, S(470))
	_GUICtrlListView_SetColumnWidth($g_lvExec, 2, S(214))
	_InitExecList()

	; ---------- 參數設定 ----------
	$g_pg[$PG_PARAM] = _NewPage()
	_Head("參數設定")
	GUICtrlCreateLabel("SciTE 路徑：", S(20), S(52), S(110), S(24))
	$g_inSciTE = GUICtrlCreateInput("", S(136), S(48), S(520), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inSciTE), "SciTE.exe 完整路徑（可留空）")
	$g_btnBrowseSciTE = _AppleBtn("…", S(662), S(48), S(34), S(26))
	GUICtrlCreateLabel("標準庫路徑：", S(20), S(90), S(110), S(24))
	$g_inStd = GUICtrlCreateInput(_GuessIncludeDir(), S(136), S(86), S(520), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inStd), "AutoIt 標準庫 Include 資料夾路徑")
	$g_btnBrowseStd = _AppleBtn("…", S(662), S(86), S(34), S(26))
	$g_chkLog = GUICtrlCreateCheckbox(" 輸出日誌", S(20), S(126), S(200), S(26))
	GUICtrlSetState($g_chkLog, $GUI_CHECKED)
	$g_oNameMap = GUICtrlCreateCheckbox(" 輸出名稱對照表（原名→混淆名；便於除錯，會洩漏對應）", S(20), S(200), S(640), S(26))
	GUICtrlCreateLabel("AU3Check 路徑：", S(20), S(236), S(140), S(24))
	$g_inAu3Check = GUICtrlCreateInput(_GuessAu3Check(), S(160), S(232), S(496), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inAu3Check), "AU3Check.exe 完整路徑（可留空；用於輸出後自動檢查）")
	$g_btnBrowseAu3Check = _AppleBtn("…", S(662), S(232), S(34), S(26))
	$g_oAutoCheck = GUICtrlCreateCheckbox(" 混淆/整合後自動以 AU3Check 檢查輸出", S(20), S(272), S(640), S(26))
	GUICtrlCreateLabel("腳本輸出編碼：", S(20), S(164), S(120), S(24))
	$g_cboEnc = GUICtrlCreateCombo("", S(146), S(160), S(440), S(24), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboEnc, "使用 Unicode UTF8（含BOM） 編碼|使用 Unicode UTF8（無BOM） 編碼|使用 Unicode UTF16 LE 編碼|使用 ANSI 編碼", "使用 Unicode UTF8（含BOM） 編碼")
	GUICtrlSetState($g_cboEnc, $GUI_HIDE) ;;原生 combo 隱藏只存值,顯示改用 Apple 按鈕
	$g_btnEncDrop = _AppleBtn("", S(146), S(159), S(440), S(28))

	; ---------- 腳本整合 ----------
	$g_pg[$PG_INTEG] = _NewPage()
	_Head("整合設定")
	$g_cboInteg = GUICtrlCreateCombo("", S(20), S(40), S(600), S(24), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboInteg, "依腳本中 Include 命令的位置整合（速度較慢）|快速整合（置於第一個 #include 位置）", "依腳本中 Include 命令的位置整合（速度較慢）")
	GUICtrlSetState($g_cboInteg, $GUI_HIDE) ;;原生 combo 隱藏只存值,顯示改用 Apple 按鈕
	$g_btnIntegDrop = _AppleBtn("", S(20), S(39), S(600), S(28))
	$g_iCmt = _Chk(" 清除註解", 20, 76, True)
	$g_iBlank = _Chk(" 清除腳本空行及行首尾空白字元", 20, 106, True)
	$g_iRegion = _Chk(" 清除 #Region 和 #EndRegion", 20, 136, True)
	$g_iDelFunc = _Chk(" 清除未使用函式（啟發式，請測試）", 20, 166, False)
	$g_iDelVar = _Chk(" 清除未使用變數（啟發式，請測試）", 20, 196, False)
	$g_iJoin = _Chk(" 合併由 "" _"" 連接的行", 20, 226, True)
	$g_iDllRen = _Chk(" 當 Dll 檔案內建函式與 UDF 函式名稱相同時對 UDF 函式重新命名", 20, 256, True)
	$g_iSort = _Chk(" 變數函式分類整理", 20, 286, True)
	$g_iMaxLen = _Chk(" 整合完成後進行「單行最大字元長度限制」檢測", 20, 316, False)

	; ---------- 腳本混淆 ----------
	$g_pg[$PG_OBFUS] = _NewPage()
	_Head("混淆設定")
	$g_btnPreMax = _AppleBtn("最強保護", S(566), S(6), S(94), S(26)) ;;一鍵套用最強(不含風險啟發式)
	$g_btnPreStd = _AppleBtn("標準", S(666), S(6), S(94), S(26)) ;;回到預設
	$g_oUseInteg = _Chk(" 依腳本整合設定進行整合", 20, 40, True)
	$g_oOutInteg = _Chk(" 輸出整合後的腳本", 20, 70, True, 300)
	$g_oBuiltinCase = _Chk(" 內建函式混淆（隨機名稱包裝）", 20, 100, False, 320) ;;移回左欄,與其他混淆選項排在一起
	$g_oUdf = _Chk(" UDF 函式混淆", 20, 130, True, 200)
	$g_oUdfAdv = _Chk(" 函式混淆進階", 230, 130, True, 200)
	$g_oUdfShuf = _Chk(" UDF 函式亂序排列", 450, 130, True, 220)
	$g_oVar = _Chk(" 變數混淆", 20, 160, True, 200)
	$g_oVarAdv = _Chk(" 變數混淆進階", 230, 160, True, 200)
	$g_oConfName = _Chk(" 易混淆名稱（l/I/1/O/0）", 450, 160, False, 300)
	$g_oNum = _Chk(" 數字加密", 20, 190, False, 320) ;;寬度限制在 x340 前,避免蓋住右側「亂數名稱長度」標籤/輸入框
	GUICtrlCreateLabel("亂數名稱長度（3-12）：", S(360), S(192), S(170), S(24))
	$g_inNameLen = GUICtrlCreateInput("6", S(532), S(188), S(60), S(26), $ES_NUMBER)
	$g_oNegNum = _Chk("　數字加密強化：連負號也一起隱藏", 40, 220, False, 560)
	GUICtrlCreateGroup("字串處理", S(20), S(254), S(600), S(86))
	$g_rStrNone = GUICtrlCreateRadio(" 不處理", S(36), S(280), S(110), S(24))
	$g_rStrSimple = GUICtrlCreateRadio(" 簡單處理", S(170), S(280), S(130), S(24))
	$g_rStrEnc = GUICtrlCreateRadio(" 加密處理", S(320), S(280), S(130), S(24))
	GUICtrlSetState($g_rStrEnc, $GUI_CHECKED)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_oStrAdv = _Chk("　加密強化：金鑰隨位置變動（更安全，僅「加密處理」時生效）", 40, 310, False, 540)
	GUICtrlCreateGroup("密文處理", S(20), S(348), S(600), S(56))
	$g_rCipherIn = GUICtrlCreateRadio(" 密文置於腳本內部", S(36), S(374), S(220), S(24))
	GUICtrlSetState($g_rCipherIn, $GUI_CHECKED)
	$g_rCipherRc = GUICtrlCreateRadio(" 密文置於 RC 資源段", S(262), S(374), S(338), S(24))
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateLabel("忽略函式（正則，逗號分隔）：", S(20), S(412), S(260), S(24))
	$g_inIgnFunc = GUICtrlCreateInput("", S(20), S(434), S(600), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inIgnFunc), "例：WM_COMMAND,func\d+（以逗號分隔，支援正則）")
	GUICtrlCreateLabel("忽略變數（正則，逗號分隔）：", S(20), S(468), S(260), S(24))
	$g_inIgnVar = GUICtrlCreateInput("", S(20), S(490), S(600), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inIgnVar), "例：\$Form1,\$v\d+（以逗號分隔，支援正則）")
	GUICtrlCreateLabel("忽略清單會與腳本內 #Obfuscator_Ignore_* 合併；格式參考上方輸入框提示。", S(20), S(522), S(620), S(24))

	; ---------- 多語言處理 ----------
	$g_pg[$PG_ML] = _NewPage()
	_Head("多語言處理")
	_LvHeader(10, 40, 560, "索引|字串", "8|68") ;;欄位標題列(ListBox 無原生表頭)
	$g_lvML = GUICtrlCreateList("", S(10), S(62), S(560), S(416), BitOR($LBS_OWNERDRAWFIXED, $LBS_HASSTRINGS, $LBS_NOTIFY, $WS_VSCROLL, $WS_BORDER)) ;;owner-draw ListBox:走 WM_DRAWITEM,不觸發 ListView NM_CUSTOMDRAW 重入(不卡)
	_GUICtrlListBox_SetItemHeight(GUICtrlGetHandle($g_lvML), S(22)) ;;owner-draw 固定列高
	Local $mnuML = GUICtrlCreateContextMenu($g_lvML) ;;右鍵選單
	$g_mnuMLCopy = GUICtrlCreateMenuItem("複製選取列", $mnuML)
	$g_mnuMLOpen = GUICtrlCreateMenuItem("以 SciTE 開啟該行", $mnuML)
	GUICtrlCreateMenuItem("", $mnuML)
	$g_mnuMLRestore = GUICtrlCreateMenuItem("還原（清空）", $mnuML)
	GUICtrlCreateLabel("定位：", S(10), S(486), S(50), S(24))
	$g_inMLLocate = GUICtrlCreateInput("", S(62), S(482), S(508), S(26), $ES_READONLY)

	GUICtrlCreateLabel("多語言處理模式：", S(584), S(44), S(180), S(22))
	$g_cboMLMode = GUICtrlCreateCombo("", S(584), S(68), S(170), S(26), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboMLMode, "只有非中文字元|只有中文字元|包含中文字元|所有字元|由雙引號 "" 包含|由單引號 ' 包含", "包含中文字元")
	GUICtrlSetState($g_cboMLMode, $GUI_HIDE) ;;原生 combo 隱藏只存值,顯示改用 Apple 按鈕
	$g_btnMLModeDrop = _AppleBtn("", S(584), S(67), S(170), S(28))

	GUICtrlCreateLabel("語言檔欄位名稱：", S(584), S(104), S(180), S(22))
	$g_inMLField = GUICtrlCreateInput("TEXT", S(584), S(128), S(170), S(26))

	GUICtrlCreateLabel("過濾：", S(584), S(164), S(180), S(22))
	$g_cboMLFilter = GUICtrlCreateCombo("", S(584), S(188), S(170), S(26), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboMLFilter, "不處理|處理|顯示所有", "處理")
	GUICtrlSetState($g_cboMLFilter, $GUI_HIDE) ;;原生 combo 隱藏只存值,顯示改用 Apple 按鈕
	$g_btnMLFilterDrop = _AppleBtn("", S(584), S(187), S(170), S(28))

	$g_chkMLMerge = GUICtrlCreateCheckbox(" 合併（附加到既有語言檔）", S(584), S(214), S(176), S(44))
	GUICtrlSetState($g_chkMLMerge, $GUI_CHECKED)

	Local $mlRestore = _AppleBtn("還原", S(584), S(262), S(170), S(32))
	Local $mlDetect = _AppleBtn("檢測", S(584), S(300), S(170), S(32))
	Local $mlRun = _AppleBtn("執行（產生語言檔）", S(584), S(338), S(170), S(32))
	$g_mlBtn[0] = $mlDetect
	$g_mlBtn[1] = $mlRun
	$g_mlBtn[2] = $mlRestore

	; ---------- 自我校驗 ----------
	$g_pg[$PG_SELF] = _NewPage()
	_Head("自我校驗")
	GUICtrlCreateGroup("憑證資訊", S(10), S(40), S(620), S(170))
	GUICtrlCreateLabel("頒發者：", S(24), S(76), S(70), S(24))
	$g_inCertIssuer = GUICtrlCreateInput("", S(100), S(72), S(500), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inCertIssuer), "數位憑證的發行機構")
	GUICtrlCreateLabel("簽署者：", S(24), S(112), S(70), S(24))
	$g_inCertSigner = GUICtrlCreateInput("", S(100), S(108), S(500), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inCertSigner), "數位憑證的使用者名稱")
	GUICtrlCreateLabel("序號：", S(24), S(148), S(70), S(24))
	$g_inCertSerial = GUICtrlCreateInput("", S(100), S(144), S(500), S(26))
	_GUICtrlEdit_SetCueBanner(GUICtrlGetHandle($g_inCertSerial), "數位憑證的序號（32 位）")
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	Local $selGen = _AppleBtn("產生自我校驗樣板", S(10), S(226), S(180), S(32))
	Local $selChk = _AppleBtn("檢查 EXE 簽章", S(202), S(226), S(170), S(32))
	Local $selRead = _AppleBtn("讀取 EXE 憑證資訊", S(384), S(226), S(190), S(32))
	GUICtrlCreateLabel("說明：「檢查 EXE 簽章」用 WinVerifyTrust 驗證是否已簽章且未被竄改；" & @CRLF & _
			"「讀取 EXE 憑證資訊」會擷取序號/頒發者填入上方欄位；樣板可直接貼進你的腳本使用。", S(10), S(268), S(740), S(60))
	$g_selBtn = $selGen
	$g_selBtnChk = $selChk
	$g_selBtnRead = $selRead

	; ---------- 除錯輔助 ----------
	$g_pg[$PG_DEBUG] = _NewPage()
	_Head("除錯輔助")
	$g_inDbgFile = GUICtrlCreateInput("將要檢查的腳本拖放至此處", S(10), S(40), S(498), S(26), $ES_READONLY)
	GUICtrlSetState($g_inDbgFile, $GUI_DROPACCEPTED)
	Local $dbgPick = _AppleBtn("...", S(514), S(39), S(40), S(28))
	Local $dbgRun = _AppleBtn("檢測", S(558), S(39), S(86), S(28))
	Local $dbgExport = _AppleBtn("匯出對照表", S(648), S(39), S(114), S(28))
	_LvHeader(10, 76, 752, "實際行號|內部行號（近似）|內容", "8|92|220") ;;欄位標題列(ListBox 無原生表頭)
	$g_lvDbg = GUICtrlCreateList("", S(10), S(98), S(752), S(408), BitOR($LBS_OWNERDRAWFIXED, $LBS_HASSTRINGS, $LBS_NOTIFY, $WS_VSCROLL, $WS_BORDER)) ;;owner-draw ListBox:三欄(實際行號/內部行號/內容),走 WM_DRAWITEM(不卡)
	_GUICtrlListBox_SetItemHeight(GUICtrlGetHandle($g_lvDbg), S(22)) ;;owner-draw 固定列高
	GUICtrlCreateLabel("註：被檢查的腳本必須是整合後的腳本；內部行號為近似值。雙擊可用 SciTE 開啟該行。", S(10), S(513), S(740), S(20))
	Local $dbgLogLabel = GUICtrlCreateLabel("診斷 LOG：%TEMP%\Obscura_DebugCrash.log（同步輸出至 SciTE）", S(10), S(538), S(625), S(20))
	GUICtrlSetColor($dbgLogLabel, 0x66666B)
	Local $dbgLogOpen = _AppleBtn("開啟 LOG", S(648), S(534), S(114), S(24))
	$g_dbgBtn[0] = $dbgPick
	$g_dbgBtn[1] = $dbgRun
	$g_dbgBtn[2] = $dbgExport
	$g_dbgBtn[3] = $dbgLogOpen

	; ---------- 程式碼轉換 ----------
	$g_pg[$PG_CONV] = _NewPage()
	_Head("程式碼轉換（取代 FileInstall）")
	$g_inConvFile = GUICtrlCreateInput("將要轉換的檔案拖放到此處", S(10), S(40), S(320), S(26), $ES_READONLY)
	GUICtrlSetState($g_inConvFile, $GUI_DROPACCEPTED)
	Local $convPick = _AppleBtn("...", S(10), S(72), S(320), S(26))
	GUICtrlCreateGroup("選項", S(346), S(36), S(260), S(150))
	$g_rConvBin = GUICtrlCreateRadio(" 產生 AU3 釋放二進位檔案程式碼", S(358), S(58), S(240), S(24))
	GUICtrlSetState($g_rConvBin, $GUI_CHECKED)
	$g_rConvTxt = GUICtrlCreateRadio(" 產生 AU3 釋放文字檔案程式碼", S(358), S(88), S(240), S(24))
	$g_rConvVar = GUICtrlCreateRadio(" 產生 AU3 單一二進位變數或常數", S(358), S(118), S(240), S(24))
	$g_chkTmpName = GUICtrlCreateCheckbox(" 檔案釋放為隨機檔名（～TmpXXXX）", S(358), S(150), S(240), S(24))
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateGroup("控制參數", S(620), S(36), S(142), S(150))
	GUICtrlCreateLabel("每行位元組數：", S(628), S(58), S(130), S(22))
	$g_inBytesPerLine = GUICtrlCreateInput("100", S(628), S(82), S(120), S(26))
	GUICtrlCreateLabel("每個變數行數：", S(628), S(114), S(130), S(22))
	$g_inLinesPerVar = GUICtrlCreateInput("20", S(628), S(138), S(120), S(26))
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateLabel("資料互轉：", S(10), S(176), S(100), S(24))
	; 轉換輸出改用內嵌 Scintilla(SciTE 編輯器核心,自行雙緩衝繪製,無殘影、吃大檔穩)。
	$g_hSci = _SciCreate($g_pg[$PG_CONV], S(10), S(202), S(752), S(286))
	Local $convOpen = 0
	If Not $g_hSci Then
		; 退回方案:載不到 SciLexer/Scintilla.dll → 顯示說明,結果改用獨立視窗
		GUICtrlCreateGroup("", S(10), S(202), S(752), S(286))
		Local $convHint = GUICtrlCreateLabel("找不到 SciLexer.dll / Scintilla.dll(通常在 AutoIt 的 SciTE 資料夾)。" & @CRLF & _
				"已自動改用獨立視窗顯示轉換結果;若要內嵌顯示,請把該 DLL 放到本程式同資料夾。" & @CRLF & @CRLF & _
				"下方「複製程式碼」「另存為 .au3」仍可直接對最近一次結果操作。", S(40), S(260), S(692), S(120))
		GUICtrlSetColor($convHint, 0x6E6E73)
		GUICtrlSetFont($convHint, 11, 400, 0, "Microsoft JhengHei UI")
		$convOpen = _AppleBtn("開啟結果視窗", S(312), S(400), S(160), S(38))
		GUICtrlCreateGroup("", -99, -99, 1, 1)
	EndIf
	GUISwitch($g_pg[$PG_CONV]) ;;Scintilla 以 CreateWindowEx 建立後,重新確立分頁為後續控制項建立對象
	Local $convCopy = _AppleBtn("複製程式碼", S(10), S(498), S(120), S(30))
	Local $convSave = _AppleBtn("另存為 .au3", S(136), S(498), S(120), S(30))
	Local $convLoad = _AppleBtn("載入檔案", S(360), S(498), S(120), S(30))
	Local $convClr = _AppleBtn("清空輸入框", S(486), S(498), S(120), S(30))
	Local $convDo = _AppleBtn("轉換（由上方檔案）", S(612), S(498), S(150), S(30))
	$g_convBtn[0] = $convPick
	$g_convBtn[1] = $convLoad
	$g_convBtn[2] = $convClr
	$g_convBtn[3] = $convDo
	$g_convBtn[4] = $convCopy
	$g_convBtn[5] = $convSave
	$g_convBtn[6] = $convOpen

	; ---------- 語系切換 ----------
	$g_pg[$PG_LANG] = _NewPage()
	_Head("設定")
	$g_chkTop = GUICtrlCreateCheckbox(" 視窗置頂（預設開啟）", S(20), S(46), S(320), S(26))
	GUICtrlSetState($g_chkTop, $GUI_CHECKED)
	GUICtrlCreateLabel("語種切換（介面語言）：", S(20), S(90), S(170), S(24))
	$g_cboLang = GUICtrlCreateCombo("", S(196), S(86), S(180), S(26), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboLang, "繁體中文|简体中文", "繁體中文")
	GUICtrlSetState($g_cboLang, $GUI_HIDE) ;;原生 combo 僅作資料來源(供設定存取/讀取),畫面改用下方 Apple 按鈕
	$g_btnLangDrop = _AppleBtn("繁體中文  " & ChrW(0x25BE), S(196), S(85), S(180), S(28))
	GUICtrlCreateLabel("切換後需重新啟動程式才會套用。", S(388), S(90), S(340), S(24))
	GUICtrlSetColor(-1, 0x007AFF)

	GUICtrlCreateGroup("腳本繁簡轉換（轉換「載入的腳本」內容，與介面語言無關）", S(20), S(140), S(620), S(114))
	GUICtrlCreateLabel("使用 Windows LCMapString 轉換腳本中的中文字元（ASCII 不變），" & @CRLF & _
			"輸出為同資料夾的 <檔名>_SC.au3（简体） / <檔名>_TC.au3（繁體）。", S(36), S(168), S(590), S(44))
	$g_btnTC2SC = _AppleBtn("腳本：繁體 → 简体", S(36), S(212), S(170), S(32))
	$g_btnSC2TC = _AppleBtn("腳本：简体 → 繁體", S(220), S(212), S(170), S(32))
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("設定備份", S(20), S(264), S(620), S(80))
	GUICtrlCreateLabel("將目前所有設定匯出成 .ini 以便備份/分享，或從 .ini 匯入套用。", S(36), S(290), S(590), S(22))
	$g_btnCfgExport = _AppleBtn("匯出設定…", S(36), S(312), S(160), S(26))
	$g_btnCfgImport = _AppleBtn("匯入設定…", S(210), S(312), S(160), S(26))
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	GUICtrlCreateGroup("外觀", S(20), S(354), S(620), S(70))
	GUICtrlCreateLabel("主題色（左側選取項目的顏色）：", S(36), S(384), S(250), S(24))
	$g_cboAccent = GUICtrlCreateCombo("", S(290), S(380), S(150), S(26), BitOR($CBS_DROPDOWNLIST, $CBS_DROPDOWN))
	GUICtrlSetData($g_cboAccent, "藍|靛|紫|綠|橙|紅|灰", "藍")
	GUICtrlSetState($g_cboAccent, $GUI_HIDE) ;;同上:隱藏原生 combo,改用 Apple 按鈕顯示
	$g_btnAccentDrop = _AppleBtn("藍  " & ChrW(0x25BE), S(290), S(379), S(150), S(28))
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	; ---------- 關於 ----------
	$g_pg[$PG_ABOUT] = _NewPage()
	_Head("關於")
	_LogoPic(S(16), S(46), S(48), S(48), 0xFFFFFFFF) ;;關於頁圖示(GDI+ 載入,白底)
	GUICtrlCreateLabel("Obscura — AutoIt 原始碼保護  v" & $OB_VER, S(78), S(48), S(500), S(28))
	GUICtrlSetFont(-1, 14, 700, 0, $font_name, $font_quality)
	$g_lnkBrand = GUICtrlCreateLabel("格雷資訊 — grayfree.tw", S(78), S(80), S(260), S(24), $SS_NOTIFY)
	GuiCtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x007AFF)
	GUICtrlSetFont(-1, $fontsize, 400, 4, $font_name, $font_quality) ;；底線=連結感
	GUICtrlCreateLabel( _
			"Obscura 是一套 AutoIt 原始碼保護工具，繁體中文（台灣用語）介面。" & @CRLF & @CRLF & _
			"功能：整合（合併 #include）、清除註解/空行/#Region、函式/變數混淆、" & @CRLF & _
			"函式亂序（可獨立）、數字加密（含浮點；可連負號隱藏）、" & @CRLF & _
			"字串加密（每段獨立金鑰；可選位置相依滾動金鑰）、易混淆名稱（l/I/1/O/0）、" & @CRLF & _
			"程式碼檢測、多語言處理、自我校驗（數位簽章驗證）、除錯行號對照、" & @CRLF & _
			"名稱對照表匯出、防重複混淆偵測、強度一鍵預設、程式碼轉換（FileInstall）、" & @CRLF & _
			"設定存檔與備份、批次處理。" & @CRLF & @CRLF & _
			"著重『原始碼層級保護』，用於保護你自己的腳本；" & @CRLF & _
			"如需進一步防逆向，請搭配 AutoIt 官方編譯與商用加殼。", S(20), S(112), S(720), S(240))

	; 連結列(可點擊;底線+藍色)
	$g_lnkGit = GUICtrlCreateLabel("GitHub：Au3Obscura 專案頁", S(20), S(392), S(300), S(24), $SS_NOTIFY)
	GuiCtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x007AFF)
	GUICtrlSetFont(-1, $fontsize, 400, 4, $font_name, $font_quality)
	$g_lnkSpon = GUICtrlCreateLabel("♥ 贊助支持作者", S(340), S(392), S(200), S(24), $SS_NOTIFY)
	GuiCtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0xFF3B30)
	GUICtrlSetFont(-1, $fontsize, 400, 4, $font_name, $font_quality)

	; ---------- 註冊 ----------
	$g_pg[$PG_REG] = _NewPage()
	_Head("註冊")
	GUICtrlCreateLabel("本程式為免費使用，無需註冊，全部功能開放。", S(20), S(56), S(600), S(50))

	For $i = 0 To $PG_COUNT - 1
		GUISetState(@SW_HIDE, $g_pg[$i])
	Next
EndFunc   ;==>_BuildPages
Func _Chk($txt, $x, $y, $checked, $w = 640)
	Local $id = GUICtrlCreateCheckbox($txt, S($x), S($y), S($w), S(26))
	If $checked Then GUICtrlSetState($id, $GUI_CHECKED)
	Return $id
EndFunc   ;==>_Chk

; 分頁標題
Func _Head($txt)
	GUICtrlCreateLabel($txt, S(10), S(8), S(400), S(26))
	GUICtrlSetFont(-1, 12, 700, 0, $font_name, $font_quality)
	GUICtrlSetColor(-1, 0x007AFF) ;;Apple 藍標題
EndFunc   ;==>_Head

; 依 DPI 縮放座標/尺寸
Func S($n)
	Return Int($n * $g_scale)
EndFunc   ;==>S

; 套用全域字型到指定視窗(需在建立控制項之前呼叫)
Func _Font($h)
	GUISetFont($fontsize, $font_xing, $font_var, $font_name, $h, $font_quality)
EndFunc   ;==>_Font

; 建立一個分頁子視窗並套用字型
Func _NewPage()
	; 分頁子視窗也加上 $WS_EX_ACCEPTFILES,確保拖放欄(除錯/轉換)在系統層級能收到 WM_DROPFILES
	Local $h = GUICreate("", S(772), S(560), S(200), S(142), $WS_CHILD, $WS_EX_ACCEPTFILES, $hMain) ;;y 下移 34(讓出自訂標題列)
	_Font($h)
	GUISetBkColor(0xFFFFFF, $h) ;;內容分頁白底(浮在淺灰主視窗上,macOS 卡片感)
	Return $h
EndFunc   ;==>_NewPage

; ==================================================================
;  DPI 自適應(參考範例並修正)
; ==================================================================
Func _DpiInit()
	If @Compiled Then
		If _IsProcessDPIAware() Then Return _GetDpi()
		Return 1
	EndIf
	_SetProcessDPIAware()
	Return _GetDpi()
EndFunc   ;==>_DpiInit

Func _SetProcessDPIAware()
	If @OSBuild < 9600 Then ;;Win8.1 以前
		DllCall("User32.dll", "bool", "SetProcessDPIAware")
	Else
		DllCall("Shcore.dll", "int", "SetProcessDpiAwareness", "int", 2) ;;2=每監視器 DPI 感知
	EndIf
EndFunc   ;==>_SetProcessDPIAware

Func _GetDpi()
	Local $iDPI
	If @OSBuild < 9600 Then
		$iDPI = RegRead("HKCU\Control Panel\Desktop\WindowMetrics", "AppliedDPI")
	Else
		Local $hMon = _WinAPI_MonitorFromWindow(_WinAPI_GetDesktopWindow())
		Local $aRet = DllCall("Shcore.dll", "int", "GetDpiForMonitor", "handle", $hMon, "int", 0, "uint*", 0, "uint*", 0)
		If @error Or Not IsArray($aRet) Then Return 1
		$iDPI = $aRet[3]
	EndIf
	If $iDPI < 96 Or $iDPI > 480 Then $iDPI = 96
	Return $iDPI / 96
EndFunc   ;==>_GetDpi

Func _IsProcessDPIAware()
	Local $aRet
	If @OSBuild < 9600 Then
		$aRet = DllCall("User32.dll", "bool", "IsProcessDPIAware")
		If @error Or Not IsArray($aRet) Then Return False
		Return $aRet[0]
	EndIf
	$aRet = DllCall("Shcore.dll", "int", "GetProcessDpiAwareness", "ptr", 0, "int*", 0)
	If @error Or Not IsArray($aRet) Then Return False
	Return ($aRet[2] <> 0)
EndFunc   ;==>_IsProcessDPIAware

; 只切換「原頁/新頁」，避免 13 個 WS_CHILD 分頁反覆隱藏時造成 WM_PAINT/WM_NOTIFY 風暴。
; GUISetState 用明確子視窗 handle，不變更 AutoIt 目前 GUI 的控制項環境。
Func _ShowPage($page)
	If $page < 0 Or $page >= $PG_COUNT Then Return
	If Not IsHWnd($g_pg[$page]) Then Return
	If $page = $g_iActivePage Then Return
	; 畫面切換只能由事件迴圈進入，禁止在切換/更新資料時同步重入。
	If $g_bPageSwitchBusy Or $g_bListPopulating Then
		$g_iPendingSidePage = $page
		Return
	EndIf
	$g_bPageSwitchBusy = True
	$g_bDebugPageGuard = True
	$g_iPageSwitchSerial += 1
	$g_iDiagCustomDrawLogs = 0
	Local $oldPage = $g_iActivePage
	Local $serial = $g_iPageSwitchSerial
	_DebugTrace("SWITCH #" & $serial & " begin old=" & $oldPage & " target=" & $page)

	; 直接使用 Win32 ShowWindow 操作已存在的 WS_CHILD 分頁。
	; 避免 GUISetState 對 AutoIt 目前 GUI/事件佇列造成額外影響。
	If $oldPage >= 0 And $oldPage < $PG_COUNT And IsHWnd($g_pg[$oldPage]) Then
		_DebugTrace("SWITCH #" & $serial & " before HIDE old=" & $oldPage)
		Local $rHide = DllCall("user32.dll", "bool", "ShowWindow", "hwnd", $g_pg[$oldPage], "int", 0)
		Local $errHide = @error
		Local $hideRet = -1
		If IsArray($rHide) Then $hideRet = $rHide[0]
		_DebugTrace("SWITCH #" & $serial & " after HIDE callErr=" & $errHide & " ret=" & $hideRet)
	EndIf

	; 先登錄目前頁，讓 SHOW 同步產生的 WM_NOTIFY 知道新頁已生效。
	$g_iActivePage = $page
	$g_bDiagPageActive = ($page = $PG_DEBUG)
	$g_iDiagLoopRemain = 3
	_DebugTrace("SWITCH #" & $serial & " before SHOW new=" & $page)
	Local $rShow = DllCall("user32.dll", "bool", "ShowWindow", "hwnd", $g_pg[$page], "int", 4) ; SW_SHOWNOACTIVATE
	Local $errShow = @error
	Local $showRet = -1
	If IsArray($rShow) Then $showRet = $rShow[0]
	_DebugTrace("SWITCH #" & $serial & " after SHOW callErr=" & $errShow & " ret=" & $showRet)
	$g_bDebugPageGuard = False
	$g_bLvSelectionDirty = True ; 回到虛擬清單時由主迴圈重新核對真正選取列
	$g_bPageSwitchBusy = False
    $g_bListMenuDirty = True ; 切頁後僅刷新當前虛擬清單的選單狀態
	; 自繪側欄不會跟著 _ShowPage 自動同步：工具列按鈕與執行混淆切頁要明確同步。
	_SideSyncToPage($page)
	_DebugTrace("SWITCH #" & $serial & " complete active=" & $g_iActivePage)
EndFunc   ;==>_ShowPage

; 診斷記錄：每次開檔／寫入／關檔，作業系統已收到的資料可在意外終止後保留。
; 不操作 GUI，避免在 WM_NOTIFY / WM_DRAWITEM 內引發重繪遞迴。
Func _DiagStart()
	Local $h = FileOpen($g_sDebugTracePath, 2 + 256) ;;覆寫舊紀錄，UTF-8 無 BOM
	If $h <> -1 Then
		FileWrite($h, "Obscura v18.3.7 OWNERDATA caller-owned text buffer" & @CRLF)
		FileClose($h)
	EndIf
	_DebugTrace("START script=" & @ScriptFullPath & " AutoIt=" & @AutoItVersion & " PID=" & @AutoItPID & " x64=" & @AutoItX64)
	_DebugTrace("INFO 優先比對最後一筆 ENTER 和 EXIT；異常終止不一定會執行 EXIT handler")
EndFunc

Func _DebugTrace($message)
	If Not $g_bDebugTrace Or $g_bDiagLogBusy Then Return
	$g_bDiagLogBusy = True
	$g_iDiagSerial += 1
	Local $s = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & _
			" [" & StringFormat("%05d", $g_iDiagSerial) & "] " & $message
	Local $h = FileOpen($g_sDebugTracePath, 1 + 256) ;;附加，每筆立刻關檔
	If $h <> -1 Then
		FileWrite($h, $s & @CRLF)
		FileClose($h)
	EndIf
	ConsoleWrite("[ObscuraDiag] " & $s & @CRLF) ;;SciTE 輸出窗同步顯示
	$g_bDiagLogBusy = False
EndFunc

Func _DiagOnExit()
	_DebugTrace("EXIT normal handler exitCode=" & @exitCode & " exitMethod=" & @exitMethod)
	Local $i
	For $i = 0 To $g_iLogoBmp - 1 ;;釋放 _LogoPic 產生的 HBITMAP
		If $g_aLogoBmp[$i] Then _WinAPI_DeleteObject($g_aLogoBmp[$i])
	Next
EndFunc

; ==================================================================
;  左側「蘋果風」自繪側欄(取代原生 TreeView)
;  繪於主視窗客戶區 (S(8),S(142)) 起,緩衝 S(184)xS(560);
;  點擊沿用 _IsPressed + ScreenToClient 輪詢(與標題列按鈕同一套做法)。
; ==================================================================
Func _SideInit()
	; 幾何(依 DPI 縮放;皆為緩衝內部座標,原點 0,0)
	$g_sX = S(8)
	$g_sY = S(142)
	$g_sW = S(184)
	$g_sH = S(560)
	$g_rowH = S(32)
	$g_topPad = S(8)
	$g_pillL = S(4)
	$g_pillR = S(180)
	$g_rad = S(7)
	$g_sIndent = S(14)

	; 列資料:text | level(0/1/2) | isParent | expanded | pageConst
	_SideSetRow(0, "整合與混淆", 0, True, True, $PG_MAIN)
	_SideSetRow(1, "程式碼檢測", 1, False, False, $PG_DETECT)
	_SideSetRow(2, "執行情況", 1, False, False, $PG_EXEC)
	_SideSetRow(3, "參數設定", 1, True, True, $PG_PARAM)
	_SideSetRow(4, "腳本整合", 2, False, False, $PG_INTEG)
	_SideSetRow(5, "腳本混淆", 2, False, False, $PG_OBFUS)
	_SideSetRow(6, "多語言處理", 0, False, False, $PG_ML)
	_SideSetRow(7, "自我校驗", 0, False, False, $PG_SELF)
	_SideSetRow(8, "除錯輔助", 0, False, False, $PG_DEBUG)
	_SideSetRow(9, "程式碼轉換", 0, False, False, $PG_CONV)
	_SideSetRow(10, "設定", 0, False, False, $PG_LANG)
	_SideSetRow(11, "關於", 0, False, False, $PG_ABOUT)
	$g_sSelRow = 2 ;;預設:執行情況

	_GDIPlus_Startup()
	Local $hWDC = _WinAPI_GetDC($hMain)
	$g_sMemDC = _WinAPI_CreateCompatibleDC($hWDC)
	$g_sMemBmp = _WinAPI_CreateCompatibleBitmap($hWDC, $g_sW, $g_sH)
	_WinAPI_SelectObject($g_sMemDC, $g_sMemBmp)
	_WinAPI_ReleaseDC($hMain, $hWDC)

	$g_sGfx = _GDIPlus_GraphicsCreateFromHDC($g_sMemDC)
	_GDIPlus_GraphicsSetSmoothingMode($g_sGfx, 2)     ;;邊緣抗鋸齒
	_GDIPlus_GraphicsSetTextRenderingHint($g_sGfx, 5) ;;ClearType

	$g_sFam = _GDIPlus_FontFamilyCreate($font_name)
	$g_sFont = _GDIPlus_FontCreate($g_sFam, 12, 1, 3) ;;12pt 粗體,單位=點(左側導覽放大加粗)
	$g_sSF = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($g_sSF, 0)          ;;水平靠左
	_GDIPlus_StringFormatSetLineAlign($g_sSF, 1)      ;;垂直置中

	_SideMakeBrushes()
	_SideBuildVis()
	_SideRender()
	_SideBlit()
EndFunc   ;==>_SideInit

Func _SideSetRow($i, $t, $lvl, $isP, $exp, $pg)
	$g_srows[$i][0] = $t
	$g_srows[$i][1] = $lvl
	$g_srows[$i][2] = $isP
	$g_srows[$i][3] = $exp
	$g_srows[$i][4] = $pg
EndFunc   ;==>_SideSetRow

; 建立/更新筆刷:$g_sBrSel 隨主題色重建,其餘固定色只建一次
Func _SideMakeBrushes()
	If $g_sBrSel Then _GDIPlus_BrushDispose($g_sBrSel)
	$g_sBrSel = _GDIPlus_BrushCreateSolid($g_accent)
	If $g_sBrHov Then Return
	$g_sBrHov = _GDIPlus_BrushCreateSolid(0x14000000)    ;;hover:黑 8%
	$g_sBrSelTxt = _GDIPlus_BrushCreateSolid(0xFFFFFFFF) ;;選取白字
	$g_sBrTxt = _GDIPlus_BrushCreateSolid(0xFF1D1D1F)    ;;近黑字
	$g_sBrTxt2 = _GDIPlus_BrushCreateSolid(0xFF48484A)   ;;子項略淺
	$g_sBrChev = _GDIPlus_BrushCreateSolid(0xFF8E8E93)   ;;折疊箭頭灰
EndFunc   ;==>_SideMakeBrushes

Func _SideBuildVis()
	Local $v[0]
	For $i = 0 To UBound($g_srows) - 1
		Local $lvl = $g_srows[$i][1]
		Local $show = True
		If $lvl = 1 Then $show = $g_srows[0][3]                      ;;L1 需 row0(整合與混淆)展開
		If $lvl = 2 Then $show = ($g_srows[0][3] And $g_srows[3][3])  ;;L2 需 row0 與 row3(參數設定)展開
		If $show Then
			ReDim $v[UBound($v) + 1]
			$v[UBound($v) - 1] = $i
		EndIf
	Next
	$g_sVis = $v
EndFunc   ;==>_SideBuildVis

Func _SideRender()
	If Not $g_sGfx Then Return
	_GDIPlus_GraphicsClear($g_sGfx, 0xFFF5F5F7) ;;側欄灰底
	Local $y = $g_topPad
	For $vi = 0 To UBound($g_sVis) - 1
		Local $i = $g_sVis[$vi]
		Local $lvl = $g_srows[$i][1]
		Local $isP = $g_srows[$i][2]
		Local $seld = ($i = $g_sSelRow)
		Local $hov = ($i = $g_sHover) And Not $seld

		If $seld Then _SideFillRound($g_pillL, $y + S(2), $g_pillR - $g_pillL, $g_rowH - S(4), $g_rad * 2, $g_sBrSel)
		If $hov Then _SideFillRound($g_pillL, $y + S(2), $g_pillR - $g_pillL, $g_rowH - S(4), $g_rad * 2, $g_sBrHov)

		Local $chevX = $g_pillL + S(4) + $lvl * $g_sIndent
		Local $txtX = $chevX + S(16)
		If $isP Then
			Local $chev = $g_srows[$i][3] ? ChrW(0x25BE) : ChrW(0x25B8) ;;▾ 展開 / ▸ 收合
			_SideTxt($chev, $chevX, $y, S(14), $g_rowH, $seld ? $g_sBrSelTxt : $g_sBrChev)
		EndIf
		Local $br = $seld ? $g_sBrSelTxt : ($lvl >= 1 ? $g_sBrTxt2 : $g_sBrTxt)
		_SideTxt($g_srows[$i][0], $txtX, $y, $g_pillR - $txtX - S(2), $g_rowH, $br)

		$y += $g_rowH
	Next
EndFunc   ;==>_SideRender

Func _SideFillRound($x, $y, $w, $h, $d, $brush)
	Local $path = _GDIPlus_PathCreate()
	_GDIPlus_PathAddArc($path, $x, $y, $d, $d, 180, 90)
	_GDIPlus_PathAddArc($path, $x + $w - $d, $y, $d, $d, 270, 90)
	_GDIPlus_PathAddArc($path, $x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
	_GDIPlus_PathAddArc($path, $x, $y + $h - $d, $d, $d, 90, 90)
	_GDIPlus_PathCloseFigure($path)
	_GDIPlus_GraphicsFillPath($g_sGfx, $path, $brush)
	_GDIPlus_PathDispose($path)
EndFunc   ;==>_SideFillRound

Func _SideTxt($s, $x, $y, $w, $h, $brush)
	Local $rc = _GDIPlus_RectFCreate($x, $y, $w, $h)
	_GDIPlus_GraphicsDrawStringEx($g_sGfx, $s, $g_sFont, $rc, $g_sSF, $brush)
EndFunc   ;==>_SideTxt

Func _SideBlit()
	If Not $g_sMemDC Then Return
	Local $hDC = _WinAPI_GetDC($hMain)
	_WinAPI_BitBlt($hDC, $g_sX, $g_sY, $g_sW, $g_sH, $g_sMemDC, 0, 0, $SRCCOPY)
	_WinAPI_ReleaseDC($hMain, $hDC)
EndFunc   ;==>_SideBlit

Func _OnPaintSide($hWnd, $iMsg, $wParam, $lParam)
    #forceref $iMsg, $wParam, $lParam
    ; 不在此處 BeginPaint / EndPaint：那會吃掉整個主窗的 WM_PAINT，
    ; 導致失焦/還原時標題列留下未繪製區，甚至干擾子視窗標頭。
    If $hWnd = $hMain And $g_sMemDC Then $g_bSideNeedsRepaint = True
    Return $GUI_RUNDEFMSG
EndFunc   ;==>_OnPaintSide

Func _SideRowAt($cx, $cy)
	If $cx < 0 Or $cx >= $g_sW Or $cy < $g_topPad Or $cy >= $g_sH Then Return -1
	Local $idx = Int(($cy - $g_topPad) / $g_rowH)
	If $idx < 0 Or $idx >= UBound($g_sVis) Then Return -1
	Return $g_sVis[$idx]
EndFunc   ;==>_SideRowAt

Func _SideActivate($i, $clickX)
	Local $lvl = $g_srows[$i][1]
	Local $isP = $g_srows[$i][2]
	Local $chevRight = $g_pillL + S(4) + $lvl * $g_sIndent + S(16)
	If $isP And $clickX <= $chevRight Then ;;點箭頭 → 折疊/展開
		$g_srows[$i][3] = Not $g_srows[$i][3]
		_SideBuildVis()
	Else ;;點文字 → 選取並切頁
		$g_sSelRow = $i
		$g_iPendingSidePage = $g_srows[$i][4] ;;延遲切頁，避免重入視窗繪製
	EndIf
	_SideRender()
	_SideBlit()
EndFunc   ;==>_SideActivate

; v18.2: 所有程式化切頁統一更新 Apple 自繪側欄選取列。
; _ShowPage 會在 _SideInit 之前被呼叫一次，因此未初始化時只維持現有預設。
Func _SideSyncToPage($page)
	If Not $g_sMemDC Then Return
	Local $target = -1
	For $i = 0 To UBound($g_srows) - 1
		If $g_srows[$i][4] = $page Then
			$target = $i
			ExitLoop
		EndIf
	Next
	If $target < 0 Then Return
	If $g_sSelRow = $target Then Return
	; 目標項目可能因上層折疊而不可見，先展開對應層級。
	If $g_srows[$target][1] >= 1 And Not $g_srows[0][3] Then
		$g_srows[0][3] = True
		_SideBuildVis()
	EndIf
	If $g_srows[$target][1] = 2 And Not $g_srows[3][3] Then
		$g_srows[3][3] = True
		_SideBuildVis()
	EndIf
	$g_sSelRow = $target
	_SideRender()
	_SideBlit()
	_DebugTrace("SIDEBAR sync page=" & $page & " selectedRow=" & $target)
EndFunc

; 導覽切頁延遲至主事件迴圈，防止 GDI+ 側欄繪製與子視窗 WM_NOTIFY 重入
Func _ApplyPendingSidePage()
    If $g_iPendingSidePage < 0 Then Return
    Local $iPage = $g_iPendingSidePage
    $g_iPendingSidePage = -1
    If $iPage < 0 Or $iPage >= $PG_COUNT Then Return
    If $g_bPageSwitchBusy Or $g_bListPopulating Then
        $g_iPendingSidePage = $iPage
        Return
    EndIf
    If $iPage = $PG_DEBUG Then _DebugTrace("SIDEBAR before _ShowPage")
    _ShowPage($iPage)
    If $iPage = $PG_DEBUG Then _DebugTrace("SIDEBAR after _ShowPage")
EndFunc

; 主題色:將下拉選項名稱對應成 ARGB(白字可讀的 Apple 系統色)
Func _AccentARGB($name)
	Switch $name
		Case "靛"
			Return 0xFF5856D6
		Case "紫"
			Return 0xFFAF52DE
		Case "綠"
			Return 0xFF34C759
		Case "橙"
			Return 0xFFFF9500
		Case "紅"
			Return 0xFFFF3B30
		Case "灰"
			Return 0xFF8E8E93
		Case Else ;;藍(預設)
			Return 0xFF007AFF
	EndSwitch
EndFunc   ;==>_AccentARGB

Func _SideSetAccent()
	$g_accent = _AccentARGB(GUICtrlRead($g_cboAccent))
	; 主題色更動立即更新三個虛擬清單的選取反白，不重建控制項。
	_LvRefreshVirtualLists()
	If $g_sMemDC Then
		_SideMakeBrushes()
		_SideRender()
		_SideBlit()
	EndIf
EndFunc   ;==>_SideSetAccent

; ==================================================================
;  蘋果風按鈕(擁有者自繪:圓角/主色/按下/停用;保留原生點擊邏輯)
; ==================================================================
Func _AppleInit()
	_GDIPlus_Startup()
	$g_btnFam = _GDIPlus_FontFamilyCreate($font_name)
	If @error Then $g_btnFam = _GDIPlus_FontFamilyCreate("Microsoft JhengHei")
	$g_btnFont = _GDIPlus_FontCreate($g_btnFam, 11, 1, 3) ;;11pt 粗體,單位=點
	$g_btnSF = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($g_btnSF, 1)     ;;水平置中
	_GDIPlus_StringFormatSetLineAlign($g_btnSF, 1) ;;垂直置中
	GUIRegisterMsg(0x002B, "_OnDrawBtn") ;;WM_DRAWITEM:統一自繪所有擁有者繪製按鈕

	; 核取方塊/單選鈕:左對齊一般字 + 子類別回呼
	$g_cbFont = _GDIPlus_FontCreate($g_btnFam, 11, 0, 3)
	$g_cbSF = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($g_cbSF, 0)     ;;水平靠左
	_GDIPlus_StringFormatSetLineAlign($g_cbSF, 1) ;;垂直置中
	If $g_appleChk Then
		$g_hCbCb = DllCallbackRegister("_CbSubProc", "lresult", "hwnd;uint;wparam;lparam;uint_ptr;dword_ptr")
		$g_pCbProc = DllCallbackGetPtr($g_hCbCb)
	EndIf
EndFunc   ;==>_AppleInit

; 列舉所有核取方塊/單選鈕,掛上子類別重繪(建立完控制項後呼叫一次)
Func _AppleHookChecks()
	If Not $g_appleChk Or Not $g_pCbProc Then Return
	_HookChecks($hMain)
	For $i = 0 To $PG_COUNT - 1
		_HookChecks($g_pg[$i])
	Next
EndFunc   ;==>_AppleHookChecks

Func _HookChecks($hParent)
	Local $a = _WinAPI_EnumChildWindows($hParent, "Button")
	If Not IsArray($a) Then Return
	For $i = 1 To $a[0][0]
		Local $hC = $a[$i][0]
		Local $typ = BitAND(_WinAPI_GetWindowLong($hC, -16), 0x0F) ;;GWL_STYLE 低位=按鈕型別
		If $typ = 2 Or $typ = 3 Or $typ = 4 Or $typ = 9 Then ;;(自動)核取方塊/(自動)單選鈕
			_WinAPI_SetWindowSubclass($hC, $g_pCbProc, $hC, 0)
			_WinAPI_InvalidateRect($hC)
		EndIf
	Next
EndFunc   ;==>_HookChecks

; 子類別程序:攔截核取方塊/單選鈕的繪製,改畫 Apple 風(狀態仍由原生控制項持有)
Func _CbSubProc($hWnd, $iMsg, $wParam, $lParam, $iID, $pData)
	#forceref $iID, $pData
	Switch $iMsg
		Case 0x000F ; WM_PAINT
			_CbPaint($hWnd)
			Return 0
		Case 0x0014 ; WM_ERASEBKGND(由 _CbPaint 自行填底)
			Return 1
		Case 0x0082 ; WM_NCDESTROY
			_WinAPI_RemoveWindowSubclass($hWnd, $g_pCbProc, $iID)
	EndSwitch
	Return _WinAPI_DefSubclassProc($hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>_CbSubProc

Func _CbPaint($hWnd)
	Local $tPS = DllStructCreate($tagPAINTSTRUCT)
	Local $hDC = _WinAPI_BeginPaint($hWnd, $tPS)
	Local $tRC = _WinAPI_GetClientRect($hWnd)
	Local $w = DllStructGetData($tRC, "Right"), $h = DllStructGetData($tRC, "Bottom")
	Local $typ = BitAND(_WinAPI_GetWindowLong($hWnd, -16), 0x0F)
	Local $isRadio = ($typ = 4 Or $typ = 9)
	Local $checked = (_SendMessage($hWnd, 0x00F0) = 1) ;;BM_GETCHECK → BST_CHECKED
	Local $enabled = _WinAPI_IsWindowEnabled($hWnd)
	Local $txt = StringStripWS(_WinAPI_GetWindowText($hWnd), 1) ;;去開頭空白(原文字常有前導空格)

	Local $parent = _WinAPI_GetParent($hWnd)
	Local $bg = ($parent = $hMain) ? 0xFFF5F5F7 : 0xFFFFFFFF

	Local $g = _GDIPlus_GraphicsCreateFromHDC($hDC)
	_GDIPlus_GraphicsSetSmoothingMode($g, 2)
	_GDIPlus_GraphicsSetTextRenderingHint($g, 5)
	_GDIPlus_GraphicsClear($g, $bg)

	Local $gs = S(17)
	Local $gx = S(2), $gy = Int(($h - $gs) / 2)
	Local $accent = $enabled ? $g_accent : 0xFFC7C7CC
	Local $txtClr = $enabled ? 0xFF1D1D1F : 0xFFB0B0B5
	Local $bA, $bW, $pen ;;分支共用,避免重複 Local 宣告警告
	Local $penW = (S(2) < 2) ? 2 : S(2)

	If $isRadio Then
		If $checked Then
			$bA = _GDIPlus_BrushCreateSolid($accent)
			_GDIPlus_GraphicsFillEllipse($g, $gx, $gy, $gs, $gs, $bA)
			_GDIPlus_BrushDispose($bA)
			$bW = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
			_GDIPlus_GraphicsFillEllipse($g, $gx + $gs * 0.3, $gy + $gs * 0.3, $gs * 0.4, $gs * 0.4, $bW)
			_GDIPlus_BrushDispose($bW)
		Else
			$bW = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
			_GDIPlus_GraphicsFillEllipse($g, $gx, $gy, $gs, $gs, $bW)
			_GDIPlus_BrushDispose($bW)
			$pen = _GDIPlus_PenCreate(0xFFC7C7CC, 1)
			_GDIPlus_GraphicsDrawEllipse($g, $gx, $gy, $gs, $gs, $pen)
			_GDIPlus_PenDispose($pen)
		EndIf
	Else
		Local $d = S(5) * 2
		Local $path = _GDIPlus_PathCreate()
		_GDIPlus_PathAddArc($path, $gx, $gy, $d, $d, 180, 90)
		_GDIPlus_PathAddArc($path, $gx + $gs - $d, $gy, $d, $d, 270, 90)
		_GDIPlus_PathAddArc($path, $gx + $gs - $d, $gy + $gs - $d, $d, $d, 0, 90)
		_GDIPlus_PathAddArc($path, $gx, $gy + $gs - $d, $d, $d, 90, 90)
		_GDIPlus_PathCloseFigure($path)
		If $checked Then
			$bA = _GDIPlus_BrushCreateSolid($accent)
			_GDIPlus_GraphicsFillPath($g, $path, $bA)
			_GDIPlus_BrushDispose($bA)
			; 白色勾(兩段線)
			$pen = _GDIPlus_PenCreate(0xFFFFFFFF, $penW)
			_GDIPlus_GraphicsDrawLine($g, $gx + $gs * 0.26, $gy + $gs * 0.52, $gx + $gs * 0.44, $gy + $gs * 0.70, $pen)
			_GDIPlus_GraphicsDrawLine($g, $gx + $gs * 0.44, $gy + $gs * 0.70, $gx + $gs * 0.74, $gy + $gs * 0.30, $pen)
			_GDIPlus_PenDispose($pen)
		Else
			$bW = _GDIPlus_BrushCreateSolid(0xFFFFFFFF)
			_GDIPlus_GraphicsFillPath($g, $path, $bW)
			_GDIPlus_BrushDispose($bW)
			$pen = _GDIPlus_PenCreate(0xFFC7C7CC, 1)
			_GDIPlus_GraphicsDrawPath($g, $path, $pen)
			_GDIPlus_PenDispose($pen)
		EndIf
		_GDIPlus_PathDispose($path)
	EndIf

	Local $tx = $gx + $gs + S(8)
	Local $tb = _GDIPlus_BrushCreateSolid($txtClr)
	Local $rc = _GDIPlus_RectFCreate($tx, 0, $w - $tx - S(2), $h)
	_GDIPlus_GraphicsDrawStringEx($g, $txt, $g_cbFont, $rc, $g_cbSF, $tb)
	_GDIPlus_BrushDispose($tb)

	_GDIPlus_GraphicsDispose($g)
	_WinAPI_EndPaint($hWnd, $tPS)
EndFunc   ;==>_CbPaint

; 建立蘋果風按鈕(簽名同 GUICtrlCreateButton;加上 $BS_OWNERDRAW)
Func _AppleBtn($txt, $x, $y, $w, $h)
	Return GUICtrlCreateButton($txt, $x, $y, $w, $h, BitOR($BS_OWNERDRAW, $BS_NOTIFY, $WS_TABSTOP))
EndFunc   ;==>_AppleBtn

; 清單欄位標題列(ListBox 無原生表頭):在清單上方畫一條灰底標題條 + 欄位名稱。
; 傳入未縮放座標;$sTitles / $sXs 以 | 分隔,$sXs 為各欄相對清單左緣的 x(未縮放)。
Func _LvHeader($x, $y, $w, $sTitles, $sXs)
	Local $bg = GUICtrlCreateLabel("", S($x), S($y), S($w), S(22))
	GUICtrlSetBkColor($bg, 0xF1F2F5)
	Local $aT = StringSplit($sTitles, "|", 2)
	Local $aX = StringSplit($sXs, "|", 2)
	Local $i, $n = UBound($aT)
	For $i = 0 To $n - 1
		Local $cx = Number($aX[$i])
		Local $cw = ($i < $n - 1) ? (Number($aX[$i + 1]) - $cx - 6) : ($w - $cx - 6)
		Local $lbl = GUICtrlCreateLabel($aT[$i], S($x + $cx), S($y + 4), S($cw), S(16))
		GUICtrlSetBkColor($lbl, 0xF1F2F5)
		GUICtrlSetColor($lbl, 0x6E6E73)
		GUICtrlSetFont($lbl, 9, 600, 0, "Microsoft JhengHei UI")
	Next
EndFunc   ;==>_LvHeader

; 下拉選擇器:點 Apple 按鈕→以彈出選單列出(隱藏)combo 的項目;選取後回寫 combo 並更新按鈕文字。
; 原生 ComboBox 在本無邊框自繪視窗顯示異常,故以此法呈現「下拉框」外觀,資料仍存於 combo。
Func _DropPick($cbo, $btn)
	Local $hB = GUICtrlGetHandle($btn)
	Local $tR = _WinAPI_GetWindowRect($hB)
	Local $x = DllStructGetData($tR, "Left"), $y = DllStructGetData($tR, "Bottom")
	Local $cnt = _GUICtrlComboBox_GetCount($cbo)
	If $cnt < 1 Then Return -1
	Local $cur = _GUICtrlComboBox_GetCurSel($cbo)
	Local $hMenu = _GUICtrlMenu_CreatePopup()
	Local $i, $s
	For $i = 0 To $cnt - 1
		$s = ""
		_GUICtrlComboBox_GetLBText($cbo, $i, $s)
		_GUICtrlMenu_AddMenuItem($hMenu, TR($s), $i + 1) ;;選單顯示文字依介面語言轉換(選取仍以索引對應,不影響值)
		If $i = $cur Then _GUICtrlMenu_SetItemChecked($hMenu, $i, True)
	Next
	; 第7參數=2 → TPM_RETURNCMD:直接回傳選取 id,不送 WM_COMMAND(避免選單 id 與控制項 id 撞號導致閃退);第8=0 → 左鍵
	Local $sel = _GUICtrlMenu_TrackPopupMenu($hMenu, $hMain, $x, $y, 1, 1, 2, 0)
	_GUICtrlMenu_DestroyMenu($hMenu)
	If $sel <= 0 Then Return -1
	Local $idx = $sel - 1
	If $idx = $cur Then Return -1
	_GUICtrlComboBox_SetCurSel($cbo, $idx)
	_DropSyncOne($cbo, $btn)
	Return $idx
EndFunc   ;==>_DropPick

; 依 combo 目前選取值更新按鈕顯示文字(值 + ▾)
Func _DropSyncOne($cbo, $btn)
	If Not $btn Then Return
	Local $idx = _GUICtrlComboBox_GetCurSel($cbo)
	If $idx < 0 Then Return
	Local $s = ""
	_GUICtrlComboBox_GetLBText($cbo, $idx, $s)
	GUICtrlSetData($btn, TR($s) & "  " & ChrW(0x25BE)) ;;TR:简体介面時顯示轉简(值仍存 combo,邏輯比對不受影響)
EndFunc   ;==>_DropSyncOne

; 設定載入後,把所有下拉按鈕文字同步成 combo 目前值
Func _DropSync()
	_DropSyncOne($g_cboLang, $g_btnLangDrop)
	_DropSyncOne($g_cboAccent, $g_btnAccentDrop)
	_DropSyncOne($g_cboEnc, $g_btnEncDrop)
	_DropSyncOne($g_cboInteg, $g_btnIntegDrop)
	_DropSyncOne($g_cboMLMode, $g_btnMLModeDrop)
	_DropSyncOne($g_cboMLFilter, $g_btnMLFilterDrop)
EndFunc   ;==>_DropSync

; 顏色加深(保留 Alpha);$f 介於 0~1
Func _Darken($argb, $f)
	Local $a = BitAND(BitShift($argb, 24), 0xFF)
	Local $r = Int(BitAND(BitShift($argb, 16), 0xFF) * $f)
	Local $g = Int(BitAND(BitShift($argb, 8), 0xFF) * $f)
	Local $b = Int(BitAND($argb, 0xFF) * $f)
	Return BitOR(BitShift($a, -24), BitShift($r, -16), BitShift($g, -8), $b)
EndFunc   ;==>_Darken

Func _OnDrawBtn($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $bDrawLog = ($g_bDiagPageActive And Not $g_bPageSwitchBusy And $g_iDiagDrawCount < 3)
	If $bDrawLog Then
		$g_iDiagDrawCount += 1
		_DebugTrace("OWNERDRAW button #" & $g_iDiagDrawCount & " ENTER")
	EndIf
	Local $t = DllStructCreate($tagDRAWITEMSTRUCT_APPLE, $lParam)
	Local $ctlType = DllStructGetData($t, "CtlType")
	If $ctlType = 2 Then Return _OnDrawListItem($t) ;;ODT_LISTBOX=2 → 自繪清單列
	If $ctlType <> 4 Then Return $GUI_RUNDEFMSG ;;ODT_BUTTON=4
	Local $hItem = DllStructGetData($t, "hItem")
	Local $hDC = DllStructGetData($t, "hDC")
	Local $st = DllStructGetData($t, "itemState")
	Local $l = DllStructGetData($t, "rL"), $tp = DllStructGetData($t, "rT")
	Local $r = DllStructGetData($t, "rR"), $b = DllStructGetData($t, "rB")
	Local $w = $r - $l, $h = $b - $tp
	If $w < 2 Or $h < 2 Then Return 1

	Local $pressed = (BitAND($st, 0x0001) <> 0)
	Local $disabled = (BitAND($st, 0x0004) <> 0)
	Local $txt = _WinAPI_GetWindowText($hItem)
	Local $isStop = ($txt = "中止")
	Local $primary = ($txt = "執行混淆" Or $txt = "执行混淆" Or $isStop) ;;執行中仍明顯顯示主操作狀態

	; 角落填回父視窗底色(主視窗灰、分頁白),避免圓角殘留毛邊
	Local $bg = (_WinAPI_GetParent($hItem) = $hMain) ? 0xFFF5F5F7 : 0xFFFFFFFF

	Local $fill, $fg, $drawBorder = False
	If $disabled Then
		$fill = 0xFFF0F0F2
		$fg = 0xFFB0B0B5
		$drawBorder = Not $primary
	ElseIf $primary Then
		; 中止按鈕使用醒目紅色，和預設的主題色混淆按鈕區分。
		If $isStop Then
			$fill = $pressed ? 0xFFD9342D : 0xFFFF453A
		Else
			$fill = $pressed ? _Darken($g_accent, 0.82) : $g_accent
		EndIf
		$fg = 0xFFFFFFFF
	Else
		$fill = $pressed ? 0xFFE6E6EB : 0xFFF7F7F9
		$fg = 0xFF1D1D1F
		$drawBorder = True
	EndIf

	Local $g = _GDIPlus_GraphicsCreateFromHDC($hDC)
	_GDIPlus_GraphicsSetSmoothingMode($g, 2)
	_GDIPlus_GraphicsSetTextRenderingHint($g, 5)
	_GDIPlus_GraphicsClear($g, $bg)

	Local $d = S(6) * 2
	Local $bx = $l + 1, $by = $tp + 1, $bw = $w - 2, $bh = $h - 2
	If $d > $bw Then $d = $bw
	If $d > $bh Then $d = $bh
	Local $path = _GDIPlus_PathCreate()
	_GDIPlus_PathAddArc($path, $bx, $by, $d, $d, 180, 90)
	_GDIPlus_PathAddArc($path, $bx + $bw - $d, $by, $d, $d, 270, 90)
	_GDIPlus_PathAddArc($path, $bx + $bw - $d, $by + $bh - $d, $d, $d, 0, 90)
	_GDIPlus_PathAddArc($path, $bx, $by + $bh - $d, $d, $d, 90, 90)
	_GDIPlus_PathCloseFigure($path)

	Local $br = _GDIPlus_BrushCreateSolid($fill)
	_GDIPlus_GraphicsFillPath($g, $path, $br)
	If $drawBorder Then
		Local $pen = _GDIPlus_PenCreate(0xFFD6D6DB, 1)
		_GDIPlus_GraphicsDrawPath($g, $path, $pen)
		_GDIPlus_PenDispose($pen)
	EndIf

	Local $tbr = _GDIPlus_BrushCreateSolid($fg)
	Local $rc = _GDIPlus_RectFCreate($l, $tp, $w, $h)
	_GDIPlus_GraphicsDrawStringEx($g, $txt, $g_btnFont, $rc, $g_btnSF, $tbr)

	_GDIPlus_BrushDispose($tbr)
	_GDIPlus_BrushDispose($br)
	_GDIPlus_PathDispose($path)
	_GDIPlus_GraphicsDispose($g)
	If $bDrawLog Then _DebugTrace("OWNERDRAW button EXIT")
	Return 1
EndFunc   ;==>_OnDrawBtn

; 自繪清單列(owner-draw ListBox,ODT_LISTBOX)。選取狀態直接由 DRAWITEMSTRUCT 提供,
; 不需任何追蹤;選取列=主題色底白字,其餘斑馬紋。走 WM_DRAWITEM,避開會卡的 NM_CUSTOMDRAW。
Func _OnDrawListItem($t)
	Local $hItem = DllStructGetData($t, "hItem")
	Local $hDC = DllStructGetData($t, "hDC")
	Local $id = DllStructGetData($t, "itemID")
	Local $st = DllStructGetData($t, "itemState")
	Local $l = DllStructGetData($t, "rL"), $tp = DllStructGetData($t, "rT")
	Local $r = DllStructGetData($t, "rR"), $b = DllStructGetData($t, "rB")
	If $id < 0 Then Return 1 ;;空清單
	Local $w = $r - $l, $h = $b - $tp
	If $w < 2 Or $h < 1 Then Return 1
	Local $selected = (BitAND($st, 0x0001) <> 0) ;;ODS_SELECTED

	Local $txt = _GUICtrlListBox_GetText($hItem, $id)
	Local $aCol = StringSplit($txt, @TAB)

	Local $bgc = $selected ? $g_accent : ((Mod($id, 2) = 0) ? 0xFFFFFFFF : 0xFFF7F7F9)
	Local $fgc = $selected ? 0xFFFFFFFF : 0xFF1D1D1F

	Local $g = _GDIPlus_GraphicsCreateFromHDC($hDC)
	_GDIPlus_GraphicsSetTextRenderingHint($g, 5)
	Local $brBg = _GDIPlus_BrushCreateSolid($bgc)
	_GDIPlus_GraphicsFillRect($g, $l, $tp, $w, $h, $brBg)
	_GDIPlus_BrushDispose($brBg)

	; 依來源清單決定欄位的 X 起點與寬度（相對列左緣 $l）。
	;   檢測：行號 / 內容（2 欄）
	;   多語言：索引 / 字串（2 欄）
	;   除錯：實際行號 / 內部行號 / 內容（3 欄）
	Local $colX[3], $colW[3], $ncol
	If $hItem = GUICtrlGetHandle($g_lvDbg) Then
		$ncol = 3
		$colX[0] = S(8)
		$colW[0] = S(76)
		$colX[1] = S(92)
		$colW[1] = S(120)
		$colX[2] = S(220)
		$colW[2] = $w - S(228)
	ElseIf $hItem = GUICtrlGetHandle($g_lvML) Then
		$ncol = 2
		$colX[0] = S(8)
		$colW[0] = S(52)
		$colX[1] = S(68)
		$colW[1] = $w - S(76)
	Else ;;檢測
		$ncol = 2
		$colX[0] = S(8)
		$colW[0] = S(56)
		$colX[1] = S(70)
		$colW[1] = $w - S(78)
	EndIf

	Local $brFg = _GDIPlus_BrushCreateSolid($fgc)
	Local $c
	For $c = 0 To $ncol - 1
		If $aCol[0] < $c + 1 Then ExitLoop
		If $colW[$c] < 2 Then ContinueLoop
		Local $rc = _GDIPlus_RectFCreate($l + $colX[$c], $tp, $colW[$c], $h)
		_GDIPlus_GraphicsDrawStringEx($g, $aCol[$c + 1], $g_cbFont, $rc, $g_cbSF, $brFg)
	Next
	_GDIPlus_BrushDispose($brFg)
	_GDIPlus_GraphicsDispose($g)
	Return 1
EndFunc   ;==>_OnDrawListItem

; 依主選項的勾選狀態,把未啟用的子（進階）選項反灰停用
Func _SyncDeps()
	Local $on
	; UDF 函式混淆 → 函式混淆進階 / UDF 函式亂序排列
	$on = (GUICtrlRead($g_oUdf) = $GUI_CHECKED)
	GUICtrlSetState($g_oUdfAdv, $on ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($g_oUdfShuf, $on ? $GUI_ENABLE : $GUI_DISABLE)
	; 變數混淆 → 變數混淆進階
	$on = (GUICtrlRead($g_oVar) = $GUI_CHECKED)
	GUICtrlSetState($g_oVarAdv, $on ? $GUI_ENABLE : $GUI_DISABLE)
	; 數字加密 → 數字加密強化（連負號隱藏）
	$on = (GUICtrlRead($g_oNum) = $GUI_CHECKED)
	GUICtrlSetState($g_oNegNum, $on ? $GUI_ENABLE : $GUI_DISABLE)
	; 字串「加密處理」→ 加密強化（金鑰隨位置變動）
	$on = (GUICtrlRead($g_rStrEnc) = $GUI_CHECKED)
	GUICtrlSetState($g_oStrAdv, $on ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc   ;==>_SyncDeps

 ; ==================================================================
; v15: 按鈕事件橋接（GUIGetMsg + WM_COMMAND，不在 Win32 回呼內執行功能）
; ==================================================================
Func _ButtonBridgeInit()
	$g_iBtnBridgeCount = 0
	For $i = 0 To UBound($g_btn) - 1
		_ButtonBridgeAdd($g_btn[$i])
	Next
	For $i = 0 To UBound($g_detBtn) - 1
		_ButtonBridgeAdd($g_detBtn[$i])
	Next
	For $i = 0 To UBound($g_mlBtn) - 1
		_ButtonBridgeAdd($g_mlBtn[$i])
	Next
	For $i = 0 To UBound($g_dbgBtn) - 1
		_ButtonBridgeAdd($g_dbgBtn[$i])
	Next
	For $i = 0 To UBound($g_convBtn) - 1
		_ButtonBridgeAdd($g_convBtn[$i])
	Next
	Local $extra[20] = [$g_selBtn, $g_selBtnChk, $g_selBtnRead, $g_btnPreMax, $g_btnPreStd, _
			$g_btnBrowseSciTE, $g_btnBrowseStd, $g_btnBrowseAu3Check, $g_btnTC2SC, $g_btnSC2TC, _
			$g_btnCfgExport, $g_btnCfgImport, $g_btnLangDrop, $g_btnAccentDrop, _
			$g_btnEncDrop, $g_btnIntegDrop, $g_btnMLModeDrop, $g_btnMLFilterDrop]
	For $i = 0 To UBound($extra) - 1
		_ButtonBridgeAdd($extra[$i])
	Next
	_DebugTrace("BUTTON bridge initialized count=" & $g_iBtnBridgeCount)
EndFunc

Func _ButtonBridgeAdd($id)
	If $id <= 0 Or $g_iBtnBridgeCount >= UBound($g_aBtnBridge) Then Return
	Local $hCtl = GUICtrlGetHandle($id)
	If Not IsHWnd($hCtl) Then Return
	For $i = 0 To $g_iBtnBridgeCount - 1
		If $g_aBtnBridge[$i][1] = $id Then Return
	Next
	$g_aBtnBridge[$g_iBtnBridgeCount][0] = $hCtl
	$g_aBtnBridge[$g_iBtnBridgeCount][1] = $id
	$g_iBtnBridgeCount += 1
EndFunc

; $WM_COMMAND 的 BN_CLICKED=0；只追蹤已註冊 Apple 按鈕，選單及其他控制項照舊。
Func _OnAppleCommand($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg
	If $lParam = 0 Then Return $GUI_RUNDEFMSG ;;選單項目不是按鈕
	Local $nCode = BitAND(BitShift($wParam, 16), 0xFFFF)
	If $nCode = 2 Then ;;LBN_DBLCLK:owner-draw ListBox 雙擊→延後到主迴圈開啟該行(回呼內不呼叫 Run/SciTE)
		If $lParam = GUICtrlGetHandle($g_lvDetect) Then $g_iLvPendingDouble = 1
		If $lParam = GUICtrlGetHandle($g_lvML) Then $g_iLvPendingDouble = 2
		If $lParam = GUICtrlGetHandle($g_lvDbg) Then $g_iLvPendingDouble = 3
		Return $GUI_RUNDEFMSG
	EndIf
	If $nCode <> 0 Then Return $GUI_RUNDEFMSG
	For $i = 0 To $g_iBtnBridgeCount - 1
		If $lParam <> $g_aBtnBridge[$i][0] Then ContinueLoop
		$g_iBtnCommandSerial += 1
		; 執行中的新點擊才是「中止」，剛剛啟動混淆的 BN_CLICKED 不算。
		If $g_bRunBusy And $g_stopBtn <> 0 And $g_aBtnBridge[$i][1] = $g_stopBtn Then
			$g_iRunStopClickSerial += 1
			; 執行中不再將「中止」加入主迴圈備援佇列，避免完成後重新執行混淆。
			Return $GUI_RUNDEFMSG
		EndIf
		If $g_iBtnPendingCount < UBound($g_aBtnPending) Then
			$g_aBtnPending[$g_iBtnPendingCount][0] = $g_aBtnBridge[$i][1]
			$g_aBtnPending[$g_iBtnPendingCount][1] = $g_iBtnCommandSerial
			$g_iBtnPendingCount += 1
		EndIf
		ExitLoop
	Next
	Return $GUI_RUNDEFMSG ;;必須讓 AutoIt 自己的 GUIGetMsg 繼續處理
EndFunc

Func _ButtonBridgeDropAt($idx)
	If $idx < 0 Or $idx >= $g_iBtnPendingCount Then Return
	For $i = $idx To $g_iBtnPendingCount - 2
		$g_aBtnPending[$i][0] = $g_aBtnPending[$i + 1][0]
		$g_aBtnPending[$i][1] = $g_aBtnPending[$i + 1][1]
	Next
	$g_iBtnPendingCount -= 1
EndFunc

Func _ButtonBridgeIsKnown($id)
	For $i = 0 To $g_iBtnBridgeCount - 1
		If $g_aBtnBridge[$i][1] = $id Then Return True
	Next
	Return False
EndFunc

; 正常 AutoIt 事件優先；AutoIt 沒有收到 BN_CLICKED 才從備援佇列補送。
; 一律在主事件迴圈操作，不從 WM_COMMAND 回呼呼叫任何功能。
Func _ButtonBridgePoll($nativeMsg)
	If $nativeMsg > 0 And _ButtonBridgeIsKnown($nativeMsg) Then
		For $i = 0 To $g_iBtnPendingCount - 1
			If $g_aBtnPending[$i][0] = $nativeMsg Then
				_ButtonBridgeDropAt($i)
				ExitLoop
			EndIf
		Next
		; 備援已執行，AutoIt 延後送來同一次點擊的事件，避免重複執行。
		If $nativeMsg = $g_iBtnLastFallbackId And $g_iBtnLastFallbackSerial = $g_iBtnCommandSerial And _
				$g_tBtnLastFallback <> 0 And TimerDiff($g_tBtnLastFallback) < 300 Then
			_DebugTrace("BUTTON late native duplicate ignored id=" & $nativeMsg)
			Return 0
		EndIf
		_DebugTrace("BUTTON native id=" & $nativeMsg & " caption=" & _WinAPI_GetWindowText(GUICtrlGetHandle($nativeMsg)))
		Return $nativeMsg
	EndIf
	; 不覆蓋其他正值事件（含右鍵選單、設定、勾選、下拉選項）。
	If $nativeMsg > 0 Or $g_iBtnPendingCount = 0 Then Return $nativeMsg
	; 關閉、拖放、視窗狀態事件優先，不可被備援按鈕覆蓋。
	If $nativeMsg < 0 And $nativeMsg <> $GUI_EVENT_PRIMARYUP And $nativeMsg <> $GUI_EVENT_PRIMARYDOWN Then Return $nativeMsg
	Local $id = $g_aBtnPending[0][0], $seq = $g_aBtnPending[0][1]
	_ButtonBridgeDropAt(0)
	Local $hCtl = GUICtrlGetHandle($id)
	If Not IsHWnd($hCtl) Or Not _WinAPI_IsWindowEnabled($hCtl) Then Return $nativeMsg
	$g_iBtnLastFallbackId = $id
	$g_iBtnLastFallbackSerial = $seq
	$g_tBtnLastFallback = TimerInit()
	_DebugTrace("BUTTON WM_COMMAND fallback id=" & $id & " caption=" & _WinAPI_GetWindowText($hCtl) & " page=" & $g_iActivePage)
	Return $id
EndFunc

; ==================================================================
;  事件迴圈
; ==================================================================
Func _Loop()
	Local $f = ""
	$g_sWasDown = _IsPressed("01") ;;先讀一次滑鼠左鍵狀態,避免啟動瞬間誤判為點擊
	While 1
		If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP enter remaining=" & $g_iDiagLoopRemain)
		Local $msg = _ButtonBridgePoll(GUIGetMsg())
		If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP after GUIGetMsg/bridge msg=" & $msg)
		If $msg = $GUI_EVENT_CLOSE Then
			_CfgSave() ;;關閉前存檔
			ExitLoop
		EndIf

		; 自繪標題列按鈕備援:即使標籤/子視窗攔截 WM_COMMAND 仍能回應
		If _TitleButtonsPoll() Then ContinueLoop
		_PollTree()
		If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP after PollTree")
		_ApplyPendingSidePage()
        If $g_bSideNeedsRepaint And $g_sMemDC And Not $g_bPageSwitchBusy Then
            $g_bSideNeedsRepaint = False
            _SideBlit()
        EndIf
		; 在 WM_NOTIFY 之外核對 LVIS_SELECTED，避免自繪時同步查詢清單。
		; (_LvCheckActiveHeader 已移除:清單全改 ListBox/手繪標題,原生表頭不再需要處理)
		_LvSyncSelections()
		_LvHandlePendingDouble()
		_LvFlushSafeCounters()
		If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP after ApplyPendingSidePage")
		If $g_bListMenuDirty And Not $g_bListPopulating Then
			$g_bListMenuDirty = False
			If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP before LvUpdMenus")
			_LvUpdMenus()
			If $g_iDiagLoopRemain > 0 Then _DebugTrace("LOOP after LvUpdMenus")
		EndIf

		If $g_doBatch Then ;;拖入多檔 → 批次處理
			$g_doBatch = False
			_AskRunBatch()
		EndIf

		If $msg > 0 And Not _ButtonBridgeIsKnown($msg) Then _DebugTrace("CONTROL native id=" & $msg & " page=" & $g_iActivePage)
		Switch $msg
			Case 0
				; 無事件
			Case $GUI_EVENT_DROPPED
				$f = @GUI_DragFile
				Switch @GUI_DropId
					Case $g_inMain
						_SetScript($f)
					Case $g_inDbgFile
						GUICtrlSetData($g_inDbgFile, $f)
					Case $g_inConvFile
						GUICtrlSetData($g_inConvFile, $f)
				EndSwitch

			Case $g_chkTop
				WinSetOnTop($hMain, "", (GUICtrlRead($g_chkTop) = $GUI_CHECKED) ? 1 : 0)
			Case $g_lnkBrand
				ShellExecute("https://grayfree.tw")
			Case $g_lnkGit
				ShellExecute("https://github.com/Hiura-Souji/Au3Obscura")
			Case $g_lnkSpon
				ShellExecute("https://portaly.cc/grayfree/support")
			Case $g_btn[0]
				$f = FileOpenDialog("選擇腳本", @ScriptDir, "AutoIt 腳本 (*.au3)|所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then _SetScript($f)
			Case $g_btn[1]
				_ShowPage($PG_DETECT)
			Case $g_btn[2]
				_RunProcess(False)
			Case $g_btn[3]
				_DebugTrace("RUN CLICK button=執行混淆 id=" & $msg & " source=" & $g_script)
				_RunProcess(True)
			Case $g_btn[4]
				_ShowPage($PG_EXEC)
			Case $g_btn[5]
				If $g_script <> "" Then ShellExecute(_DirOf($g_script))
			Case $g_btn[6]
				If $g_script <> "" Then ShellExecute($g_script)

			Case $g_detBtn[0]
				_DetectExport()
			Case $g_detBtn[1]
				_DebugTrace("ACTION 檢測函式 begin")
				_Detect("func")
				_DebugTrace("ACTION 檢測函式 end")
			Case $g_detBtn[2]
				_DebugTrace("ACTION 檢測變數 begin")
				_Detect("var")
				_DebugTrace("ACTION 檢測變數 end")
			Case $g_detBtn[3]
				_DebugTrace("ACTION 檢測字串 begin")
				_Detect("str")
				_DebugTrace("ACTION 檢測字串 end")
			Case $g_detBtn[4]
				_DebugTrace("ACTION 檢測特殊 begin")
				_Detect("special")
				_DebugTrace("ACTION 檢測特殊 end")
			Case $g_detBtn[5]
				_DebugTrace("ACTION 全部檢測 begin")
				_DetectAll()
				_DebugTrace("ACTION 全部檢測 end")
			Case $g_lvDetect
				_DetectShowLocate()
			Case $g_mnuDetCopy
				_DebugTrace("ACTION DETECT copy menu")
				_LvCopySel($g_lvDetect, $g_detData)
			Case $g_mnuDetOpen
				_OpenAtLine($g_lvDetect, $g_detData)
			Case $g_mnuDetExport
				_DetectExport()

			Case $g_mlBtn[0]
				_MLDetect()
			Case $g_mlBtn[1]
				_MLRun()
			Case $g_mlBtn[2], $g_mnuMLRestore
				_MLRestore()
			Case $g_lvML
				_MLShowLocate()
			Case $g_mnuMLCopy
				_LvCopySel($g_lvML, $g_mlData)
			Case $g_mnuMLOpen
				_OpenAtLine($g_lvML, $g_mlData)

			Case $g_btnBrowseSciTE
				$f = FileOpenDialog("選擇 SciTE.exe", @ScriptDir, "執行檔 (*.exe)|所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then GUICtrlSetData($g_inSciTE, $f)
			Case $g_btnBrowseStd
				$f = FileSelectFolder("選擇 AutoIt 標準庫 Include 資料夾", "", 0, GUICtrlRead($g_inStd), $hMain)
				If Not @error Then GUICtrlSetData($g_inStd, $f)
			Case $g_btnBrowseAu3Check
				$f = FileOpenDialog("選擇 AU3Check.exe", @ScriptDir, "執行檔 (*.exe)|所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then GUICtrlSetData($g_inAu3Check, $f)
			Case $g_btnTC2SC
				_LangConvertScript(True)
			Case $g_btnSC2TC
				_LangConvertScript(False)
			Case $g_btnCfgExport
				_CfgExport()
			Case $g_btnCfgImport
				_CfgImport()
			Case $g_btnLangDrop
				If _DropPick($g_cboLang, $g_btnLangDrop) >= 0 Then
					_CfgSave() ;;先存語言設定
					If (GUICtrlRead($g_cboLang) = "简体中文") <> $g_uiSimp Then _
							_Msg(64, "語種切換", "介面語言已設定為「" & GUICtrlRead($g_cboLang) & "」，" & @CRLF & "請重新啟動程式以套用。")
				EndIf
			Case $g_btnAccentDrop
				If _DropPick($g_cboAccent, $g_btnAccentDrop) >= 0 Then
					_SideSetAccent() ;;即時套用主題色到側欄選取膠囊
					_CfgSave()
				EndIf

			Case $g_btnEncDrop
				If _DropPick($g_cboEnc, $g_btnEncDrop) >= 0 Then _CfgSave()
			Case $g_btnIntegDrop
				If _DropPick($g_cboInteg, $g_btnIntegDrop) >= 0 Then _CfgSave()
			Case $g_btnMLModeDrop
				If _DropPick($g_cboMLMode, $g_btnMLModeDrop) >= 0 Then _CfgSave()
			Case $g_btnMLFilterDrop
				If _DropPick($g_cboMLFilter, $g_btnMLFilterDrop) >= 0 Then _CfgSave()
			Case $g_btnPreMax
				_PresetMax()
			Case $g_btnPreStd
				_PresetStd()
			Case $g_selBtn
				_SelfGen()
			Case $g_selBtnChk
				_CertCheck()
			Case $g_selBtnRead
				_CertRead()

			Case $g_dbgBtn[0]
				_DebugTrace("ACTION choose debug source")
				$f = FileOpenDialog("選擇腳本", @ScriptDir, "AutoIt 腳本 (*.au3)|所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then GUICtrlSetData($g_inDbgFile, $f)
			Case $g_dbgBtn[1]
				_DebugTrace("ACTION before DebugMap")
				_DebugMap()
				_DebugTrace("ACTION after DebugMap")
			Case $g_dbgBtn[2]
				_DebugTrace("ACTION export debug list")
				_DbgExport()
			Case $g_dbgBtn[3]
				_DebugTrace("ACTION open diagnostic log")
				If FileExists($g_sDebugTracePath) Then ShellExecute($g_sDebugTracePath)

			Case $g_convBtn[0]
				$f = FileOpenDialog("選擇檔案", @ScriptDir, "所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then GUICtrlSetData($g_inConvFile, $f)
			Case $g_convBtn[1]
				$f = FileOpenDialog("載入檔案", @ScriptDir, "所有檔案 (*.*)", 3, "", $hMain)
				If Not @error Then
					GUICtrlSetData($g_inConvFile, $f)
					_ConvFromFile($f)
				EndIf
			Case $g_convBtn[2]
				$g_sConvCode = "" ;;清空最近結果
				If $g_hSci Then _SciSetText($g_hSci, "")
				_Status("已清空轉換結果。")
			Case $g_convBtn[3]
				_ConvRun()
			Case $g_convBtn[4]
				_ConvCopy()
			Case $g_convBtn[5]
				_ConvSave()
			Case $g_convBtn[6]
				If $g_sConvCode <> "" Then
					_ConvShowResult($g_sConvCode)
				Else
					_Msg(48, "提示", "尚無轉換結果，請先『轉換』或『載入檔案』。")
				EndIf
		EndSwitch

		If $g_iDiagLoopRemain > 0 Then
			_DebugTrace("LOOP end msg=" & $msg)
			$g_iDiagLoopRemain -= 1
		EndIf
		If $msg > 0 Then
			; 不可在每個功能按鈕/右鍵選單事件後重寫整份設定：會造成介面卡頓
			; 僅在設定控制項變更時同步依賴與儲存；關閉視窗仍完整儲存。
			If _IsConfigControl($msg) Then
				_SyncDeps()
				_CfgSave()
			EndIf
		EndIf
	WEnd
EndFunc   ;==>_Loop


; 僅設定項目需要即時儲存。GUI 按鈕、ListView 與右鍵選單不可觸發整份 INI 寫入。
Func _IsConfigControl($id)
	Local $a = _CfgCtrls()
	For $i = 0 To UBound($a) - 1
		If $id = $a[$i][1] Then Return True
	Next
	Return False
EndFunc

; 詢問是否批次混淆拖入的多個檔案
Func _AskRunBatch()
	Local $n = UBound($g_batchFiles)
	If $n < 1 Then Return
	; 是=批次混淆, 否=批次整合, 取消=只載入第一個
	Local $ans = _Choose3("批次處理", "偵測到 " & $n & " 個檔案，要如何處理？", "全部混淆", "全部整合", "只載入第一個")
	Switch $ans
		Case 1 ;；全部批次混淆
			_RunBatch(True)
		Case 2 ;；全部批次整合
			_RunBatch(False)
		Case Else ;；關閉 / Esc → 只載入第一個
			_SetScript($g_batchFiles[0], False)
	EndSwitch
EndFunc   ;==>_AskRunBatch

; 依目前設定,逐一處理清單中的每個檔案($obf:True=混淆 False=整合)
Func _RunBatch($obf)
	Local $ok = 0, $fail = 0, $i, $n = UBound($g_batchFiles)
	Local $act = $obf ? "混淆" : "整合"
	$g_batch = True
	For $i = 0 To $n - 1
		_SetScript($g_batchFiles[$i], False)
		_Status("批次" & $act & " " & ($i + 1) & "/" & $n & ":" & _NameOf($g_batchFiles[$i]))
		If $g_script <> "" And FileExists($g_script) Then
			$g_bLastRunOk = False
			_RunProcess($obf)
			If $g_stop Then ExitLoop ;;使用者中止 → 停止整批
			If $g_bLastRunOk Then
				$ok += 1
			Else
				$fail += 1
				_LogLine("批次失敗：" & $g_batchFiles[$i] & "，原因：" & $g_sLastOutputError)
			EndIf
		Else
			$fail += 1
		EndIf
	Next
	$g_batch = False
	_Msg(64, "批次完成", "批次" & $act & "結束：成功 " & $ok & " 個" & ($fail ? ("，失敗 " & $fail & " 個") : "") & "。" & _
			($g_stop ? (@CRLF & "（已中止，未處理完全部）") : ""))
EndFunc   ;==>_RunBatch

Func _SetScript($f, $warn = True)
	If Not FileExists($f) Then Return
	If $warn And StringRight(StringLower($f), 4) <> ".au3" Then
		If _Msg(BitOR(4, 48), "非 .au3 檔", "此檔副檔名不是 .au3:" & @CRLF & $f & @CRLF & @CRLF & "仍要載入嗎？") <> 6 Then Return
	EndIf
	$g_script = $f
	GUICtrlSetData($g_inMain, $f)
	GUICtrlSetBkColor($g_inMain, 0xEAF7EA) ;;拖放/載入回饋:淡綠底表示已載入
	; 狀態列顯示載入資訊:行數與大小
	Local $sz = FileGetSize($f)
	Local $txt = FileRead($f)
	Local $cnt = StringLen($txt) - StringLen(StringReplace($txt, @LF, "")) + 1
	Local $restored = _RecoverKnownOutputs($f)
	_Status("已載入：" & _NameOf($f) & "(" & $cnt & " 行，" & _SizeStr($sz) & ")" & ($restored > 0 ? "；已復原 " & $restored & " 個意外中斷的輸出檔" : ""))
	_UpdateToolbar() ;;已載入 → 啟用功能鈕
EndFunc   ;==>_SetScript

; 取檔名(去路徑)
Func _NameOf($p)
	Return StringRegExpReplace($p, "^.*[\\/]", "")
EndFunc   ;==>_NameOf

; ==================================================================
;  執行情況表
; ==================================================================
Func _InitExecList()
	Local $items = "整合腳本|預處理腳本|清除腳本註解語句|清除腳本空行及行首尾空白字元|" & _
			"取得所有函式清單|清除未使用函式|取得所有變數清單|清除未使用變數|" & _
			"函式混淆|變數混淆|數字加密處理|字串字面值處理|儲存腳本"
	Local $a = StringSplit($items, "|")
	For $i = 1 To $a[0]
		GUICtrlCreateListViewItem("[" & $i & "]|" & $a[$i] & "|", $g_lvExec)
	Next
EndFunc   ;==>_InitExecList

Func _ExecSet($idx, $txt)
	_GUICtrlListView_SetItemText($g_lvExec, $idx - 1, TR($txt), 2)
	_LogLine("    [" & $idx & "] 結果：" & $txt)
EndFunc   ;==>_ExecSet

; 處理日誌:勾選「輸出日誌」時累積帶時間戳的記錄
Func _LogLine($s)
	If $g_logOn Then $g_log &= @HOUR & ":" & @MIN & ":" & @SEC & "  " & $s & @CRLF
EndFunc   ;==>_LogLine

Func _ExecReset()
	$g_execActive = 0
	For $i = 1 To 13
		_GUICtrlListView_SetItemText($g_lvExec, $i - 1, "[" & $i & "]", 0)
		_ExecSet($i, "")
	Next
EndFunc   ;==>_ExecReset

; 把目前執行中的步驟「索引」顯示為箭頭,前一個還原為 [n]
Func _ExecActive($idx)
	If $g_execActive > 0 Then _GUICtrlListView_SetItemText($g_lvExec, $g_execActive - 1, "[" & $g_execActive & "]", 0)
	$g_execActive = $idx
	_GUICtrlListView_SetItemText($g_lvExec, $idx - 1, ChrW(0x2192), 0)
	; 不強制清除使用者選取，執行進度狀態與真正選取反白可同時存在。
	_GUICtrlListView_RedrawItems($g_lvExec, 0, 12)
EndFunc   ;==>_ExecActive

Func _ExecDone()
	If $g_execActive > 0 Then _GUICtrlListView_SetItemText($g_lvExec, $g_execActive - 1, "[" & $g_execActive & "]", 0)
	$g_execActive = 0
	; 工作完成後仍保留使用者的清單選取；只清除執行進度標示。
	_GUICtrlListView_RedrawItems($g_lvExec, 0, 12)
EndFunc   ;==>_ExecDone

; 一次設定「箭頭 + 狀態列文字」,並立即重繪
Func _Step($idx, $txt)
	_DebugTrace("RUN stage=" & $idx & " " & $txt)
	; 紀錄前一步驟耗時
	If $g_logOn And $g_stepT0 > 0 Then _LogLine("    (步驟 " & $g_stepPrev & " 耗時 " & Round(TimerDiff($g_stepT0) / 1000, 2) & " 秒)")
	$g_stepT0 = TimerInit()
	$g_stepPrev = $idx
	_ExecActive($idx)
	_Status($txt)
	_LogLine("[步驟 " & $idx & "] " & $txt)
	_Pump()
EndFunc   ;==>_Step

; v18.2: AutoIt 有時在 WM_COMMAND 備援啟動工作後，下一輪 GUIGetMsg 才收到
; *同一個* 啟動按鈕的原生事件。那是回音，不能被誤當成中止。
; 正式中止只接受執行中額外產生的 BN_CLICKED (由 _OnAppleCommand 記錄)。
Func _RunHandleStopClick($m)
	If $g_stopBtn = 0 Then Return
	; WM_COMMAND 能在 _Pump 未收下 GUIGetMsg 時先送達；有新中止點擊就接受。
	If $g_iRunStopClickSerial > 0 Then
		$g_iRunStopClickSerial -= 1
		$g_stop = True
		_DebugTrace("RUN STOP accepted: new click")
	ElseIf $m = $g_stopBtn Then
		$g_iRunIgnoredLaunchEcho += 1
		If $g_iRunIgnoredLaunchEcho <= 3 Then _DebugTrace("RUN ignored startup-click echo #" & $g_iRunIgnoredLaunchEcho)
	EndIf
EndFunc

; 強制重繪執行情況清單與狀態列,輪詢「中止」與樹狀換頁。回傳是否已中止。
Func _Pump()
	_WinAPI_UpdateWindow(GUICtrlGetHandle($g_lvExec))
	_WinAPI_UpdateWindow(GUICtrlGetHandle($g_status))
	_TitleButtonsPoll() ;;處理中仍可用 − / ✕(座標命中,不靠事件迴圈)
	Local $m = GUIGetMsg() ;;標題列拖曳由 $GUI_WS_EX_PARENTDRAG 處理(本次 GUIGetMsg 的派送即會觸發)
	If $m = $GUI_EVENT_CLOSE Then Exit
	_RunHandleStopClick($m)
	; 產生 ListView 虛擬資料時不允許重入切頁；檢測完成後恢復正常切換。
	If Not $g_bListPopulating Then
		If $m = $g_btn[4] Then _ShowPage($PG_EXEC)
		If $m = $g_btn[1] Then _ShowPage($PG_DETECT)
		_PollTree()
		_ApplyPendingSidePage()
	EndIf
	Return $g_stop
EndFunc   ;==>_Pump

; 側欄輪詢:hover 連動 + 點擊切頁/折疊(主迴圈與處理中共用)
; 沿用 _IsPressed + ScreenToClient;同一列按下→放開才觸發,避免拖曳誤點。
Func _PollTree()
	If Not $g_sMemDC Then Return
	Local $aPos = MouseGetPos()
	If Not IsArray($aPos) Then Return
	Local $tPt = DllStructCreate("long X;long Y")
	DllStructSetData($tPt, "X", $aPos[0])
	DllStructSetData($tPt, "Y", $aPos[1])
	DllCall("user32.dll", "bool", "ScreenToClient", "hwnd", $hMain, "struct*", $tPt)
	Local $cx = DllStructGetData($tPt, "X") - $g_sX
	Local $cy = DllStructGetData($tPt, "Y") - $g_sY
	Local $r = _SideRowAt($cx, $cy)

	If $r <> $g_sHover Then
		$g_sHover = $r
		_SideRender()
		_SideBlit()
	EndIf

	Local $down = (WinActive($hMain) And _IsPressed("01"))
	If $down And Not $g_sWasDown Then
		$g_sPressRow = $r
	ElseIf Not $down And $g_sWasDown Then
		If $g_sPressRow >= 0 And $r = $g_sPressRow Then _SideActivate($r, $cx)
		$g_sPressRow = -1
	EndIf
	$g_sWasDown = $down
	; 右鍵選單狀態改在滑鼠右鍵開始時更新，避免每次迴圈反覆操作控制項
	; 右鍵選單由 WM_CONTEXTMENU 於顯示前同步，避免輪詢重入
EndFunc   ;==>_PollTree

; 在清單「執行情況」欄即時顯示 已處理/總數,並重繪。回傳是否已中止。
Func _Progress($done, $total)
	If $g_execActive > 0 Then _GUICtrlListView_SetItemText($g_lvExec, $g_execActive - 1, $done & " / " & $total, 2)
	Return _Pump()
EndFunc   ;==>_Progress

; 自繪標題列的最小化/關閉備援。按下與放開都必須位於同一按鈕內，
; 避免單純滑過或拖曳視窗時誤觸。使用螢幕座標轉主視窗客戶區座標，支援 DPI。
Func _TitleButtonsPoll()
    Local $aKey = DllCall("user32.dll", "short", "GetAsyncKeyState", "int", 0x01)
    If @error Or Not IsArray($aKey) Then Return False
    Local $bDown = (BitAND($aKey[0], 0x8000) <> 0)
    Local $iHit = 0
    If WinActive($hMain) Then
        Local $aPos = MouseGetPos()
        Local $tPt = DllStructCreate("long X;long Y")
        DllStructSetData($tPt, "X", $aPos[0])
        DllStructSetData($tPt, "Y", $aPos[1])
        Local $aClient = DllCall("user32.dll", "bool", "ScreenToClient", "hwnd", $hMain, "struct*", $tPt)
        If Not @error And IsArray($aClient) And $aClient[0] Then
            Local $x = DllStructGetData($tPt, "X"), $y = DllStructGetData($tPt, "Y")
            If $y >= S(5) And $y < S(29) Then
                If $x >= S(902) And $x < S(936) Then $iHit = 1
                If $x >= S(940) And $x < S(974) Then $iHit = 2
            EndIf
        EndIf
    EndIf
    ; hover / 按下回饋(✕=紅底白字、按下更深紅;−=淺灰底、按下更深灰)
    Local $iPress = ($bDown And $g_iTitleMouseDown = $iHit And $iHit <> 0) ? $iHit : 0
    Local $vis = $iHit * 10 + $iPress
    If $vis <> $g_titleVisual Then
        $g_titleVisual = $vis
        $g_titleHover = $iHit
        _SetTitleBtnColors($iHit, $iPress)
    EndIf
    ; 只在滑鼠「由放開變成按下」時記錄起點，避免按住後移入按鈕誤觸。
    If $bDown And Not $g_bTitleWasDown Then
        $g_iTitleMouseDown = $iHit
    ElseIf Not $bDown And $g_bTitleWasDown Then
        Local $iReleased = $g_iTitleMouseDown
        $g_iTitleMouseDown = 0
        $g_bTitleWasDown = False
        ; 必須在同一按鈕內放開，才執行；移出按鈕放開即取消。
        If $iReleased <> 0 And $iReleased = $iHit Then
            If $iReleased = 1 Then
                GUISetState(@SW_MINIMIZE, $hMain)
            ElseIf $iReleased = 2 Then
                _CfgSave()
                Exit
            EndIf
            Return True
        EndIf
    EndIf
    $g_bTitleWasDown = $bDown
    Return False
EndFunc

; 主視窗任一區域接收 WM_DROPFILES(Unicode 路徑);三個輸入欄的 $GUI_EVENT_DROPPED 仍保留。
Func _OnActivate($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $lParam
	If $hWnd <> $hMain Then Return $GUI_RUNDEFMSG
	Local $active = (BitAND($wParam, 0xFFFF) <> 0) ;;WA_INACTIVE=0;其餘(ACTIVE/CLICKACTIVE)為作用中
	If $active = $g_winActive Then Return $GUI_RUNDEFMSG
	$g_winActive = $active
	_ApplyTitleColors()
	Return $GUI_RUNDEFMSG
EndFunc

; 依焦點狀態套用標題列顏色(漸層;作用中較亮、失焦較暗;文字/分隔線同步)
Func _ApplyTitleColors()
	Local $fg, $div
	If $g_winActive Then
		$fg = 0x15151B
		$div = 0xC7CAD2
	Else
		$fg = 0x404048 ; 失焦仍保留可讀對比
		$div = 0xD3D4D9
	EndIf
	_PaintTitleGradient($g_winActive) ;;重畫漸層細帶
	GUICtrlSetBkColor($g_lblTitle, $OB_TITLE_BG)
	GUICtrlSetColor($g_lblTitle, $fg)
	GUICtrlSetBkColor($g_divTitle, $div)
	_SetTitleBtnColors($g_titleHover)
EndFunc

; 線性內插 0~255 單一色版
Func _Lerp8($a, $b, $t)
	Return Int($a + ($b - $a) * $t)
EndFunc

; 取標題列漸層色:$t=0(頂)~1(底);$active 決定亮/暗兩組端點。回傳 0xRRGGBB
Func _TitleGrad($t, $active)
    #forceref $t, $active
    ; 固定全寬同色，避免 17 個 label 漸層與字型 label 拼接處，在焦點切換時露出縫隙。
    Return $OB_TITLE_BG
EndFunc

; 重畫整條漸層細帶
Func _PaintTitleGradient($active)
    #forceref $active
    ; 舊版 17 段漸層不再逐一改色；WM_ACTIVATE 僅更新文字/按鈕狀態。
    Return
EndFunc

; 依焦點 + hover + 按下 設定 − / ✕ 兩顆標題按鈕顏色
; $hover:0=皆無 1=最小化 2=關閉  $pressed:同編碼,表示按住中
Func _SetTitleBtnColors($hover, $pressed = 0)
	Local $baseBg = $OB_TITLE_BG ;;單色整合，聚焦與失焦一致
	Local $baseFg = $g_winActive ? 0x1D1D1F : 0x505058 ; 失焦圖示仍清楚
	; − 最小化
	If $pressed = 1 Then
		GUICtrlSetBkColor($g_btnMin, 0xD1D1D6) ;;按下更深灰
		GUICtrlSetColor($g_btnMin, 0x1D1D1F)
	ElseIf $hover = 1 Then
		GUICtrlSetBkColor($g_btnMin, 0xE5E5EA) ;;淺灰 hover
		GUICtrlSetColor($g_btnMin, 0x1D1D1F)
	Else
		GUICtrlSetBkColor($g_btnMin, $baseBg)
		GUICtrlSetColor($g_btnMin, $baseFg)
	EndIf
	; ✕ 關閉
	If $pressed = 2 Then
		GUICtrlSetBkColor($g_btnClose, 0xC50F1F) ;;按下更深紅
		GUICtrlSetColor($g_btnClose, 0xFFFFFF)
	ElseIf $hover = 2 Then
		GUICtrlSetBkColor($g_btnClose, 0xE81123) ;;紅底
		GUICtrlSetColor($g_btnClose, 0xFFFFFF) ;;白字
	Else
		GUICtrlSetBkColor($g_btnClose, $baseBg)
		GUICtrlSetColor($g_btnClose, $baseFg)
	EndIf
EndFunc

Func _OnDropFiles($hWnd, $iMsg, $wParam, $lParam)
	#forceref $iMsg, $lParam
	; 只處理我們認得的視窗(主視窗 + 有拖放欄的分頁子視窗),其餘交還系統
	If $hWnd <> $hMain And $hWnd <> $g_pg[$PG_CONV] And $hWnd <> $g_pg[$PG_DEBUG] Then Return $GUI_RUNDEFMSG
	Local $files = _DragGetAll($wParam) ;;取所有拖入的檔案(Unicode)
	DllCall("shell32.dll", "none", "DragFinish", "handle", $wParam)
	If UBound($files) = 0 Then Return 0
	Switch $hWnd
		Case $g_pg[$PG_CONV]
			GUICtrlSetData($g_inConvFile, $files[0])
		Case $g_pg[$PG_DEBUG]
			GUICtrlSetData($g_inDbgFile, $files[0])
		Case Else
			If UBound($files) > 1 Then
				$g_batchFiles = $files
				$g_doBatch = True ;;交由主迴圈處理(避免在訊息回呼中執行長工作)
			Else
				_SetScript($files[0]) ;;主視窗任一區域(含腳本輸入欄與空白處)
			EndIf
	EndSwitch
	Return 0
EndFunc   ;==>_OnDropFiles

; 從 WM_DROPFILES 的 wParam 取出所有檔案路徑(Unicode)
Func _DragGetAll($wParam)
	Local $res[0]
	Local $aCount = DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", 0xFFFFFFFF, "ptr", 0, "uint", 0)
	If @error Or Not IsArray($aCount) Or $aCount[0] < 1 Then Return $res
	Local $i
	For $i = 0 To $aCount[0] - 1
		Local $aLen = DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", $i, "ptr", 0, "uint", 0)
		If @error Then ContinueLoop
		Local $tPath = DllStructCreate("wchar[" & ($aLen[0] + 1) & "]")
		DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", $i, "struct*", $tPath, "uint", $aLen[0] + 1)
		If Not @error Then _ArrayAdd($res, DllStructGetData($tPath, 1))
	Next
	Return $res
EndFunc   ;==>_DragGetAll

; 從 WM_DROPFILES 的 wParam 取出第一個檔案完整路徑(Unicode)
Func _DragGetFirst($wParam)
	Local $aCount = DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", 0xFFFFFFFF, "ptr", 0, "uint", 0)
	If @error Or $aCount[0] < 1 Then Return ""
	Local $aLength = DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", 0, "ptr", 0, "uint", 0)
	If @error Then Return ""
	Local $tPath = DllStructCreate("wchar[" & ($aLength[0] + 1) & "]")
	DllCall("shell32.dll", "uint", "DragQueryFileW", "handle", $wParam, "uint", 0, "struct*", $tPath, "uint", $aLength[0] + 1)
	If @error Then Return ""
	Return DllStructGetData($tPath, 1)
EndFunc   ;==>_DragGetFirst

; 雙擊檢測/多語言清單列 → 用 SciTE 開啟原始腳本並跳到該行
; 深色主題:標籤/群組/輸入框/下拉清單統一淺字深底(回傳深色筆刷)
Func _WM_CTLCOLOR($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $lParam
	DllCall("gdi32.dll", "dword", "SetTextColor", "handle", $wParam, "dword", 0xE6E6E6) ;;淺字(COLORREF BGR,灰階對稱)
	DllCall("gdi32.dll", "dword", "SetBkColor", "handle", $wParam, "dword", 0x1E1E1E) ;;深底
	Return $g_hBrushDark
EndFunc   ;==>_WM_CTLCOLOR

; v16: 預先配置所有通知所需的常駐文字槽，不讓回呼分配大量結構。
; 每種通知 (ANSI/Unicode) 與每個清單分別有 64 個槽。
Func _LvTextBuffersInit()
	If $g_bLvTextBuffersReady Then Return
	For $i = 0 To 2
		For $j = 0 To 63
			$g_aLvTextW[$i][$j] = DllStructCreate("wchar[4096]")
			$g_aLvTextA[$i][$j] = DllStructCreate("char[4096]")
			If @error Then
				_DebugTrace("LV buffer allocation failed list=" & $i & " slot=" & $j)
				Return
			EndIf
		Next
	Next
	$g_bLvTextBuffersReady = True
	_DebugTrace("LV stable text buffers ready lists=3 slots=64 per encoding")
EndFunc

; 與 GDI+ / 控制項無關的清單資料交易：停用重繪 → 清空可見列數 → 替換快照。
; 所有耗時解析都在暫存陣列內完成，舊資料在提交之前保持不變。
Func _LvBeginSnapshot($id)
    ; v18.3.7：不對 OWNERDATA 清單使用 WM_SETREDRAW(False)。
    ; 該訊息也會影響 ListView 的可見樣式和內部 Header 繪製，
    ; 若中途收到同步通知，可能留下白畫面或標頭不重繪。
    Local $h = GUICtrlGetHandle($id)
    If Not IsHWnd($h) Then Return
    ; LVM_SETITEMCOUNT = 0x102F，LVSICF_NOINVALIDATEALL|LVSICF_NOSCROLL = 3。
    ; 通知期間 g_bListPopulating 已為 True，繪製回呼會退回原生處理。
    Local $a = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x102F, "wparam", 0, "lparam", 3)
    If @error Or Not IsArray($a) Then _DebugTrace("LV snapshot reset failed control=" & $id)
EndFunc   ;==>_LvBeginSnapshot

Func _LvCommitSnapshot($id, ByRef $target, ByRef $staging, $count)
    ; 依清單是否仍為 OWNERDATA(虛擬)自動分流:
    ;   虛擬 → 僅告知列數,內容由 LVN_GETDISPINFO 供應(維持原行為)。
    ;   一般 → 直接塞入真實項目(可安全自繪主題色反白,無取字重入)。
    Local $h = GUICtrlGetHandle($id)
    $target = $staging
    If IsHWnd($h) Then
        If $id = $g_lvDetect Or $id = $g_lvML Or $id = $g_lvDbg Then
            ; owner-draw ListBox:各欄以 @TAB 串接塞入,繪製時再切欄;來源行號等原始資料仍保留在資料陣列。
            Local $ncol = ($id = $g_lvDbg) ? 3 : 2
            DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x000B, "wparam", 0, "lparam", 0) ;;WM_SETREDRAW False
            _GUICtrlListBox_ResetContent($h)
            If $count > 2000 Then _GUICtrlListBox_InitStorage($h, $count, 64) ;;大量項目先預配記憶體,避免逐筆 LB_ADDSTRING 重配而變慢(大檔除錯清單)
            Local $k, $c
            For $k = 0 To $count - 1
                Local $s = String($staging[$k][0])
                For $c = 1 To $ncol - 1
                    $s &= @TAB & String($staging[$k][$c])
                Next
                _GUICtrlListBox_AddString($h, $s)
            Next
            DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x000B, "wparam", 1, "lparam", 0) ;;WM_SETREDRAW True
            DllCall("user32.dll", "bool", "InvalidateRect", "hwnd", $h, "ptr", 0, "bool", True)
            $g_bListMenuDirty = True
            $g_selDet = -1
            $g_selML = -1
            $g_selDbg = -1
            $g_bLvSelectionDirty = True
            $g_iHeaderCheckPage = -1
            Return
        EndIf
        Local $isVirtual = (BitAND(_WinAPI_GetWindowLong($h, -16), 0x1000) <> 0) ;;LVS_OWNERDATA=0x1000
        If $isVirtual Then
            ; 使用官方 LVM_SETITEMCOUNT，不切換 WS_VISIBLE，也不操作 Header HWND。
            Local $a = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x102F, "wparam", $count, "lparam", 3)
            If @error Or Not IsArray($a) Then
                _DebugTrace("LV snapshot commit call failed control=" & $id & " count=" & $count)
            ElseIf $a[0] = 0 Then
                _DebugTrace("LV snapshot commit returned FALSE control=" & $id & " count=" & $count)
            EndIf
            DllCall("user32.dll", "bool", "InvalidateRect", "hwnd", $h, "ptr", 0, "bool", False)
        Else
            ; 一般清單:關閉重繪批次塞入,速度快且不閃爍。
            Local $cols = _GUICtrlListView_GetColumnCount($h)
            If $cols < 1 Then $cols = 1
            DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x000B, "wparam", 0, "lparam", 0) ;;WM_SETREDRAW False
            _GUICtrlListView_DeleteAllItems($h)
            Local $i, $j
            For $i = 0 To $count - 1
                _GUICtrlListView_AddItem($h, String($staging[$i][0]))
                For $j = 1 To $cols - 1
                    _GUICtrlListView_AddSubItem($h, $i, String($staging[$i][$j]), $j)
                Next
            Next
            DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x000B, "wparam", 1, "lparam", 0) ;;WM_SETREDRAW True
            DllCall("user32.dll", "bool", "InvalidateRect", "hwnd", $h, "ptr", 0, "bool", True)
        EndIf
    EndIf
    $g_bListMenuDirty = True
    $g_selDet = -1
    $g_selML = -1
    $g_selDbg = -1
    $g_bLvSelectionDirty = True
    ; 只在主迴圈檢查標題；不在提交時重建或 ShowWindow Header。
    $g_iHeaderCheckPage = -1
EndFunc   ;==>_LvCommitSnapshot

Func _LvGetActualSelected($id)
	If $id <= 0 Then Return -1
	Local $h = GUICtrlGetHandle($id)
	If Not IsHWnd($h) Then Return -1
	If $id = $g_lvDetect Or $id = $g_lvML Or $id = $g_lvDbg Then Return _GUICtrlListBox_GetCurSel($h) ;;owner-draw ListBox:直接問目前選取列(-1=無)
	Local $a = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", $OB_LVM_GETNEXTITEM, "wparam", -1, "lparam", $OB_LVNI_SELECTED)
	If @error Or Not IsArray($a) Then Return -1
	Local $row = $a[0]
	If $row < 0 Then Return -1
	Local $b = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", $OB_LVM_GETITEMSTATE, "wparam", $row, "lparam", $OB_LVIS_SELECTED)
	If @error Or Not IsArray($b) Then Return -1
	If BitAND($b[0], $OB_LVIS_SELECTED) = 0 Then Return -1
	Return $row
EndFunc

; 真正的選取狀態查詢在 GUI 主迴圈執行；繪製只讀取快取。
; 除收到 LVN_ITEMCHANGED / LVN_ODSTATECHANGED 立即同步外，
; 每 150ms 對照一次系統狀態，補上虛擬清單偶爾未通知的情況。
Func _LvSyncSelections()
    If $g_bListPopulating Or $g_bPageSwitchBusy Then Return
    ; OWNERDATA 虛擬清單只有顯示中的一份需要輪詢，避免對另外兩個
    ; 隱藏頁面持續 SendMessage，觸發同步 LVN_GETDISPINFO/繪製通知。
    If $g_iActivePage <> $PG_DETECT And $g_iActivePage <> $PG_ML And $g_iActivePage <> $PG_DEBUG Then Return
    If $g_tLvSelectionPoll = 0 Then $g_tLvSelectionPoll = TimerInit()
    If Not $g_bLvSelectionDirty And TimerDiff($g_tLvSelectionPoll) < 150 Then Return
    $g_tLvSelectionPoll = TimerInit()
    $g_bLvSelectionDirty = False
    Local $oldRow = -1
    Switch $g_iActivePage
        Case $PG_DETECT
            Local $d = _LvGetActualSelected($g_lvDetect)
            If $d <> $g_selDet Then
                $oldRow = $g_selDet
                $g_selDet = $d
                _LvRedrawChangedRows($g_lvDetect, $oldRow, $d)
                $g_bListMenuDirty = True
            EndIf
        Case $PG_ML
            Local $m = _LvGetActualSelected($g_lvML)
            If $m <> $g_selML Then
                $oldRow = $g_selML
                $g_selML = $m
                _LvRedrawChangedRows($g_lvML, $oldRow, $m)
                $g_bListMenuDirty = True
            EndIf
        Case $PG_DEBUG
            Local $b = _LvGetActualSelected($g_lvDbg)
            If $b <> $g_selDbg Then
                $oldRow = $g_selDbg
                $g_selDbg = $b
                _LvRedrawChangedRows($g_lvDbg, $oldRow, $b)
            EndIf
    EndSwitch
EndFunc

; 只重繪舊選取列與新選取列，避免整張 OWNERDATA 清單重複 GETDISPINFO。
; 在主迴圈執行；WM_NOTIFY 不呼叫 LVM_REDRAWITEMS。
Func _LvRedrawChangedRows($id, $oldRow, $newRow)
    Local $h = GUICtrlGetHandle($id)
    If Not IsHWnd($h) Then Return
    ; LVM_REDRAWITEMS = LVM_FIRST + 21
    If $oldRow >= 0 Then DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x1015, "wparam", $oldRow, "lparam", $oldRow)
    If $newRow >= 0 And $newRow <> $oldRow Then DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", 0x1015, "wparam", $newRow, "lparam", $newRow)
EndFunc

Func _LvRefreshVirtualLists()
	Local $a[3] = [$g_lvDetect, $g_lvML, $g_lvDbg]
	For $i = 0 To 2
		Local $h = GUICtrlGetHandle($a[$i])
		If IsHWnd($h) Then DllCall("user32.dll", "bool", "InvalidateRect", "hwnd", $h, "ptr", 0, "bool", True)
	Next
EndFunc

; Windows 訊息內只累計計數；這裡由主事件迴圈定期落盤，避免回呼中 FileOpen。
Func _LvFlushSafeCounters()
	If $g_tLvDiagFlush = 0 Then $g_tLvDiagFlush = TimerInit()
	If TimerDiff($g_tLvDiagFlush) < 5000 Then Return
	$g_tLvDiagFlush = TimerInit()
	If $g_iLvTextRequests = 0 And $g_iLvDrawRequests = 0 And $g_iLvPendingDouble = 0 Then Return
	_DebugTrace("LV counters text=" & $g_iLvTextRequests & " nested=" & $g_iLvNestedText & " draw=" & $g_iLvDrawRequests & " skipped=" & $g_iLvDroppedDraw & " safe=" & $g_bLvSafeDraw)
	$g_iLvTextRequests = 0
	$g_iLvNestedText = 0
	$g_iLvDrawRequests = 0
	$g_iLvDroppedDraw = 0
EndFunc

; 雙擊實際執行操作延後到主迴圈（不在 WM_NOTIFY 內開啟外部程式）。
Func _LvHandlePendingDouble()
	Local $action = $g_iLvPendingDouble
	If $action = 0 Or $g_bListPopulating Or $g_bPageSwitchBusy Then Return
	$g_iLvPendingDouble = 0
	Switch $action
		Case 1
			_OpenAtLine($g_lvDetect, $g_detData)
		Case 2
			_OpenAtLine($g_lvML, $g_mlData)
		Case 3
			_DbgOpenLine()
	EndSwitch
EndFunc

Func _OnNotify($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	If $lParam = 0 Then Return $GUI_RUNDEFMSG
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	If @error Then Return $GUI_RUNDEFMSG
	Local $code = DllStructGetData($tNMHDR, "Code")
	Local $hFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	; 所有訊息回呼內禁止磁碟 LOG、GUI 修改或查詢 ListView 目前選取列。
	If $code = -121 Then Return $GUI_RUNDEFMSG ; LVN_HOTTRACK
	Local $isDbg = ($hFrom = $g_hLvDbg)
	Local $isDet = ($hFrom = $g_hLvDet)
	Local $isML = ($hFrom = $g_hLvML)
	Local $isExec = ($hFrom = $g_hLvExec)
	If Not ($isDbg Or $isDet Or $isML Or $isExec) Then Return $GUI_RUNDEFMSG

	Switch $code
		Case -177, -150 ; LVN_GETDISPINFOW / LVN_GETDISPINFOA
			If Not $g_bLvTextBuffersReady Then Return 0
			$g_iLvTextRequests += 1
			If $g_iLvDrawDepth > 0 Then $g_iLvNestedText += 1
			Local $unicode = ($code = -177)
			If $isDet Then Return _LvFillDispInfoSafe($lParam, $g_detData, 0, $unicode)
			If $isML Then Return _LvFillDispInfoSafe($lParam, $g_mlData, 1, $unicode)
			If $isDbg Then Return _LvFillDispInfoSafe($lParam, $g_dbgData, 2, $unicode)
			Return 0

		Case -12 ; NM_CUSTOMDRAW
			$g_iLvDrawRequests += 1
			If $g_bPageSwitchBusy Or $g_bListPopulating Then Return 0 ; CDRF_DODEFAULT
			If $g_bLvSafeDraw And Not $isExec Then Return 0 ; 僅虛擬清單可切原生繪製
			If $g_iLvDrawDepth > 0 Then
				$g_iLvDroppedDraw += 1
				Return 0 ; CDRF_DODEFAULT，不丟給 AutoIt 其他訊息處理
			EndIf
			$g_iLvDrawDepth += 1
			Local $result = _LvCustomDraw($lParam, $hFrom)
			$g_iLvDrawDepth -= 1
			Return $result

		Case -101 ; LVN_ITEMCHANGED：回呼只記錄「待同步」
			; 真正 LVIS_SELECTED 由主迴圈讀取，不在通知內讀 NMLISTVIEW 或發 Win32 訊息。
			$g_bLvSelectionDirty = True
			$g_bListMenuDirty = True
			Return $GUI_RUNDEFMSG

		Case -115 ; LVN_ODSTATECHANGED（OWNERDATA 範圍狀態變動通知）
			$g_bLvSelectionDirty = True
			$g_bListMenuDirty = True
			Return $GUI_RUNDEFMSG

		Case -3 ; NM_DBLCLK
			If $g_bPageSwitchBusy Or $g_bListPopulating Then Return 0
			If $isDet Then $g_iLvPendingDouble = 1
			If $isML Then $g_iLvPendingDouble = 2
			If $isDbg Then $g_iLvPendingDouble = 3
			Return 0
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_OnNotify

; 清單斑馬紋:僅對四個資料清單生效,其餘控制項維持系統預設繪製
; 虛擬列表文字供應:依 LVN_GETDISPINFO 要求的列/欄,從資料陣列填入系統提供的緩衝區
; v13 將字串放入各 ListView 常駐的全域 wchar/char 緩衝區，
; 並在 LVN_GETDISPINFO 返回時提供 Text 指標，避免對未驗證的外部記憶體寫入。
; 相容舊函式名稱的安全轉送。實際 WM_NOTIFY 使用 _LvFillDispInfoSafe。
Func _LvFillDispInfo($lParam, ByRef $data, ByRef $tStableBuf, $unicode = True)
	#forceref $lParam, $data, $tStableBuf, $unicode
	; 此入口保留給舊程式使用；WM_NOTIFY 已不再呼叫它。
	Return 0
EndFunc   ;==>_LvFillDispInfo

; v18.3.7: LVN_GETDISPINFO 優先「寫入通知呼叫方自己的 pszText 緩衝區」。
; 這能避免替換 pszText 為輪替指標之後，切頁大量通知期間的指標生命週期問題。
; cchTextMax 為唯讀，含結尾 NUL；不擅自擴容、不寫超過呼叫方宣告容量。
; 僅在 pszText=NULL / TextMax<=0 時，用長期持有的固定緩衝區備援。
; 此函式不可更新 GUI / 發 SendMessage / 寫診斷檔。
Func _LvFillDispInfoSafe($lParam, ByRef $data, $listIndex, $unicode)
    If $lParam = 0 Or Not $g_bLvTextBuffersReady Then Return 0
    If $listIndex < 0 Or $listIndex > 2 Then Return 0
    Local $tDI = DllStructCreate($tagNMLVDISPINFO, $lParam)
    If @error Then Return 0
    If BitAND(DllStructGetData($tDI, "Mask"), $LVIF_TEXT) = 0 Then Return 0

    Local $item = DllStructGetData($tDI, "Item")
    Local $sub = DllStructGetData($tDI, "SubItem")
    Local $txt = ""
    If $item >= 0 And $item < UBound($data) And $sub >= 0 And $sub < UBound($data, 2) Then
        $txt = String($data[$item][$sub])
    EndIf

    Local $capacity = DllStructGetData($tDI, "TextMax")
    Local $ptr = DllStructGetData($tDI, "Text")
    ; 只在 Windows 提供有效的緩衝區與容量時直接複製。
    If $ptr <> 0 And $ptr <> -1 And $capacity > 0 Then
        ; 每次只映射本次要寫的容量，絕不大於 TextMax。
        Local $size = $capacity
        If $size > 4096 Then $size = 4096
        If $unicode Then
            Local $tOutW = DllStructCreate("wchar[" & $size & "]", $ptr)
            If Not @error Then
                DllStructSetData($tOutW, 1, StringLeft($txt, $size - 1))
                Return 0
            EndIf
        Else
            Local $tOutA = DllStructCreate("char[" & $size & "]", $ptr)
            If Not @error Then
                ; 系統 ANSI code page 可能使用多位元組；最壞以每字 4 bytes 計算。
                DllStructSetData($tOutA, 1, StringLeft($txt, Int(($size - 1) / 4)))
                Return 0
            EndIf
        EndIf
    EndIf

    ; 少數通知沒有提供 pszText 緩衝區：沿用全域固定槽，避免局部字串失效。
    ; 此備援不寫入呼叫方記憶體，且絕不修改 TextMax。
    Local $slot = 0
    If $unicode Then
        $slot = Mod($g_aLvCursorW[$listIndex], 64)
        $g_aLvCursorW[$listIndex] += 1
        DllStructSetData($g_aLvTextW[$listIndex][$slot], 1, StringLeft($txt, 1024))
        DllStructSetData($tDI, "Text", DllStructGetPtr($g_aLvTextW[$listIndex][$slot]))
    Else
        $slot = Mod($g_aLvCursorA[$listIndex], 64)
        $g_aLvCursorA[$listIndex] += 1
        DllStructSetData($g_aLvTextA[$listIndex][$slot], 1, StringLeft($txt, 256))
        DllStructSetData($tDI, "Text", DllStructGetPtr($g_aLvTextA[$listIndex][$slot]))
    EndIf
    Return 0
EndFunc   ;==>_LvFillDispInfoSafe

Func _LvCustomDraw($lParam, $hFrom)
	; v17.2 四個資料清單統一蘋果風:斑馬紋 + 真正選取列反白；執行情況另外保留執行進度底色。
	Local $isExec = ($hFrom = $g_hLvExec)
	; 試點期間:只自繪執行情況。檢測改用 ListBox(走 WM_DRAWITEM);
	; 多語言/除錯仍為 ListView,維持系統原生(不自繪,避免卡死),待檢測試點穩定再一併改。
	If Not $isExec Then Return 0
	If $lParam = 0 Then Return $GUI_RUNDEFMSG
	Local $t = DllStructCreate($tagNMLVCUSTOMDRAW, $lParam)
	If @error Then Return $GUI_RUNDEFMSG
	Local $stage = DllStructGetData($t, "dwDrawStage")
	Switch $stage
		Case 0x00000001 ; CDDS_PREPAINT
			Return 0x00000020 ; CDRF_NOTIFYITEMDRAW
		Case 0x00010001 ; CDDS_ITEMPREPAINT
			Local $row = DllStructGetData($t, "dwItemSpec")
			If $isExec Then
				; v17.2：執行情況是一般 ListView，沒有 OWNERDATA 的同步取字回呼。
				; 使用已實測正確的 LVM_GETITEMSTATE / LVIS_SELECTED 取得真正的選取狀態。
				; 清除 *當次繪製* 的 CDIS_SELECTED / CDIS_FOCUS，避免系統反白蓋掉 Apple 主題色。
				Local $execState = DllStructGetData($t, "uItemState")
				DllStructSetData($t, "uItemState", BitAND($execState, BitNOT(BitOR($OB_CDIS_SELECTED, $OB_CDIS_FOCUS))))
				Local $isExecSelected = False
				Local $hExec = $g_hLvExec
				If $row >= 0 And IsHWnd($hExec) Then
					Local $aExecState = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hExec, "uint", $OB_LVM_GETITEMSTATE, "wparam", $row, "lparam", $OB_LVIS_SELECTED)
					If Not @error And IsArray($aExecState) Then $isExecSelected = (BitAND($aExecState[0], $OB_LVIS_SELECTED) <> 0)
				EndIf
				If $isExecSelected Then
					; 滑鼠實際選取列：Apple 主題色反白 + 白字，優先於執行中的狀態色。
					DllStructSetData($t, "clrTextBk", _ToBGR($g_accent))
					DllStructSetData($t, "clrText", 0xFFFFFF)
				ElseIf $g_execActive > 0 And $row = $g_execActive - 1 Then
					; 正在執行的步驟不是使用者選取：保留原本的狀態提示色。
					DllStructSetData($t, "clrTextBk", 0xFBECE5)
					DllStructSetData($t, "clrText", 0xA66B13)
				Else
					DllStructSetData($t, "clrTextBk", (Mod($row, 2) = 0) ? 0xFFFFFF : 0xF7F7F7)
					DllStructSetData($t, "clrText", 0x1F1F1F)
				EndIf
				Return $OB_CDRF_NEWFONT
			EndIf

			; 照 SciTEUserTool 的穩定做法:不清 uItemState(不強行覆蓋系統反白),
			; 只設底色/文字色後回傳 NEWFONT。選取列維持系統反白(藍),斑馬紋由自繪提供。
			If $row >= 0 And $row = _LvSelOf($hFrom) Then
				DllStructSetData($t, "clrTextBk", _ToBGR($g_accent))
				DllStructSetData($t, "clrText", 0xFFFFFF)
			Else
				DllStructSetData($t, "clrTextBk", (Mod($row, 2) = 0) ? 0xFFFFFF : 0xF7F7F7)
				DllStructSetData($t, "clrText", 0x1F1F1F)
			EndIf
			Return $OB_CDRF_NEWFONT
	EndSwitch
	Return 0
EndFunc   ;==>_LvCustomDraw

; ARGB(0xFFrrggbb) → COLORREF(BGR 0x00bbggrr)
Func _ToBGR($argb)
	Local $r = BitAND(BitShift($argb, 16), 0xFF)
	Local $g = BitAND(BitShift($argb, 8), 0xFF)
	Local $b = BitAND($argb, 0xFF)
	Return BitOR(BitShift($b, -16), BitShift($g, -8), $r)
EndFunc   ;==>_ToBGR

; LVN_ITEMCHANGED:記錄該清單目前被選取的列索引(在通知裡處理,安全)
Func _LvTrackSel($lParam, $hFrom)
	Local $t = DllStructCreate($tagNMLISTVIEW, $lParam)
	Local $iItem = DllStructGetData($t, "Item")
	Local $old = DllStructGetData($t, "OldState")
	Local $new = DllStructGetData($t, "NewState")
	If $iItem < 0 Then Return
	Local $sel = BitAND($new, 0x0002) <> 0
	Local $was = BitAND($old, 0x0002) <> 0
	If $sel = $was Then Return
	Local $value = $sel ? $iItem : -1
	If $hFrom = $g_hLvDet Then $g_selDet = $value
	If $hFrom = $g_hLvML Then $g_selML = $value
	If $hFrom = $g_hLvDbg Then $g_selDbg = $value
	$g_bListMenuDirty = True ; 只記錄狀態，GUI 主迴圈更新選單
EndFunc

Func _LvSelOf($hFrom)
	If $hFrom = $g_hLvDet Then Return $g_selDet
	If $hFrom = $g_hLvML Then Return $g_selML
	If $hFrom = $g_hLvDbg Then Return $g_selDbg
	Return -1
EndFunc

; WM_CONTEXTMENU 先於選單開啟送達，僅同步狀態、不攔截預設選單處理。
Func _OnListContextMenu($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $lParam
	Local $hSrc = HWnd($wParam)
	If $hSrc = $g_hLvDet Or $hSrc = $g_hLvML Then _LvUpdMenus()
	Return $GUI_RUNDEFMSG
EndFunc

Func _LvValidSelection($lv, ByRef $data)
	Local $row = _LvSelIndex($lv) ;;相容 owner-draw ListBox 與 ListView
	If $row < 0 Or $row >= UBound($data) Then Return -1
	Return $row
EndFunc

; 選單是否可用，以控制項當下真正選取列及資料內容為準。
Func _LvUpdMenus()
    ; 只讀取正在顯示的虛擬清單，避免查詢隱藏清單造成同步 WM_NOTIFY。
    If $g_bPageSwitchBusy Or $g_bListPopulating Then Return
    Switch $g_iActivePage
        Case $PG_DETECT
            Local $d = _LvValidSelection($g_lvDetect, $g_detData)
            $g_selDet = $d
            GUICtrlSetState($g_mnuDetCopy, $d >= 0 ? $GUI_ENABLE : $GUI_DISABLE)
            GUICtrlSetState($g_mnuDetOpen, ($d >= 0 And $g_script <> "" And FileExists($g_script)) ? $GUI_ENABLE : $GUI_DISABLE)
            GUICtrlSetState($g_mnuDetExport, UBound($g_detData) > 0 ? $GUI_ENABLE : $GUI_DISABLE)
        Case $PG_ML
            Local $m = _LvValidSelection($g_lvML, $g_mlData)
            $g_selML = $m
            GUICtrlSetState($g_mnuMLCopy, $m >= 0 ? $GUI_ENABLE : $GUI_DISABLE)
            GUICtrlSetState($g_mnuMLOpen, ($m >= 0 And $g_script <> "" And FileExists($g_script)) ? $GUI_ENABLE : $GUI_DISABLE)
            GUICtrlSetState($g_mnuMLRestore, UBound($g_mlData) > 0 ? $GUI_ENABLE : $GUI_DISABLE)
    EndSwitch
EndFunc   ;==>_LvUpdMenus

; 美化清單:全列選取 + 無格線 + 雙緩衝(消閃爍) + 統一字型
Func _BeautifyLv($lv)
	; 蘋果風:全列選取 + 去格線 + 雙緩衝(消閃爍);斑馬紋與選取色由 _LvCustomDraw 畫
	_GUICtrlListView_SetExtendedListViewStyle($lv, BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_DOUBLEBUFFER))
	GUICtrlSetFont($lv, 10, $font_xing, $font_var, $font_name, $font_quality)
	; 不啟用 GUI_BKCOLOR_LV_ALTERNATE：AutoIt 原生交錯背景與 NM_CUSTOMDRAW 雙重上色
	; 會增加 OWNERDATA 通知與重繪機會；原有斑馬紋已由 _LvCustomDraw 負責。
	_GUICtrlListView_SetBkColor($lv, 0xFFFFFF)
	_GUICtrlListView_SetTextBkColor($lv, 0xFFFFFF)
	_GUICtrlListView_SetTextColor($lv, 0x1D1D1F)
EndFunc   ;==>_BeautifyLv

; 讀取並清理 SciTE 路徑:去除前後空白與成對引號(避免使用者貼上含引號的路徑導致 FileExists 失敗)
Func _SciTEPath()
	Local $s = StringStripWS(GUICtrlRead($g_inSciTE), 3)
	If StringLeft($s, 1) = '"' And StringRight($s, 1) = '"' And StringLen($s) >= 2 Then
		$s = StringStripWS(StringTrimLeft(StringTrimRight($s, 1), 1), 3)
	EndIf
	Return $s
EndFunc   ;==>_SciTEPath

; 除錯頁雙擊:以第 0 欄(實際行號)用 SciTE 開啟被檢查的檔案
Func _DbgOpenLine()
	Local $row = _LvSelIndex($g_lvDbg) ;;owner-draw ListBox:目前選取列
	If $row < 0 Or $row >= UBound($g_dbgData) Then Return
	Local $line = $g_dbgData[$row][0] ;;虛擬列表:讀資料陣列
	Local $file = GUICtrlRead($g_inDbgFile)
	If Not FileExists($file) Or Not StringIsInt($line) Then Return
	Local $scite = _SciTEPath()
	If $scite = "" Then
		_Msg(48, "定位", "位於第 " & $line & " 行。" & @CRLF & @CRLF & "尚未設定 SciTE 路徑，請至「參數設定」填入 SciTE.exe。")
	ElseIf Not FileExists($scite) Then
		_Msg(48, "定位", "位於第 " & $line & " 行。" & @CRLF & @CRLF & "SciTE 路徑無效或找不到檔案：" & @CRLF & $scite)
	Else
		Run('"' & $scite & '" "' & $file & '" "-goto:' & $line & '"', _DirOf($scite))
	EndIf
EndFunc   ;==>_DbgOpenLine

; 匯出除錯行號對照表為 CSV
Func _DbgExport()
	Local $n = UBound($g_dbgData)
	If $n = 0 Then
		_Msg(48, "提示", "請先『檢測』出對照表。")
		Return
	EndIf
	Local $f = FileSaveDialog("匯出行號對照表", @ScriptDir, "CSV (*.csv)|文字檔 (*.txt)", 16, "linemap.csv", $hMain)
	If @error Then Return
	Local $txt = "實際行號，內部行號，內容" & @CRLF, $i
	For $i = 0 To $n - 1
		$txt &= $g_dbgData[$i][0] & "," & $g_dbgData[$i][1] & "," & _
				'"' & StringReplace($g_dbgData[$i][2], '"', '""') & '"' & @CRLF
		If Mod($i, 4000) = 0 Then _Pump()
	Next
	If Not _WriteOut($f, $txt) Then Return _Msg(16, "匯出失敗", $g_sLastOutputError)
	_Msg(64, "完成", "已匯出:" & @CRLF & $f)
EndFunc   ;==>_DbgExport

; 依選取列，從虛擬資料查來源行號，以 SciTE 開啟並跳轉（未設 SciTE 則提示）
; 取得清單目前選取列索引(相容 owner-draw ListBox 與 ListView);無選取回 -1
Func _LvSelIndex($lv)
	If $lv = $g_lvDetect Or $lv = $g_lvML Or $lv = $g_lvDbg Then Return _GUICtrlListBox_GetCurSel(GUICtrlGetHandle($lv)) ;;ListBox
	Local $sel = _GUICtrlListView_GetSelectedIndices($lv, False)
	If $sel = "" Then Return -1
	Return Int($sel)
EndFunc   ;==>_LvSelIndex

Func _OpenAtLine($lv, ByRef $data)
	If $g_script = "" Then Return
	Local $row = _LvSelIndex($lv)
	If $row < 0 Or $row >= UBound($data) Then Return
	Local $line = $data[$row][2]
	If Not StringIsInt($line) Or $line < 1 Then Return
	Local $scite = _SciTEPath()
	If $scite <> "" And FileExists($scite) Then
		Run('"' & $scite & '" "' & $g_script & '" "-goto:' & $line & '"', _DirOf($scite))
	ElseIf $scite <> "" Then
		_Msg(48, "定位", "位於第 " & $line & " 行。" & @CRLF & @CRLF & "SciTE 路徑無效或找不到檔案：" & @CRLF & $scite)
	Else
		_Msg(64, "定位", "位於第 " & $line & " 行。" & @CRLF & @CRLF & "若要雙擊自動跳轉，請先在「參數設定」填入 SciTE.exe 路徑。")
	EndIf
EndFunc   ;==>_OpenAtLine

; 複製清單選取列的內容（第 1 欄）到剪貼簿 — 從虛擬資料讀取
Func _LvCopySel($lv, ByRef $data)
	Local $row = _LvSelIndex($lv)
	If $row < 0 Or $row >= UBound($data) Then Return
	Local $txt = $data[$row][1]
	ClipPut($txt)
	_Status("已複製到剪貼簿:" & StringLeft($txt, 60))
EndFunc   ;==>_LvCopySel

; #RequireAdmin 下，放行拖放相關訊息（否則無法從一般 Explorer 拖入檔案）
Func _AllowDrop()
	; 程序層級（舊 API，相容用）
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilter", "dword", 0x0233, "dword", 1)
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilter", "dword", 0x0049, "dword", 1)
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilter", "dword", 0x004A, "dword", 1)
	; 逐視窗層級（Win7+ 建議 API）：主視窗 + 有拖放欄的分頁子視窗
	_AllowDropWin($hMain)
	_AllowDropWin($g_pg[$PG_DEBUG])
	_AllowDropWin($g_pg[$PG_CONV])
EndFunc   ;==>_AllowDrop

Func _AllowDropWin($h)
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", "hwnd", $h, "uint", 0x0233, "dword", 1, "ptr", 0) ;;WM_DROPFILES
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", "hwnd", $h, "uint", 0x0049, "dword", 1, "ptr", 0) ;;WM_COPYGLOBALDATA
	DllCall("user32.dll", "bool", "ChangeWindowMessageFilterEx", "hwnd", $h, "uint", 0x004A, "dword", 1, "ptr", 0) ;;WM_COPYDATA
EndFunc   ;==>_AllowDropWin

; ==================================================================
;  主處理流程
; ==================================================================
Func _RunProcess($obf)
	If $g_bRunBusy Then
		_DebugTrace("RUN rejected: another run is active")
		Return
	EndIf
	$g_bLastRunOk = False
	$g_sLastOutputError = ""
	_DebugTrace("RUN enter obf=" & $obf & " builtin=" & (GUICtrlRead($g_oBuiltinCase) = $GUI_CHECKED) & " file=" & $g_script)
	If $g_script = "" Or Not FileExists($g_script) Then
		_Msg(48, "提示", "請先拖入或選擇一個 .au3 腳本。")
		Return
	EndIf
	; 防重複混淆：偵測腳本是否已含 Obscura 注入的 _xd() 解碼器（重複混淆會壞檔）
	If StringRegExp(FileRead($g_script), "(?im)^\s*Func\s+_xd\b") Then
		If _Msg(BitOR(4, 48), "可能已混淆", "偵測到此腳本已含 Obscura 的解碼函式 _xd(),看起來已經混淆過。" & @CRLF & @CRLF & _
				"重複混淆很可能導致輸出無法執行。確定仍要繼續嗎?") <> 6 Then Return
	EndIf
	; 名稱對照表容器（供結束後選擇性輸出）
	Local $fmap = 0, $vmap = 0
	; 輸出檔覆蓋確認
	Local $od = _DirOf($g_script) & "\" & StringRegExpReplace(StringRegExpReplace($g_script, "^.*\\", ""), "\.[^.]*$", "") & ($obf ? "_Obfuscation" : "_Integration") & ".au3"
	If FileExists($od) Then
		If _Msg(BitOR(4, 48), "輸出檔已存在", "輸出檔已存在,將被覆蓋:" & @CRLF & $od & @CRLF & @CRLF & "要繼續嗎?") <> 6 Then Return
	EndIf
	$g_bRunBusy = True
	$g_iRunStopClickSerial = 0
	$g_iRunIgnoredLaunchEcho = 0
	_DebugTrace("RUN before show execution page")
	_ShowPage($PG_EXEC)
	_DebugTrace("RUN after show, before ExecReset")
	_ExecReset()
	_DebugTrace("RUN after ExecReset")
	; 執行中列使用獨立配色，不再強制取得焦點或產生第二條反白。

	; 將當前操作的按鈕變成「中止」，並停用其它按鈕
	$g_stop = False
	Local $stopBtn = $obf ? $g_btn[3] : $g_btn[2]   ;；混淆→執行混淆；整合→腳本整合
	Local $stopOrig = $obf ? TR("執行混淆") : TR("腳本整合")
	Local $otherBtn = $obf ? $g_btn[2] : $g_btn[3]
	$g_stopBtn = $stopBtn
	GUICtrlSetData($stopBtn, TR("中止"))
	; 立即重畫 owner-draw 按鈕，避免長工作期間看起來仍是「執行混淆」。
	_WinAPI_InvalidateRect(GUICtrlGetHandle($stopBtn))
	_WinAPI_UpdateWindow(GUICtrlGetHandle($stopBtn))
	_DebugTrace("RUN stop button armed id=" & $stopBtn & " caption=" & _WinAPI_GetWindowText(GUICtrlGetHandle($stopBtn)))
	GUICtrlSetState($g_btn[1], $GUI_DISABLE)
	GUICtrlSetState($otherBtn, $GUI_DISABLE)

	_DebugTrace("RUN before FileRead bytes=" & FileGetSize($g_script))
	Local $code = FileRead($g_script)
	If @error Then
		$g_sLastOutputError = "無法讀取來源腳本：" & $g_script
		_DebugTrace("RUN FileRead failed")
		_Status($g_sLastOutputError)
		_EndRun($stopBtn, $stopOrig, $otherBtn)
		If Not $g_batch Then _Msg(16, "讀取失敗", $g_sLastOutputError)
		Return
	EndIf
	_DebugTrace("RUN after FileRead chars=" & StringLen($code))
	Local $srcDir = _DirOf($g_script)
	Local $stem = StringRegExpReplace(StringRegExpReplace($g_script, "^.*\\", ""), "\.[^.]*$", "")

	; 處理日誌：依「輸出日誌」選項啟用
	$g_logOn = (GUICtrlRead($g_chkLog) = $GUI_CHECKED)
	$g_log = ""
	$g_stepT0 = 0
	$g_stepPrev = 0
	Local $tRun = TimerInit()
	_LogLine("===== " & ($obf ? "執行混淆" : "腳本整合") & " 開始 =====")
	_LogLine("來源:" & $g_script & "(" & _SizeStr(FileGetSize($g_script)) & ")")

	Local $ignFunc = _ReadIgnore($code, "Obfuscator_Ignore_Funcs")
	Local $ignVar = _ReadIgnore($code, "Obfuscator_Ignore_Variables")
	_MergeIgnoreUI($ignFunc, GUICtrlRead($g_inIgnFunc)) ;；合併介面輸入的忽略清單
	_MergeIgnoreUI($ignVar, GUICtrlRead($g_inIgnVar))

	; 亂數名稱長度（介面帶入，限制 3-12）
	$g_nameLen = Int(GUICtrlRead($g_inNameLen))
	If $g_nameLen < 3 Then $g_nameLen = 3
	If $g_nameLen > 12 Then $g_nameLen = 12

	Local $doInteg = True
	If $obf Then $doInteg = (GUICtrlRead($g_oUseInteg) = $GUI_CHECKED)

	; [1] 整合
	If $doInteg Then
		_Step(1, "正在整合腳本(合併 #include)…")
		Local $seen = ObjCreate("Scripting.Dictionary")
		Local $cnt[1] = [0]
		$code = _MergeIncludes($code, $srcDir, GUICtrlRead($g_inStd), $seen, $cnt)
		_ExecSet(1, "完成(" & $cnt[0] & " 檔)")
	Else
		_ExecSet(1, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; [2] 預處理：抽出字串與註解
	_Step(2, "正在預處理腳本…")
	Local $strs = ObjCreate("Scripting.Dictionary")
	Local $strRaw = ObjCreate("Scripting.Dictionary")
	Local $strNoEnc = ObjCreate("Scripting.Dictionary")
	Local $strPure = ObjCreate("Scripting.Dictionary")
	Local $cmts = ObjCreate("Scripting.Dictionary")
	_ExtractBlockComments($code, $cmts)
	_ExtractLine($code, $strs, $strRaw, $strNoEnc, $strPure, $cmts)
	_DebugTrace("RUN after string extraction chars=" & StringLen($code))
	_ExecSet(2, "完成")
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	Local $delCmt = (GUICtrlRead($g_iCmt) = $GUI_CHECKED)
	_ExecSet(3, $delCmt ? "將清除" : "保留")
	_ExecSet(4, (GUICtrlRead($g_iBlank) = $GUI_CHECKED) ? "將清除" : "保留")

	; 混淆時若勾選「輸出整合後的腳本」，另存整合檔（未混淆）到同資料夾
	If $obf And GUICtrlRead($g_oOutInteg) = $GUI_CHECKED Then
		If Not _SaveIntegrated($code, $strs, $strRaw, $cmts, $delCmt, $srcDir, $stem) Then
			_DebugTrace("RUN integrated preview failed: " & $g_sLastOutputError)
			_Status("整合預覽檔儲存失敗：" & $g_sLastOutputError)
			_EndRun($stopBtn, $stopOrig, $otherBtn)
			If Not $g_batch Then _Msg(16, "儲存失敗", $g_sLastOutputError)
			Return
		EndIf
	EndIf

	Local $delFunc = (GUICtrlRead($g_iDelFunc) = $GUI_CHECKED)
	Local $delVar = (GUICtrlRead($g_iDelVar) = $GUI_CHECKED)

	Local $obVar = $obf And (GUICtrlRead($g_oVar) = $GUI_CHECKED)
	Local $obVarAdv = $obf And (GUICtrlRead($g_oVarAdv) = $GUI_CHECKED)
	Local $obFunc = $obf And (GUICtrlRead($g_oUdf) = $GUI_CHECKED)
	Local $obFuncAdv = $obf And (GUICtrlRead($g_oUdfAdv) = $GUI_CHECKED)
	Local $obShuf = $obf And (GUICtrlRead($g_oUdfShuf) = $GUI_CHECKED)
	Local $obNum = $obf And (GUICtrlRead($g_oNum) = $GUI_CHECKED)
	$g_strAdvMode = $obf And (GUICtrlRead($g_oStrAdv) = $GUI_CHECKED) ;；進階字串/數字加密方案（供 _EncStr 與 _DecodeStub 同步採用）
	$g_confName = $obf And (GUICtrlRead($g_oConfName) = $GUI_CHECKED) ;；易混淆名稱（供 _RandName 採用）
	$g_negNum = $obf And (GUICtrlRead($g_oNegNum) = $GUI_CHECKED) ;；數字連負號隱藏（供 _EncNumbers 採用）
	$g_rcMode = $obf And (GUICtrlRead($g_rCipherRc) = $GUI_CHECKED) ;；密文置於 RC 資源段
	$g_blob = ""
	Local $strMode = 0
	If $obf Then
		If GUICtrlRead($g_rStrSimple) = $GUI_CHECKED Then $strMode = 1
		If GUICtrlRead($g_rStrEnc) = $GUI_CHECKED Then $strMode = 2
	EndIf

	; [5] 函數列表
	Local $funcs = StringRegExp($code, "(?im)^\s*Func\s+(\w+)", 3)
	_ExecSet(5, (IsArray($funcs) ? UBound($funcs) : 0) & " 個")

	; [6] 清除未使用函數
	If $delFunc Then
		_Step(6, "正在清除未使用函式…")
		_ExecSet(6, _RemoveUnusedFuncs($code, $ignFunc, $strs) & " 個")
	Else
		_ExecSet(6, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; [7] 變量列表
	_ExecSet(7, "掃描完成")

	; [8] 清除未使用變量
	If $delVar Then
		_Step(8, "正在清除未使用變數…")
		_ExecSet(8, _RemoveUnusedVars($code, $ignVar, $strs) & " 個")
	Else
		_ExecSet(8, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; [9] 函數混淆
	If $obFunc Then
		_Step(9, "正在混淆函式名稱…")
		$fmap = _RenameFuncs($code, $ignFunc, $obShuf)
		If $obFuncAdv Then _ApplyAdvFunc($strs, $strRaw, $strPure, $fmap)
		_ExecSet(9, $fmap.Count & " 個" & ($obShuf ? " (已亂序)" : ""))
	ElseIf $obShuf Then
		; 未啟用函式重命名、但單獨要求亂序 → 仍打散函式定義順序
		_Step(9, "正在亂序排列函式…")
		_ShuffleFuncs($code)
		_ExecSet(9, "僅亂序")
	Else
		_ExecSet(9, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

 	; 內建函式隨機名稱包裝（安全白名單）；依「混淆設定」選項決定是否啟用。
	If $obf And GUICtrlRead($g_oBuiltinCase) = $GUI_CHECKED Then
		_DebugTrace("RUN before builtin wrapper chars=" & StringLen($code))
		_Step(9, "正在包裝 AutoIt 內建函式…")
		Local $bwResult = _WrapBuiltinFunctions($code)
		_DebugTrace("RUN after builtin wrapper result=" & $bwResult & " chars=" & StringLen($code))
		If $g_stop Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)
		If $bwResult < 0 Then
			_LogLine("內建函式混淆：因資料不適合安全轉換，已略過本次包裝，原始碼保持原樣。")
			_ExecSet(9, "內建函式已安全略過")
		Else
			_LogLine("內建函式混淆：" & $bwResult & " 處呼叫已包裝（安全白名單）")
			Local $bwSummary = "內建函式 " & $bwResult & " 處"
			If $obFunc And IsObj($fmap) Then $bwSummary = "UDF " & $fmap.Count & " 個；" & $bwSummary
			_ExecSet(9, $bwSummary)
		EndIf
	EndIf

	; [10] 變量混淆
	If $obVar Then
		_Step(10, "正在混淆變數名稱…")
		$vmap = _RenameVars($code, $ignVar, $doInteg)
		If $obVarAdv Then _ApplyAdvVar($strs, $strRaw, $vmap)
		_ExecSet(10, $vmap.Count & " 個")
	Else
		_ExecSet(10, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	Local $key = Random(1, 254, 1)
	Local $usedEnc = False
	Local $numDecls = "" ;；數字加密的預宣告全域變數
	Local $nc = 0 ;；數字加密處數（提升作用域，供完成統計使用）

	; [11] 數字加密
	If $obNum Then
		_Step(11, "正在進行數字加密…")
		$nc = _EncNumbers($code, $key, $numDecls)
		If $nc > 0 Then $usedEnc = True
		_ExecSet(11, $nc & " 處")
	Else
		_ExecSet(11, "略過")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; [12] 字串字面量處理
	If $strMode > 0 Then
		_Step(12, "正在處理字串字面值…")
		If _ApplyStrings($strs, $strRaw, $strNoEnc, $strMode, $key) Then $usedEnc = True
		_ExecSet(12, ($strMode = 1) ? "簡單處理完成" : "加密完成")
	Else
		_ExecSet(12, "不處理")
	EndIf
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; 回填
	_Status("正在回填字串/註解…")
	_Reinsert($code, $strs, $strRaw, $cmts, $delCmt)
	If _CheckStop() Then Return _EndRun($stopBtn, $stopOrig, $otherBtn)

	; 清除 #Region
	If GUICtrlRead($g_iRegion) = $GUI_CHECKED Then
		$code = StringRegExpReplace($code, "(?im)^\s*#(end)?region\b[^\r\n]*\r?\n", "")
	EndIf
	; 清空行、行尾空白
	If GUICtrlRead($g_iBlank) = $GUI_CHECKED Then
		$code = StringRegExpReplace($code, "(?m)[ \t]+(\r?\n)", "\1")
		$code = StringRegExpReplace($code, "(?m)^[ \t]*\r?\n", "")
	EndIf

	; 前置解碼函式 + 數字加密的預宣告全域變數（置於 #AutoIt3Wrapper 等指令之後）
	If $usedEnc Then _InjectAfterDirectives($code, _DecodeStub($key, $stem & "_res.bin") & @CRLF & $numDecls)

	; [13] 保存
	_Step(13, "正在儲存…")
	Local $suffix = $obf ? "_Obfuscation" : "_Integration"
	Local $dst = $srcDir & "\" & $stem & $suffix & ".au3"
	_DebugTrace("RUN before WriteOut dst=" & $dst & " chars=" & StringLen($code))
	If GUICtrlRead($g_oAutoCheck) = $GUI_CHECKED Then _Status("正在驗證暫存輸出（AU3Check）…")
	If Not _WriteOut($dst, $code, True) Then
		_DebugTrace("RUN failed to save/validate: " & $g_sLastOutputError)
		_ExecSet(13, "儲存／驗證失敗")
		_Status("輸出未完成：" & $g_sLastOutputError)
		_EndRun($stopBtn, $stopOrig, $otherBtn)
		If Not $g_batch Then _Msg(16, "輸出失敗（原有檔案未覆蓋）", $g_sLastOutputError)
		Return
	EndIf
	_DebugTrace("RUN after WriteOut bytes=" & FileGetSize($dst))
	If $g_rcMode And $usedEnc Then ;;RC 模式：密文另存為資源用的 .bin(ANSI 無 BOM)
		If Not _WriteBinaryOut($srcDir & "\" & $stem & "_res.bin", $g_blob) Then
			_DebugTrace("RUN RC resource failed: " & $g_sLastOutputError)
			_ExecSet(13, "資源儲存失敗")
			_Status("資源輸出失敗：" & $g_sLastOutputError)
			_EndRun($stopBtn, $stopOrig, $otherBtn)
			If Not $g_batch Then _Msg(16, "RC 資源儲存失敗", $g_sLastOutputError)
			Return
		EndIf
	EndIf
	_ExecSet(13, "已儲存")
	If GUICtrlRead($g_oNameMap) = $GUI_CHECKED And (IsObj($fmap) Or IsObj($vmap)) Then
		Local $mapTxt = "; Obscura 名稱對照表(原名 -> 混淆名) — 請妥善保管,勿隨輸出散佈" & @CRLF
		Local $mk
		If IsObj($fmap) Then
			$mapTxt &= @CRLF & "[函式]" & @CRLF
			For $mk In $fmap.Keys()
				$mapTxt &= $mk & " -> " & $fmap.Item($mk) & @CRLF
			Next
		EndIf
		If IsObj($vmap) Then
			$mapTxt &= @CRLF & "[變數]" & @CRLF
			For $mk In $vmap.Keys()
				$mapTxt &= "$" & $mk & " -> $" & $vmap.Item($mk) & @CRLF
			Next
		EndIf
		If Not _WriteOut($srcDir & "\" & $stem & "_namemap.txt", $mapTxt) Then
			_DebugTrace("RUN warning: name map save failed " & $g_sLastOutputError)
			If Not $g_batch Then _Msg(48, "名稱對照表儲存失敗", $g_sLastOutputError)
		EndIf
	EndIf
	_Status("完成:" & $dst)
	$g_bLastRunOk = True ; 完整輸出與驗證通過才列為成功
	_EndRun($stopBtn, $stopOrig, $otherBtn)

	; --- 結果摘要：原始/輸出大小與縮減比 ---
	Local $srcSize = FileGetSize($g_script), $dstSize = FileGetSize($dst)

	; --- 混淆統計摘要：彙整本次各項目實際處理數量 ---
	Local $sum = "", $sumLine = ""
	If $obf Then
		Local $p = ""
		If $strMode = 2 Then $p &= "字串加密 " & $g_cntStr & " 段　"
		If $strMode = 1 Then $p &= "字串處理 " & $g_cntStr & " 段　"
		If $obNum Then $p &= "數字加密 " & $nc & " 處　"
		If $obFunc Then $p &= "函式改名 " & (IsObj($fmap) ? $fmap.Count : 0) & " 個　"
		If $obVar Then $p &= "變數改名 " & (IsObj($vmap) ? $vmap.Count : 0) & " 個　"
		If $obShuf Then $p &= "函式亂序　"
		If $g_rcMode And $usedEnc Then $p &= "RC 資源封裝　"
		$p = StringStripWS($p, 3)
		If $p <> "" Then
			$sumLine = $p
			$sum = @CRLF & @CRLF & "──── 混淆統計 ────" & @CRLF & $p
		EndIf
	EndIf

	; 寫出處理日誌（若啟用）
	If $g_logOn Then
		If $sumLine <> "" Then _LogLine("混淆統計:" & $sumLine)
		If $g_stepT0 > 0 Then _LogLine("    (步驟 " & $g_stepPrev & " 耗時 " & Round(TimerDiff($g_stepT0) / 1000, 2) & " 秒)") ;；最後一步
		_LogLine("輸出:" & $dst & "(" & _SizeStr($dstSize) & ")")
		If $usedEnc Then _LogLine("字串/數字加密:每段獨立隨機金鑰")
		_LogLine("總耗時:" & Round(TimerDiff($tRun) / 1000, 2) & " 秒")
		_LogLine("===== 完成 =====")
		Local $logPath = $srcDir & "\" & $stem & $suffix & ".log"
		Local $hLog = FileOpen($logPath, 2 + 256)
		If $hLog <> -1 Then
			FileWrite($hLog, $g_log)
			FileClose($hLog)
		EndIf
	EndIf
	Local $delta = ""
	If $srcSize > 0 Then
		Local $pct = Round(($dstSize - $srcSize) / $srcSize * 100, 1)
		$delta = @CRLF & "大小:" & _SizeStr($srcSize) & " → " & _SizeStr($dstSize) & _
				"(" & ($pct >= 0 ? "+" : "") & $pct & "%)"
	EndIf
	Local $extra = ""
	If $obf And GUICtrlRead($g_oOutInteg) = $GUI_CHECKED Then $extra = @CRLF & "整合檔:" & $srcDir & "\" & $stem & "_Integration.au3"
	If $g_logOn Then $extra &= @CRLF & "日誌:" & $srcDir & "\" & $stem & $suffix & ".log"

	If $g_batch Then Return ;；批次模式：不逐檔彈窗，交由批次結束統一回報

	; 若已設定 SciTE，詢問是否開啟輸出檔
	Local $scite = _SciTEPath()
	Local $canOpen = ($scite <> "" And FileExists($scite))
	Local $ans = _Choose3("完成", ($obf ? "混淆" : "整合") & "完成!" & @CRLF & @CRLF & "輸出:" & $dst & $delta & $extra & $sum, _
			"開啟輸出檔", "開啟資料夾", "關閉")
	Switch $ans
		Case 1
			If $canOpen Then
				Run('"' & $scite & '" "' & $dst & '"', _DirOf($scite))
			Else
				ShellExecute($dst)
			EndIf
		Case 2
			ShellExecute($srcDir)
	EndSwitch
EndFunc   ;==>_RunProcess

; 以 Windows LCMapString 做繁↔简轉換（僅影響中文字元，ASCII 不變）
Func _CnConvert($s, $toSimp)
	If $s = "" Then Return ""
	Local $flag = $toSimp ? 0x02000000 : 0x04000000 ;;LCMAP_SIMPLIFIED / LCMAP_TRADITIONAL_CHINESE
	Local $len = StringLen($s)
	Local $a = DllCall("kernel32.dll", "int", "LCMapStringW", "dword", 0x0404, "dword", $flag, _
			"wstr", $s, "int", $len, "ptr", 0, "int", 0)
	If @error Or Not IsArray($a) Or $a[0] = 0 Then Return SetError(1, 0, $s)
	Local $tDst = DllStructCreate("wchar[" & ($a[0] + 1) & "]")
	Local $b = DllCall("kernel32.dll", "int", "LCMapStringW", "dword", 0x0404, "dword", $flag, _
			"wstr", $s, "int", $len, "struct*", $tDst, "int", $a[0])
	If @error Or Not IsArray($b) Or $b[0] = 0 Then Return SetError(2, 0, $s)
	Return DllStructGetData($tDst, 1)
EndFunc   ;==>_CnConvert

; 對載入的腳本做繁簡轉換並輸出
Func _LangConvertScript($toSimp)
	If $g_script = "" Or Not FileExists($g_script) Then
		_Msg(48, "提示", "請先載入腳本。")
		Return
	EndIf
	Local $out = _CnConvert(FileRead($g_script), $toSimp)
	If @error Then
		_Msg(16, "錯誤", "繁簡轉換失敗(LCMapString 回傳錯誤)。")
		Return
	EndIf
	Local $stem = StringRegExpReplace(_NameOf($g_script), "\.[^.]*$", "")
	Local $dst = _DirOf($g_script) & "\" & $stem & ($toSimp ? "_SC" : "_TC") & ".au3"
	If Not _WriteOut($dst, $out) Then Return _Msg(16, "轉換輸出失敗", $g_sLastOutputError)
	_Msg(64, "完成", ($toSimp ? "繁體 → 简体" : "简体 → 繁體") & "轉換完成:" & @CRLF & $dst)
EndFunc   ;==>_LangConvertScript

; 位元組大小轉易讀字串
Func _SizeStr($n)
	If $n >= 1048576 Then Return Round($n / 1048576, 2) & " MB"
	If $n >= 1024 Then Return Round($n / 1024, 1) & " KB"
	Return $n & " B"
EndFunc   ;==>_SizeStr

; 狀態列
Func _Status($txt)
	GUICtrlSetData($g_status, TR($txt))
EndFunc   ;==>_Status

; 在步驟之間輪詢是否按下「中止」（處理期間事件迴圈被佔用）
Func _CheckStop()
	_TitleButtonsPoll() ;；處理中仍可用 − / ✕（變色）
	Local $m = GUIGetMsg() ;；標題列拖曳由 $GUI_WS_EX_PARENTDRAG 處理
	If $m = $GUI_EVENT_CLOSE Then Exit
	_RunHandleStopClick($m)
	Return $g_stop
EndFunc   ;==>_CheckStop

; 還原按鈕狀態（成功或中止後呼叫）
Func _EndRun($stopBtn, $stopOrig, $otherBtn)
	_DebugTrace("RUN EndRun stop=" & $g_stop)
	$g_bRunBusy = False
	GUICtrlSetData($stopBtn, $stopOrig)
	GUICtrlSetState($stopBtn, $GUI_ENABLE)
	GUICtrlSetState($g_btn[1], $GUI_ENABLE)
	GUICtrlSetState($otherBtn, $GUI_ENABLE)
	$g_stopBtn = 0
	$g_iRunStopClickSerial = 0
	_WinAPI_InvalidateRect(GUICtrlGetHandle($stopBtn))
	_WinAPI_UpdateWindow(GUICtrlGetHandle($stopBtn))
	_ExecDone()
	If $g_stop Then _Status("已中止。")
	_UpdateToolbar()
EndFunc   ;==>_EndRun

; 依是否已載入腳本，啟用/停用工具列功能鈕
Func _UpdateToolbar()
	Local $on = ($g_script <> "" And FileExists($g_script)) ? $GUI_ENABLE : $GUI_DISABLE
	GUICtrlSetState($g_btn[1], $on) ;；程式碼檢測
	GUICtrlSetState($g_btn[2], $on) ;；腳本整合
	GUICtrlSetState($g_btn[3], $on) ;；執行混淆
	GUICtrlSetState($g_btn[5], $on) ;；開啟資料夾
	GUICtrlSetState($g_btn[6], $on) ;；開啟腳本
EndFunc   ;==>_UpdateToolbar

; 混淆強度一鍵預設 ----------------------------------------------------
Func _SetChk($id, $on)
	GUICtrlSetState($id, $on ? $GUI_CHECKED : $GUI_UNCHECKED)
EndFunc   ;==>_SetChk

; 最強保護：開啟所有安全的強化項（不含風險啟發式「清除未使用」）
Func _PresetMax()
	_SetChk($g_iCmt, True)
	_SetChk($g_iBlank, True)
	_SetChk($g_iRegion, True)
	_SetChk($g_iJoin, True)
	_SetChk($g_iDllRen, True)
	_SetChk($g_iSort, True)
	_SetChk($g_iDelFunc, False) ;；風險啟發式維持關
	_SetChk($g_iDelVar, False)
	_SetChk($g_iMaxLen, False)
	_SetChk($g_oUseInteg, True)
	_SetChk($g_oOutInteg, True) ;;最強保護:輸出整合後的腳本
	_SetChk($g_oUdf, True)
	_SetChk($g_oUdfAdv, True)
	_SetChk($g_oUdfShuf, True)
	_SetChk($g_oVar, True)
	_SetChk($g_oVarAdv, True)
	_SetChk($g_oNum, True)
	_SetChk($g_oStrAdv, True)
	_SetChk($g_oConfName, True)
	_SetChk($g_oBuiltinCase, True) ;;最強保護:內建函式混淆
	_SetChk($g_oNegNum, True)
	GUICtrlSetState($g_rStrEnc, $GUI_CHECKED) ;；字串加密處理
	GUICtrlSetState($g_rCipherRc, $GUI_CHECKED) ;;最強保護:密文置於 RC 資源段
	_SyncDeps() ;;更新子選項反灰狀態
	_Status("已套用「最強保護」預設(風險啟發式未啟用,請自行斟酌)")
	_CfgSave()
EndFunc   ;==>_PresetMax

; 標準：回到建立時的預設值
Func _PresetStd()
	_SetChk($g_iCmt, True)
	_SetChk($g_iBlank, True)
	_SetChk($g_iRegion, True)
	_SetChk($g_iJoin, True)
	_SetChk($g_iDllRen, True)
	_SetChk($g_iSort, True)
	_SetChk($g_iDelFunc, False)
	_SetChk($g_iDelVar, False)
	_SetChk($g_iMaxLen, False)
	_SetChk($g_oUseInteg, True)
	_SetChk($g_oOutInteg, True)
	_SetChk($g_oUdf, True)
	_SetChk($g_oUdfAdv, True)
	_SetChk($g_oUdfShuf, True)
	_SetChk($g_oVar, True)
	_SetChk($g_oVarAdv, True)
	_SetChk($g_oNum, False)
	_SetChk($g_oStrAdv, False)
	_SetChk($g_oConfName, False)
	_SetChk($g_oBuiltinCase, False)
	_SetChk($g_oNegNum, False)
	GUICtrlSetState($g_rStrEnc, $GUI_CHECKED)
	_Status("已回到標準預設")
	_CfgSave()
EndFunc   ;==>_PresetStd

; ==================================================================
;  忽略指令
; ==================================================================
; 混淆流程中，輸出「整合後（未混淆）」的腳本到同資料夾（供對照除錯）
Func _SaveIntegrated($codeClone, $strs, $strRaw, $cmts, $delCmt, $dir, $stem)
	Local $ic = $codeClone
	_Reinsert($ic, $strs, $strRaw, $cmts, $delCmt) ;；此時 strRaw 仍為原字串（尚未加密/進階替換）
	If GUICtrlRead($g_iRegion) = $GUI_CHECKED Then $ic = StringRegExpReplace($ic, "(?im)^\s*#(end)?region\b[^\r\n]*\r?\n", "")
	If GUICtrlRead($g_iBlank) = $GUI_CHECKED Then
		$ic = StringRegExpReplace($ic, "(?m)[ \t]+(\r?\n)", "\1")
		$ic = StringRegExpReplace($ic, "(?m)^[ \t]*\r?\n", "")
	EndIf
	Return _WriteOut($dir & "\" & $stem & "_Integration.au3", $ic)
EndFunc   ;==>_SaveIntegrated

Func _ReadIgnore($code, $tag)
	Local $m = StringRegExp($code, "(?im)^\s*#" & $tag & "\s*=\s*([^\r\n]+)", 3)
	Local $list[0]
	If Not IsArray($m) Then Return $list
	For $i = 0 To UBound($m) - 1
		Local $parts = StringSplit(StringStripWS($m[$i], 3), ",")
		For $j = 1 To $parts[0]
			Local $p = StringStripWS($parts[$j], 3)
			If $p <> "" Then _ArrayAdd($list, $p)
		Next
	Next
	Return $list
EndFunc   ;==>_ReadIgnore

Func _IsIgnored($name, $list)
	For $i = 0 To UBound($list) - 1
		If StringRegExp($name, "(?i)^(" & $list[$i] & ")$") Then Return True
	Next
	Return False
EndFunc   ;==>_IsIgnored

; 把介面輸入的忽略清單（逗號分隔正則）併入清單
Func _MergeIgnoreUI(ByRef $list, $text)
	Local $parts = StringSplit(StringStripWS($text, 3), ",")
	For $j = 1 To $parts[0]
		Local $p = StringStripWS($parts[$j], 3)
		If $p <> "" Then _ArrayAdd($list, $p)
	Next
EndFunc   ;==>_MergeIgnoreUI

; ==================================================================
;  合併 #include
; ==================================================================
Func _MergeIncludes($code, $baseDir, $incDir, $seen, ByRef $cnt)
	Local $DQ = Chr(34), $SQ = Chr(39)
	Local $pat = "(?i)^\s*#include\s+([" & $DQ & $SQ & "<])([^" & $DQ & $SQ & "<>]+)[" & $DQ & $SQ & ">]"
	Local $lines = StringSplit($code, @LF, 1)
	Local $out = "", $chunk = ""
	For $i = 1 To $lines[0]
		If Mod($i, 200) = 0 Then
			$out &= $chunk
			$chunk = ""
			_Pump()
		EndIf
		Local $ln = $lines[$i]
		If StringRegExp($ln, "(?i)^\s*#include-once\b") Then ContinueLoop ;；合併後 #include-once 已無意義，直接移除
		Local $m = StringRegExp($ln, $pat, 2)
		If IsArray($m) Then
			Local $delim = $m[1], $fname = $m[2], $path = ""
			If $delim = "<" Then
				If $incDir <> "" Then $path = $incDir & "\" & $fname
			Else
				$path = $baseDir & "\" & $fname
			EndIf
			If $path <> "" And FileExists($path) Then
				Local $full = _FullPath($path)
				If $seen.Exists(StringLower($full)) Then ContinueLoop
				$seen.Add(StringLower($full), 1)
				$cnt[0] += 1
				Local $sub = FileRead($full)
				$sub = _MergeIncludes($sub, _DirOf($full), $incDir, $seen, $cnt)
				$out &= $chunk & $sub & @LF ;；先清暫存再接子檔，維持順序
				$chunk = ""
				ContinueLoop
			EndIf
		EndIf
		$chunk &= $ln & @LF
	Next
	Return StringTrimRight($out & $chunk, 1)
EndFunc   ;==>_MergeIncludes

; ==================================================================
;  抽出區塊註解
; ==================================================================
Func _ExtractBlockComments(ByRef $code, $cmts)
	; 快速路徑：整檔無區塊註解起始 → 直接返回
	If Not StringInStr($code, "#cs") And Not StringInStr($code, "#comments-start") Then Return
	Local $lines = StringSplit($code, @LF, 1)
	Local $out = "", $chunk = "", $i = 1
	While $i <= $lines[0]
		If Mod($i, 200) = 0 Then
			$out &= $chunk
			$chunk = ""
			_Pump()
		EndIf
		Local $ln = $lines[$i]
		If StringInStr($ln, "#") And StringRegExp(StringStripWS($ln, 1), "(?i)^#(cs|comments-start)\b") Then
			Local $block = $ln & @LF
			$i += 1
			While $i <= $lines[0]
				$block &= $lines[$i] & @LF
				If StringRegExp(StringStripWS($lines[$i], 1), "(?i)^#(ce|comments-end)\b") Then ExitLoop
				$i += 1
			WEnd
			$chunk &= Chr(4) & _CmtAdd($cmts, StringTrimRight($block, 1)) & Chr(5) & @LF
		Else
			$chunk &= $ln & @LF
		EndIf
		$i += 1
	WEnd
	$out &= $chunk
	$code = StringTrimRight($out, 1)
EndFunc   ;==>_ExtractBlockComments

; ==================================================================
;  逐行抽出字串 + 行註解
; ==================================================================
Func _ExtractLine(ByRef $code, $strs, $strRaw, $strNoEnc, $strPure, $cmts)
	Local $lines = StringSplit($code, @LF, 1)
	Local $out = "", $chunk = ""
	For $li = 1 To $lines[0]
		$chunk &= _ProcessLine($lines[$li], $strs, $strRaw, $strNoEnc, $strPure, $cmts) & @LF
		If Mod($li, 200) = 0 Then
			$out &= $chunk
			$chunk = ""
			If _Progress($li, $lines[0]) Then ExitLoop
		EndIf
	Next
	$out &= $chunk
	$code = StringTrimRight($out, 1)
EndFunc   ;==>_ExtractLine

Func _ProcessLine($ln, $strs, $strRaw, $strNoEnc, $strPure, $cmts)
	; 快速路徑：整行無引號也無分號 → 原樣返回（大幅加速）
	If Not StringInStr($ln, '"') And Not StringInStr($ln, "'") And Not StringInStr($ln, ";") Then Return $ln
	Local $cr = ""
	If StringRight($ln, 1) = @CR Then
		$cr = @CR
		$ln = StringTrimRight($ln, 1)
	EndIf
	Local $noEncLine = False
	If StringRegExp($ln, "(?i)^\s*(Global\s+|Local\s+|Dim\s+|Static\s+)?Const\b") Then $noEncLine = True
	If StringRegExp($ln, "(?i)^\s*Func\b") Then $noEncLine = True
	If StringRegExp($ln, "^\s*#") Then $noEncLine = True ;;# 指令行的字串絕不加密

	Local $res = "", $n = StringLen($ln), $i = 1
	While $i <= $n
		Local $c = StringMid($ln, $i, 1)
		If $c = '"' Or $c = "'" Then
			; 用 StringInStr 跳到收尾引號（處理成對 ""/''），避免逐字掃描
			Local $q = $c, $j = $i + 1
			While 1
				Local $qp = StringInStr($ln, $q, 0, 1, $j)
				If $qp = 0 Then
					$j = $n + 1
					ExitLoop
				EndIf
				If $qp < $n And StringMid($ln, $qp + 1, 1) = $q Then
					$j = $qp + 2
				Else
					$j = $qp + 1
					ExitLoop
				EndIf
			WEnd
			Local $raw = StringMid($ln, $i, $j - $i)
			Local $inner = StringReplace(StringMid($raw, 2, StringLen($raw) - 2), $q & $q, $q)
			Local $thisNoEnc = $noEncLine
			If StringRegExp($res, "(?i)FileInstall\s*\(\s*$") Then $thisNoEnc = True
			Local $pure = (StringRegExp($inner, "^\$?\w+$") = 1)
			$res &= Chr(2) & _StrAdd($strs, $strRaw, $strNoEnc, $strPure, $inner, $raw, $thisNoEnc, $pure) & Chr(3)
			$i = $j
		ElseIf $c = ";" Then
			$res &= Chr(4) & _CmtAdd($cmts, StringMid($ln, $i)) & Chr(5)
			$i = $n + 1
		Else
			; 整段複製到下一個特殊字元為止（避免逐字累加）
			Local $p1 = StringInStr($ln, '"', 0, 1, $i)
			Local $p2 = StringInStr($ln, "'", 0, 1, $i)
			Local $p3 = StringInStr($ln, ";", 0, 1, $i)
			Local $next = $n + 1
			If $p1 > 0 And $p1 < $next Then $next = $p1
			If $p2 > 0 And $p2 < $next Then $next = $p2
			If $p3 > 0 And $p3 < $next Then $next = $p3
			$res &= StringMid($ln, $i, $next - $i)
			$i = $next
		EndIf
	WEnd
	Return $res & $cr
EndFunc   ;==>_ProcessLine

; ==================================================================
;  函式混淆(+ 可選亂序)
; ==================================================================
Func _RenameFuncs(ByRef $code, $ignList, $shuffle)
	Local $map = ObjCreate("Scripting.Dictionary")
	Local $found = StringRegExp($code, "(?im)^\s*Func\s+(\w+)", 3)
	If IsArray($found) Then
		For $i = 0 To UBound($found) - 1
			Local $low = StringLower($found[$i])
			If _IsIgnored($found[$i], $ignList) Then ContinueLoop
			If Not $map.Exists($low) Then $map.Add($low, _RandName())
		Next
		Local $done = 0, $total = $map.Count
		For $k In $map.Keys()
			$code = StringRegExpReplace($code, "(?i)(?<![0-9A-Za-z_\$@.])" & $k & "(?![0-9A-Za-z_])", $map.Item($k))
			$done += 1
			If _Progress($done, $total) Then ExitLoop ;;每項都 pump:每輪皆整份掃描,保持可拖曳/可中止
		Next
	EndIf
	If $shuffle Then _ShuffleFuncs($code)
	Return $map
EndFunc   ;==>_RenameFuncs

Func _ShuffleFuncs(ByRef $code)
	Local $lines = StringSplit($code, @LF, 1)
	Local $head = "", $blocks[0], $cur = "", $in = False
	For $i = 1 To $lines[0]
		Local $ln = $lines[$i]
		If Not $in And StringRegExp(StringStripWS($ln, 1), "(?i)^Func\b") Then
			$in = True
			$cur = $ln & @LF
		ElseIf $in Then
			$cur &= $ln & @LF
			If StringRegExp(StringStripWS($ln, 1), "(?i)^EndFunc\b") Then
				_ArrayAdd($blocks, $cur)
				$in = False
				$cur = ""
			EndIf
		Else
			$head &= $ln & @LF
		EndIf
	Next
	For $i = UBound($blocks) - 1 To 1 Step -1
		Local $j = Random(0, $i, 1)
		Local $t = $blocks[$i]
		$blocks[$i] = $blocks[$j]
		$blocks[$j] = $t
	Next
	Local $out = $head
	For $i = 0 To UBound($blocks) - 1
		$out &= $blocks[$i]
	Next
	$code = StringTrimRight($out, 1)
EndFunc   ;==>_ShuffleFuncs

; ==================================================================
;  變數混淆
; ==================================================================
; 蒐集「本程式碼中有宣告」的變數名(小寫集合):Global/Local/Dim/Static/Const 宣告目標、函式參數、For 迴圈變數。
; 用來判斷哪些 $var 可安全改名;未宣告者(來自未合併的 include 或內建常數)一律不改。
Func _CollectDeclaredVars($code)
	Local $set = ObjCreate("Scripting.Dictionary")
	Local $lines = StringSplit(StringStripCR($code), @LF)
	Local $i, $j
	For $i = 1 To $lines[0]
		Local $ln = $lines[$i]
		If Mod($i, 400) = 0 Then _Pump()
		; 宣告語句:取關鍵字後、逗號分隔的每段「= 之前」的首個 $var
		Local $kw = StringRegExp($ln, "(?i)^\s*(?:Global|Local|Dim|Static|Const)\b\s*(.*)$", 3)
		If IsArray($kw) Then
			Local $rest = StringRegExpReplace($kw[0], "(?i)^Const\b\s*", "")
			Local $parts = StringSplit($rest, ",", 2)
			For $j = 0 To UBound($parts) - 1
				Local $seg = $parts[$j]
				Local $eq = StringInStr($seg, "=")
				If $eq > 0 Then $seg = StringLeft($seg, $eq - 1) ;;只看 = 之前(宣告目標)
				Local $vm = StringRegExp($seg, "(\$\w+)", 3)
				If IsArray($vm) Then $set.Item(StringLower(StringTrimLeft($vm[0], 1))) = 1
			Next
		EndIf
		; 函式參數列(含 ByRef / 預設值)
		Local $fp = StringRegExp($ln, "(?i)^\s*Func\s+\w+\s*\((.*)\)", 3)
		If IsArray($fp) Then
			Local $ps = StringRegExp($fp[0], "\$\w+", 3)
			If IsArray($ps) Then
				For $j = 0 To UBound($ps) - 1
					$set.Item(StringLower(StringTrimLeft($ps[$j], 1))) = 1
				Next
			EndIf
		EndIf
		; For 迴圈變數
		Local $fv = StringRegExp($ln, "(?i)^\s*For\s+(\$\w+)", 3)
		If IsArray($fv) Then $set.Item(StringLower(StringTrimLeft($fv[0], 1))) = 1
	Next
	Return $set
EndFunc   ;==>_CollectDeclaredVars

Func _RenameVars(ByRef $code, $ignList, $merged)
	#forceref $merged
	Local $map = ObjCreate("Scripting.Dictionary")
	Local $decl = _CollectDeclaredVars($code) ;;只混淆「本程式確實有宣告」的變數
	Local $found = StringRegExp($code, "\$\w+", 3)
	If Not IsArray($found) Then Return $map
	Local $excl = "|cmdline|cmdlineraw|"
	For $i = 0 To UBound($found) - 1
		Local $name = StringTrimLeft($found[$i], 1)
		Local $low = StringLower($name)
		If StringInStr($excl, "|" & $low & "|") Then ContinueLoop
		If Not $decl.Exists($low) Then ContinueLoop ;;未在本程式宣告(來自未合併的 include 或內建常數)→ 不改名,避免「未宣告的全域變數」
		If StringRegExp($name, "^[A-Z0-9_]+$") Then ContinueLoop ;;全大寫常數(含標準庫常數)一律不改
		If _IsIgnored($name, $ignList) Then ContinueLoop
		If Not $map.Exists($low) Then $map.Add($low, _RandName())
	Next
	Local $done = 0, $total = $map.Count
	For $k In $map.Keys()
		$code = StringRegExpReplace($code, "(?i)\$" & $k & "(?![0-9A-Za-z_])", "$" & $map.Item($k))
		$done += 1
		If _Progress($done, $total) Then ExitLoop ;;每項都 pump:每輪皆整份掃描,保持可拖曳/可中止
	Next
	Return $map
EndFunc   ;==>_RenameVars

; 進階:字串「包含且僅包含」函式名 → 一併改,並更新原字面量
Func _ApplyAdvFunc($strs, $strRaw, $strPure, $fmap)
	If $strs.Count = 0 Then Return
	For $k In $strs.Keys()
		If Not $strPure.Item($k) Then ContinueLoop
		Local $v = $strs.Item($k)
		If StringLeft($v, 1) = "$" Then ContinueLoop
		Local $low = StringLower($v)
		If $fmap.Exists($low) Then
			$strs.Item($k) = $fmap.Item($low)
			$strRaw.Item($k) = _ReQuote($fmap.Item($low))
		EndIf
	Next
EndFunc   ;==>_ApplyAdvFunc

; 進階:字串內含完整變數名($xxx)→ 一併替換
Func _ApplyAdvVar($strs, $strRaw, $vmap)
	If $strs.Count = 0 Then Return
	For $k In $strs.Keys()
		Local $v = $strs.Item($k)
		If Not StringInStr($v, "$") Then ContinueLoop
		Local $orig = $v
		For $vk In $vmap.Keys()
			$v = StringRegExpReplace($v, "(?i)\$" & $vk & "(?![0-9A-Za-z_])", "$" & $vmap.Item($vk))
		Next
		If $v <> $orig Then
			$strs.Item($k) = $v
			$strRaw.Item($k) = _ReQuote($v)
		EndIf
	Next
EndFunc   ;==>_ApplyAdvVar

Func _ReQuote($s)
	Return '"' & StringReplace($s, '"', '""') & '"'
EndFunc   ;==>_ReQuote

; ==================================================================
;  精簡未使用函式（啟發式）
; ==================================================================
; 效率版：每回合只建一次「識別字計數表」(O（檔案大小）)，一次批次移除本回合未使用的函式；
; 多回合處理連鎖（被移除函式所呼叫者），每回合讓出訊息並檢查中止 → 大型檔不再卡死、終止有效。
Func _RemoveUnusedFuncs(ByRef $code, $ignList, $strs)
	Local $removed = 0, $pass = 0
	While Not $g_stop And $pass < 12
		$pass += 1
		Local $cnt = _TokenCount($code, $strs, "[A-Za-z_]\w*") ;；一次統計全部識別字出現次數
		If _Pump() Then ExitLoop
		Local $found = StringRegExp($code, "(?im)^\s*Func\s+(\w+)", 3)
		If Not IsArray($found) Then ExitLoop
		Local $dead = ObjCreate("Scripting.Dictionary"), $i
		For $i = 0 To UBound($found) - 1
			Local $name = $found[$i]
			If _IsIgnored($name, $ignList) Then ContinueLoop
			Local $lw = StringLower($name)
			Local $c = $cnt.Exists($lw) ? $cnt.Item($lw) : 0
			If $c <= 1 Then $dead.Item($lw) = 1 ;；只出現 1 次（僅定義處）→ 未使用
		Next
		If $dead.Count = 0 Then ExitLoop
		$removed += _RemoveFuncBlocks($code, $dead)
		If _Progress($removed, $removed) Then ExitLoop
	WEnd
	Return $removed
EndFunc   ;==>_RemoveUnusedFuncs

; 一次移除多個函式區塊（$dead：小寫名稱集合），單次掃描全檔
Func _RemoveFuncBlocks(ByRef $code, $dead)
	Local $lines = StringSplit(StringStripCR($code), @LF)
	Local $out = "", $chunk = "", $in = False, $n = 0, $i
	For $i = 1 To $lines[0]
		If Mod($i, 800) = 0 Then
			$out &= $chunk
			$chunk = ""
			_Pump()
		EndIf
		Local $ln = $lines[$i]
		If Not $in Then
			Local $m = StringRegExp(StringStripWS($ln, 1), "(?i)^Func\s+(\w+)", 1)
			If IsArray($m) And $dead.Exists(StringLower($m[0])) Then
				$in = True
				$n += 1
				ContinueLoop
			EndIf
			$chunk &= $ln & @LF
		Else
			If StringRegExp(StringStripWS($ln, 1), "(?i)^EndFunc\b") Then $in = False
			ContinueLoop
		EndIf
	Next
	$out &= $chunk
	$code = StringTrimRight($out, 1)
	Return $n
EndFunc   ;==>_RemoveFuncBlocks

; 統計 $code（與 $strs 內字串）中，符合 $pat 的識別字出現次數 → 字典（小寫鍵）
Func _TokenCount($code, $strs, $pat)
	Local $d = ObjCreate("Scripting.Dictionary")
	_AddTokens($d, $code, $pat)
	If IsObj($strs) Then
		Local $k
		For $k In $strs.Keys()
			_AddTokens($d, $strs.Item($k), $pat)
		Next
	EndIf
	Return $d
EndFunc   ;==>_TokenCount

Func _AddTokens($d, $s, $pat)
	Local $a = StringRegExp($s, $pat, 3)
	If Not IsArray($a) Then Return
	Local $w, $lw
	For $w In $a
		$lw = StringLower($w)
		If $d.Exists($lw) Then
			$d.Item($lw) = $d.Item($lw) + 1
		Else
			$d.Add($lw, 1)
		EndIf
	Next
EndFunc   ;==>_AddTokens

Func _CountWord($code, $name)
	Local $m = StringRegExp($code, "(?i)(?<![0-9A-Za-z_\$@.])" & $name & "(?![0-9A-Za-z_])", 3)
	If IsArray($m) Then Return UBound($m)
	Return 0
EndFunc   ;==>_CountWord

Func _CountStr($strs, $name, $isVar)
	Local $c = 0
	For $k In $strs.Keys()
		Local $v = $strs.Item($k)
		If $isVar Then
			If StringLower($v) = StringLower($name) Or StringLower($v) = StringLower("$" & $name) Then $c += 1
		Else
			If StringLower($v) = StringLower($name) Then $c += 1
		EndIf
	Next
	Return $c
EndFunc   ;==>_CountStr

Func _RemoveFuncBlock(ByRef $code, $name)
	Local $lines = StringSplit($code, @LF, 1)
	Local $out = "", $in = False, $done = False
	For $i = 1 To $lines[0]
		Local $ln = $lines[$i]
		If Not $in And StringRegExp(StringStripWS($ln, 1), "(?i)^Func\s+" & $name & "(?![0-9A-Za-z_])") Then
			$in = True
			$done = True
			ContinueLoop
		ElseIf $in Then
			If StringRegExp(StringStripWS($ln, 1), "(?i)^EndFunc\b") Then $in = False
			ContinueLoop
		EndIf
		$out &= $ln & @LF
	Next
	$code = StringTrimRight($out, 1)
	Return $done
EndFunc   ;==>_RemoveFuncBlock

; 效率版：一次建立「$變數計數表」，批次刪除只用一次、且為單一宣告整行的未使用變數（多宣告逗號行不動，避免誤刪）。
Func _RemoveUnusedVars(ByRef $code, $ignList, $strs)
	Local $cnt = _TokenCount($code, $strs, "\$\w+") ;；鍵為含 $ 的小寫名
	If _Pump() Then Return 0
	Local $found = StringRegExp($code, "\$\w+", 3)
	If Not IsArray($found) Then Return 0
	Local $seen = ObjCreate("Scripting.Dictionary"), $dead = ObjCreate("Scripting.Dictionary"), $i
	For $i = 0 To UBound($found) - 1
		If Mod($i, 3000) = 0 Then
			If _Progress($i, UBound($found)) Then ExitLoop
		EndIf
		Local $name = StringTrimLeft($found[$i], 1)
		Local $lw = StringLower($name)
		If $seen.Exists($lw) Then ContinueLoop
		$seen.Add($lw, 1)
		If _IsIgnored($name, $ignList) Then ContinueLoop
		Local $c = $cnt.Exists("$" & $lw) ? $cnt.Item("$" & $lw) : 0
		If $c <= 1 Then $dead.Item($lw) = 1
	Next
	If $dead.Count = 0 Then Return 0
	; 單次掃描，刪除未使用變數的「單一宣告整行」
	Local $lines = StringSplit(StringStripCR($code), @LF)
	Local $out = "", $chunk = "", $removed = 0
	For $i = 1 To $lines[0]
		If Mod($i, 800) = 0 Then
			$out &= $chunk
			$chunk = ""
			_Pump()
		EndIf
		Local $ln = $lines[$i]
		Local $m = StringRegExp(StringStripWS($ln, 1), "(?i)^(?:Local|Global|Dim|Static)\s+\$(\w+)\s*(?:=[^,\r\n]*)?$", 1) ;；僅單一宣告行
		If IsArray($m) And $dead.Exists(StringLower($m[0])) Then
			$removed += 1
			ContinueLoop ;；刪除此行
		EndIf
		$chunk &= $ln & @LF
	Next
	$out &= $chunk
	$code = StringTrimRight($out, 1)
	Return $removed
EndFunc   ;==>_RemoveUnusedVars

Func _CountVar($code, $name)
	Local $m = StringRegExp($code, "(?i)\$" & $name & "(?![0-9A-Za-z_])", 3)
	If IsArray($m) Then Return UBound($m)
	Return 0
EndFunc   ;==>_CountVar

; ==================================================================
;  數字加密：數字字面量 → Number(_xd("hex"))
;  （排除字串/註解佔位符 \x02..\x05；跳過 Const/Func/# 開頭行）
; ==================================================================
Func _EncNumbers(ByRef $code, $key, ByRef $decls)
	; 相同數值共用一個預宣告全域變數（只解碼一次），並以 $變數 取代原數字。
	; 需常量的位置（Const / Enum / Func 標頭預設參數 / # 指令）不處理，保留原數字。
	Local $map = ObjCreate("Scripting.Dictionary") ;；數值字串 -> 變數名
	Local $lines = StringSplit($code, @LF, 1)
	Local $out = "", $count = 0
	; 數字樣式：十六進位 | 浮點（含無整數部 .5 與科學記號）| 科學記號 | 整數。負數的 - 為運算子，不納入字面量。
	Local $neg = $g_negNum ? "-?" : "" ;；連負號隱藏時，字面量前可含一元負號（二元減號由 lookbehind 排除）
	; lookbehind 多排除 ) ] 與字串/註解佔位結尾（\x03 \x05）：這些後面的 - 一定是二元減號，不可當成負號字面量
	Local $pat = "(?i)(?<![0-9A-Za-z_\$@.\x02\x03\x04\x05)\]])(" & $neg & "(?:0x[0-9a-f]+|\d*\.\d+(?:e[+-]?\d+)?|\d+e[+-]?\d+|\d+))(?![0-9A-Za-z_.\x03\x05])"
	For $li = 1 To $lines[0]
		If Mod($li, 100) = 0 Then
			If _Progress($li, $lines[0]) Then ExitLoop
		EndIf
		Local $ln = $lines[$li]
		Local $trim = StringStripWS($ln, 1)
		If StringRegExp($trim, "(?i)^(Global\s+|Local\s+|Dim\s+|Static\s+)?Const\b") Or _
				StringRegExp($trim, "(?i)^(Global\s+|Local\s+)?Enum\b") Or _
				StringRegExp($trim, "(?i)^Func\b") Or StringLeft($trim, 1) = "#" Then
			$out &= $ln & @LF
			ContinueLoop
		EndIf
		Local $new = StringRegExpReplace($ln, $pat, Chr(6) & "\1" & Chr(6))
		While StringInStr($new, Chr(6))
			Local $m = StringRegExp($new, Chr(6) & "([^" & Chr(6) & "]+)" & Chr(6), 1)
			If Not IsArray($m) Then ExitLoop
			Local $numTxt = $m[0]
			; 略過極常見的 0 / 1（加密它們只會徒增體積與雜訊，無保護意義）
			If StringRegExp($numTxt, "^\d+$") And (Number($numTxt) = 0 Or Number($numTxt) = 1) Then
				$new = StringReplace($new, Chr(6) & $numTxt & Chr(6), $numTxt, 1)
				ContinueLoop
			EndIf
			; 正規化數值；負號分離處理，避免 Number("-0x..") 解析問題
			Local $sign = 1, $core = $numTxt
			If StringLeft($numTxt, 1) = "-" Then
				$sign = -1
				$core = StringTrimLeft($numTxt, 1)
			EndIf
			Local $val = String(Number($core) * $sign)
			Local $var
			If $map.Exists($val) Then
				$var = $map.Item($val)
			Else
				$var = _RandName()
				$map.Add($val, $var)
				$decls &= "Global $" & $var & " = Number(" & _CipherRef(_EncStr($val, $key)) & ")" & @CRLF
			EndIf
			$new = StringReplace($new, Chr(6) & $numTxt & Chr(6), "$" & $var, 1)
			$count += 1
		WEnd
		$out &= $new & @LF
	Next
	$code = StringTrimRight($out, 1)
	Return $count
EndFunc   ;==>_EncNumbers

; ==================================================================
;  字串處理
; ==================================================================
Func _ApplyStrings($strs, $strRaw, $strNoEnc, $mode, $key)
	Local $used = False
	$g_cntStr = 0
	If $strs.Count = 0 Then Return False
	Local $done = 0, $total = $strs.Count
	For $k In $strs.Keys()
		$done += 1
		If Mod($done, 50) = 0 Then
			If _Progress($done, $total) Then ExitLoop
		EndIf
		If $strNoEnc.Item($k) Then ContinueLoop
		Local $v = $strs.Item($k)
		If $v = "" Then ContinueLoop
		If $mode = 1 Then
			$strRaw.Item($k) = "BinaryToString(" & StringToBinary($v, 4) & ", 4)"
		Else
			$strRaw.Item($k) = _CipherRef(_EncStr($v, $key))
			$used = True
		EndIf
		$g_cntStr += 1
	Next
	Return $used
EndFunc   ;==>_ApplyStrings

; 將加密後的 hex 包成 _xd("...") 呼叫；過長時以 "&" 續行拆段，避免單行超過 AutoIt 長度上限（未結束的字串）
Func _XdCall($hex)
	Local $n = StringLen($hex)
	If $n <= 1800 Then Return "_xd(""" & $hex & """)"
	Local $s = "_xd(", $first = True
	For $i = 1 To $n Step 1800
		If Not $first Then $s &= " & _" & @CRLF
		$s &= """" & StringMid($hex, $i, 1800) & """"
		$first = False
	Next
	$s &= ")"
	Return $s
EndFunc   ;==>_XdCall

; 每段字串/數字使用「獨立隨機金鑰」：首位元組存金鑰，其後為 XOR 後的資料
Func _EncStr($s, $key)
	#forceref $key
	If $s = "" Then Return ""
	Local $k = Random(1, 254, 1) ;；本段專屬金鑰（存於首位元組）
	Local $hex = StringTrimLeft(StringToBinary($s, 4), 2)
	Local $out = Hex($k, 2), $len = StringLen($hex), $i
	If $g_strAdvMode Then
		; 進階：位置相依滾動金鑰 kj = (k + j*step) & 0xFF,step 由 k 導出（奇數），每位元組金鑰不同
		Local $step = BitOR($k, 1), $j = 0
		For $i = 1 To $len Step 2
			$out &= Hex(BitXOR(Dec(StringMid($hex, $i, 2)), BitAND($k + $j * $step, 0xFF)), 2)
			$j += 1
		Next
	Else
		; 一般：整段固定金鑰 XOR
		For $i = 1 To $len Step 2
			$out &= Hex(BitXOR(Dec(StringMid($hex, $i, 2)), $k), 2)
		Next
	EndIf
	Return $out
EndFunc   ;==>_EncStr

; 密文參照：一般模式內嵌 _xd("hex");RC 模式累積到 blob 並回傳 _xd（偏移， 長度）
Func _CipherRef($hex)
	If Not $g_rcMode Then Return _XdCall($hex)
	Local $off = StringLen($g_blob) + 1
	$g_blob &= $hex
	Return "_xd(" & $off & ", " & StringLen($hex) & ")"
EndFunc   ;==>_CipherRef

Func _DecodeStub($key, $binName)
	#forceref $key
	; 解碼本體（依 $g_strAdvMode；首位元組為金鑰，其後為 XOR 後資料）
	Local $body = ""
	If $g_strAdvMode Then
		$body &= "	Local $k = Dec(StringLeft($h, 2)), $o = '', $i, $j = 0, $st = BitOR($k, 1)" & @CRLF
		$body &= "	For $i = 3 To StringLen($h) Step 2" & @CRLF
		$body &= "		$o &= Hex(BitXOR(Dec(StringMid($h, $i, 2)), BitAND($k + $j * $st, 0xFF)), 2)" & @CRLF
		$body &= "		$j += 1" & @CRLF
		$body &= "	Next" & @CRLF
	Else
		$body &= "	Local $k = Dec(StringLeft($h, 2)), $o = '', $i" & @CRLF
		$body &= "	For $i = 3 To StringLen($h) Step 2" & @CRLF
		$body &= "		$o &= Hex(BitXOR(Dec(StringMid($h, $i, 2)), $k), 2)" & @CRLF
		$body &= "	Next" & @CRLF
	EndIf
	$body &= "	If $o = '' Then Return ''" & @CRLF
	$body &= "	Return BinaryToString(Binary('0x' & $o), 4)" & @CRLF
	Local $s = ""
	If $g_rcMode Then
		; 密文置於 RC 資源段：編譯時由 AutoIt3Wrapper 加入 exe 資源，執行時讀出 blob；未編譯則讀同資料夾 .bin
		$s &= "#AutoIt3Wrapper_Res_File_Add=" & $binName & ", rt_rcdata, OBSCURA" & @CRLF
		$s &= "Global $__OB = _ld()" & @CRLF
		$s &= "Func _ld()" & @CRLF
		$s &= "	If Not @Compiled Then Return FileRead(@ScriptDir & '\" & $binName & "')" & @CRLF
		$s &= "	Local $f = DllCall('kernel32.dll', 'handle', 'FindResourceW', 'handle', 0, 'wstr', 'OBSCURA', 'long_ptr', 10)" & @CRLF
		$s &= "	If @error Or Not IsArray($f) Or $f[0] = 0 Then Return ''" & @CRLF
		$s &= "	Local $sz = DllCall('kernel32.dll', 'dword', 'SizeofResource', 'handle', 0, 'handle', $f[0])" & @CRLF
		$s &= "	Local $r = DllCall('kernel32.dll', 'handle', 'LoadResource', 'handle', 0, 'handle', $f[0])" & @CRLF
		$s &= "	Local $pp = DllCall('kernel32.dll', 'ptr', 'LockResource', 'handle', $r[0])" & @CRLF
		$s &= "	If @error Or Not IsArray($pp) Or $pp[0] = 0 Then Return ''" & @CRLF
		$s &= "	Local $b = DllStructCreate('byte[' & $sz[0] & ']', $pp[0])" & @CRLF
		$s &= "	Return BinaryToString(DllStructGetData($b, 1), 1)" & @CRLF
		$s &= "EndFunc" & @CRLF
		$s &= "Func _xd($__o, $__l)" & @CRLF
		$s &= "	Local $h = StringMid($__OB, $__o, $__l)" & @CRLF
		$s &= $body
		$s &= "EndFunc"
	Else
		$s &= "Func _xd($h)" & @CRLF
		$s &= $body
		$s &= "EndFunc"
	EndIf
	Return $s
EndFunc   ;==>_DecodeStub

; 將 $inject 插入到檔首的指令區（#AutoIt3Wrapper_* / #NoTrayIcon / #RequireAdmin / #include 等）之後，
; 保留 #AutoIt3Wrapper_Version=Beta 這類必須位於最前面的編譯指令。
Func _InjectAfterDirectives(ByRef $code, $inject)
	If $inject = "" Then Return
	Local $n = StringLen($code), $pos = 1, $insAt = 1
	While $pos <= $n
		Local $nl = StringInStr($code, @LF, 0, 1, $pos)
		Local $lineEnd = ($nl = 0) ? $n + 1 : $nl
		Local $t = StringStripWS(StringMid($code, $pos, $lineEnd - $pos), 3)
		Local $c1 = StringLeft($t, 1)
		If $t <> "" And $c1 <> ";" And $c1 <> "#" Then
			$insAt = $pos
			ExitLoop
		EndIf
		If $nl = 0 Then
			$insAt = $n + 1
			ExitLoop
		EndIf
		$pos = $nl + 1
	WEnd
	$code = StringLeft($code, $insAt - 1) & $inject & @CRLF & StringMid($code, $insAt)
EndFunc   ;==>_InjectAfterDirectives

; ==================================================================
;  回填占位符
; ==================================================================
Func _Reinsert(ByRef $code, $strs, $strRaw, $cmts, $delCmt)
	#forceref $strs
	; 單次正則切段：每段若是字串/註解占位符則查表替換，否則原樣；分塊累加避免 O(n^2)
	Local $segs = StringRegExp($code, "\x02\d+\x03|\x04\d+\x05|[^\x02\x04]+", 3)
	If Not IsArray($segs) Then Return
	Local $total = UBound($segs)
	Local $out = "", $chunk = ""
	For $i = 0 To $total - 1
		Local $s = $segs[$i]
		Local $c1 = StringLeft($s, 1)
		If $c1 = Chr(2) Then
			$chunk &= $strRaw.Item(Int(StringMid($s, 2, StringLen($s) - 2)))
		ElseIf $c1 = Chr(4) Then
			$chunk &= ($delCmt ? "" : $cmts.Item(Int(StringMid($s, 2, StringLen($s) - 2))))
		Else
			$chunk &= $s
		EndIf
		If Mod($i, 500) = 0 Then
			$out &= $chunk
			$chunk = ""
			If _Progress($i, $total) Then ExitLoop
		EndIf
	Next
	$code = $out & $chunk
EndFunc   ;==>_Reinsert

; ==================================================================
;  代碼檢測
; ==================================================================
Func _Detect($what)
	_DebugTrace("DETECT enter mode=" & $what & " file=" & $g_script)
	If $g_bListPopulating Then Return
	If $g_script = "" Then
		_Msg(48, "提示", "請先載入腳本。")
		Return
	EndIf
	$g_bListPopulating = True
	_DebugTrace("DETECT start updating virtual list")
	GUISwitch($g_pg[$PG_DETECT])
	_DebugTrace("DETECT begin snapshot")
	_LvBeginSnapshot($g_lvDetect)
	$g_selDet = -1
	$g_bListMenuDirty = True
	GUICtrlSetData($g_inLocate, "")
	Local $work[256][3]
	Local $special = "AdlibRegister|AdlibUnRegister|Assign|Call|DllCallbackRegister|Eval|Execute|" & _
			"GUIRegisterMsg|GUISetOnEvent|GUICtrlSetOnEvent|HotKeySet|IsDeclared|" & _
			"TrayItemSetOnEvent|ObjEvent|OnAutoItStartRegister|OnAutoItExitUnRegister"
	Local $lines = StringSplit(StringStripCR(FileRead($g_script)), @LF)
	Local $uniq = ObjCreate("Scripting.Dictionary"), $idx = 0, $ln, $i, $arr
	For $ln = 1 To $lines[0]
		If Mod($ln, 4000) = 0 Then _Pump()
		Local $line = $lines[$ln]
		Switch $what
			Case "func"
				$arr = StringRegExp($line, "(?i)^\s*Func\s+(\w+)", 3)
			Case "var"
				$arr = StringRegExp($line, "\$\w+", 3)
			Case "str"
				$arr = StringRegExp($line, _StrLiteralPat(), 3)
			Case "special"
				If StringRegExp($line, "(?i)(?<![0-9A-Za-z_])(" & $special & ")\s*\(") Then
					Local $one[1] = [StringStripWS($line, 3)]
					$arr = $one
				Else
					$arr = 0
				EndIf
		EndSwitch
		If Not IsArray($arr) Then ContinueLoop
		For $i = 0 To UBound($arr) - 1
			Local $v = $arr[$i]
			If $what = "func" Or $what = "var" Then
				If $uniq.Exists(StringLower($v)) Then ContinueLoop
				$uniq.Add(StringLower($v), 1)
			EndIf
			_DetPush($work, $idx, $idx + 1, $v, $ln)
		Next
	Next
	ReDim $work[$idx][3]
	_DebugTrace("DETECT before SetItemCount(" & $idx & ")")
	_LvCommitSnapshot($g_lvDetect, $g_detData, $work, $idx)
	_DebugTrace("DETECT after SetItemCount(" & $idx & ")")
	$g_bListMenuDirty = True
	$g_selDet = -1
	$g_bListPopulating = False
	_LvUpdMenus()
	_DebugTrace("DETECT finish before status")
	_Status("偵測完成:" & $idx & " 筆")
EndFunc   ;==>_Detect

; 附加一筆檢測結果到虛擬資料陣列（自動成長）
Func _DetPush(ByRef $work, ByRef $idx, $disp, $content, $ln)
	If $idx >= UBound($work) Then ReDim $work[($idx + 1) * 2][3]
	$work[$idx][0] = $disp
	$work[$idx][1] = $content
	$work[$idx][2] = $ln
	$idx += 1
EndFunc   ;==>_DetPush

; 全部檢測：一次列出函式/變數/字串/特殊，內容前加 [類別]；依「類別|值」去重
Func _DetectAll()
	_DebugTrace("DETECT ALL enter file=" & $g_script)
	If $g_bListPopulating Then Return
	If $g_script = "" Then
		_Msg(48, "提示", "請先載入腳本。")
		Return
	EndIf
	$g_bListPopulating = True
	_DebugTrace("DETECT start updating virtual list")
	GUISwitch($g_pg[$PG_DETECT])
	_DebugTrace("DETECT ALL begin snapshot")
	_LvBeginSnapshot($g_lvDetect)
	$g_selDet = -1
	$g_bListMenuDirty = True
	GUICtrlSetData($g_inLocate, "")
	Local $work[256][3]
	Local $special = "AdlibRegister|AdlibUnRegister|Assign|Call|DllCallbackRegister|Eval|Execute|" & _
			"GUIRegisterMsg|GUISetOnEvent|GUICtrlSetOnEvent|HotKeySet|IsDeclared|" & _
			"TrayItemSetOnEvent|ObjEvent|OnAutoItStartRegister|OnAutoItExitUnRegister"
	Local $lines = StringSplit(StringStripCR(FileRead($g_script)), @LF)
	Local $uniq = ObjCreate("Scripting.Dictionary"), $idx = 0, $ln, $k
	For $ln = 1 To $lines[0]
		If Mod($ln, 4000) = 0 Then _Pump()
		Local $line = $lines[$ln]
		Local $m = StringRegExp($line, "(?i)^\s*Func\s+(\w+)", 3)
		If IsArray($m) Then _DetRow($work, $idx, $uniq, $ln, "函式", $m[0])
		If StringRegExp($line, "(?i)(?<![0-9A-Za-z_])(" & $special & ")\s*\(") Then _DetRow($work, $idx, $uniq, $ln, "特殊", StringStripWS($line, 3))
		Local $ss = StringRegExp($line, _StrLiteralPat(), 3)
		If IsArray($ss) Then
			For $k = 0 To UBound($ss) - 1
				_DetRow($work, $idx, $uniq, $ln, "字串", $ss[$k])
			Next
		EndIf
		Local $vv = StringRegExp($line, "\$\w+", 3)
		If IsArray($vv) Then
			For $k = 0 To UBound($vv) - 1
				_DetRow($work, $idx, $uniq, $ln, "變數", $vv[$k])
			Next
		EndIf
	Next
	ReDim $work[$idx][3]
	_DebugTrace("DETECT before SetItemCount(" & $idx & ")")
	_LvCommitSnapshot($g_lvDetect, $g_detData, $work, $idx)
	_DebugTrace("DETECT after SetItemCount(" & $idx & ")")
	$g_bListMenuDirty = True
	$g_selDet = -1
	$g_bListPopulating = False
	_LvUpdMenus()
	_DebugTrace("DETECT finish before status")
	_Status("全部檢測完成:" & $idx & " 筆(已去重)")
EndFunc   ;==>_DetectAll

; 加入一筆偵測結果（去重、記行號）到虛擬資料
Func _DetRow(ByRef $work, ByRef $idx, $uniq, $ln, $cat, $val)
	Local $key = $cat & Chr(1) & $val
	If $uniq.Exists($key) Then Return
	$uniq.Add($key, 1)
	_DetPush($work, $idx, $idx + 1, "[" & TR($cat) & "] " & $val, $ln)
EndFunc   ;==>_DetRow

; 點選偵測清單列時，於「定位」欄顯示來源行號與內容
Func _DetectShowLocate()
	Local $row = _LvSelIndex($g_lvDetect) ;;owner-draw ListBox:目前選取列
	If $row < 0 Or $row >= UBound($g_detData) Then Return
	GUICtrlSetData($g_inLocate, "第 " & $g_detData[$row][2] & " 行:" & $g_detData[$row][1])
EndFunc   ;==>_DetectShowLocate

Func _DetectExport()
	Local $n = UBound($g_detData)
	If $n = 0 Then Return
	Local $f = FileSaveDialog("輸出檢測結果", @ScriptDir, "文字檔 (*.txt)", 16, "detect.txt", $hMain)
	If @error Then Return
	Local $txt = ""
	For $i = 0 To $n - 1
		$txt &= $g_detData[$i][0] & @TAB & $g_detData[$i][1] & @CRLF
	Next
	Local $h = FileOpen($f, 2 + 256)
	FileWrite($h, $txt)
	FileClose($h)
	_Msg(64, "完成", "已輸出:" & $f)
EndFunc   ;==>_DetectExport

; ==================================================================
;  多語言處理
; ==================================================================
Func _MLDetect()
	If $g_script = "" Then
		_Msg(48, "提示", "請先載入腳本。")
		Return
	EndIf
	If $g_bListPopulating Then Return
	$g_bListPopulating = True
	GUISwitch($g_pg[$PG_ML])
	_LvBeginSnapshot($g_lvML)
	$g_selML = -1
	$g_bListMenuDirty = True
	GUICtrlSetData($g_inMLLocate, "")
	Local $work[256][3]
	Local $mode = GUICtrlRead($g_cboMLMode) ;；處理模式
	Local $showAll = (GUICtrlRead($g_cboMLFilter) = "顯示所有") ;；顯示所有=不去除重複
	Local $lines = StringSplit(StringStripCR(FileRead($g_script)), @LF)
	Local $pat = _StrLiteralPat()
	Local $idx = 0, $uniq = ObjCreate("Scripting.Dictionary"), $ln, $i
	For $ln = 1 To $lines[0]
		If Mod($ln, 4000) = 0 Then _Pump()
		Local $arr = StringRegExp($lines[$ln], $pat, 3)
		If Not IsArray($arr) Then ContinueLoop
		For $i = 0 To UBound($arr) - 1
			Local $lit = $arr[$i]
			Local $q = StringLeft($lit, 1)
			Local $v = StringReplace(StringMid($lit, 2, StringLen($lit) - 2), $q & $q, $q)
			If Not _MLModeMatch($v, $q, $mode) Then ContinueLoop
			If Not $showAll Then
				If $uniq.Exists($v) Then ContinueLoop
				$uniq.Add($v, 1)
			EndIf
			If $idx >= UBound($work) Then ReDim $work[($idx + 1) * 2][3]
			$work[$idx][0] = $idx + 1
			$work[$idx][1] = $v
			$work[$idx][2] = $ln
			$idx += 1
		Next
	Next
	ReDim $work[$idx][3]
	_LvCommitSnapshot($g_lvML, $g_mlData, $work, $idx)
	$g_bListPopulating = False
	$g_bListMenuDirty = True
	$g_selML = -1
	_LvUpdMenus()
	_Status("多語言偵測完成:" & $idx & " 筆")
EndFunc   ;==>_MLDetect

; 依「多語言處理模式」判斷某字串是否納入
Func _MLModeMatch($v, $q, $mode)
	Local $hasCn = StringRegExp($v, "[\x{4e00}-\x{9fff}]") ;；含中文
	Local $allCn = StringRegExp($v, "^[\x{4e00}-\x{9fff}\s]+$") ;；僅中文（含空白）
	Switch $mode
		Case "只有非中文字元"
			Return Not $hasCn And $v <> ""
		Case "只有中文字元"
			Return $allCn = 1
		Case "包含中文字元"
			Return $hasCn = 1
		Case "所有字元"
			Return $v <> ""
		Case "由雙引號 "" 包含"
			Return $q = Chr(34)
		Case "由單引號 ' 包含"
			Return $q = Chr(39)
	EndSwitch
	Return $hasCn = 1
EndFunc   ;==>_MLModeMatch

Func _StrLiteralPat()
	Local $DQ = Chr(34), $SQ = Chr(39)
	Return $DQ & "(?:[^" & $DQ & "]|" & $DQ & $DQ & ")*" & $DQ & "|" & _
			$SQ & "(?:[^" & $SQ & "]|" & $SQ & $SQ & ")*" & $SQ
EndFunc   ;==>_StrLiteralPat

; 點選清單列時，於「定位」欄顯示來源行號與內容
Func _MLShowLocate()
	Local $row = _LvSelIndex($g_lvML) ;;owner-draw ListBox:目前選取列
	If $row < 0 Or $row >= UBound($g_mlData) Then Return
	GUICtrlSetData($g_inMLLocate, "第 " & $g_mlData[$row][2] & " 行:" & $g_mlData[$row][1])
EndFunc   ;==>_MLShowLocate

Func _MLRestore()
	If $g_bListPopulating Then Return
	$g_bListPopulating = True
	GUISwitch($g_pg[$PG_ML])
	_LvBeginSnapshot($g_lvML)
	$g_selML = -1
	$g_bListMenuDirty = True
	GUICtrlSetData($g_inMLLocate, "")
	Local $work[0][3]
	_LvCommitSnapshot($g_lvML, $g_mlData, $work, 0)
	$g_bListPopulating = False
	_Status("已清空多語言偵測結果。")
EndFunc   ;==>_MLRestore

Func _MLRun()
	Local $filter = GUICtrlRead($g_cboMLFilter)
	If $filter = "不處理" Then
		_Msg(48, "提示", "目前『過濾』為「不處理」,不會產生語言檔。請改為「處理」或「顯示所有」。")
		Return
	EndIf
	Local $n = UBound($g_mlData)
	If $n = 0 Then
		_Msg(48, "提示", "請先『檢測』出字串。")
		Return
	EndIf
	Local $field = GUICtrlRead($g_inMLField)
	If $field = "" Then $field = "TEXT"
	Local $ini = _DirOf($g_script) & "\Lang_" & $field & ".ini"
	Local $merge = (GUICtrlRead($g_chkMLMerge) = $GUI_CHECKED)
	Local $base = 0
	If $merge And FileExists($ini) Then
		; 合併：沿用既有鍵數，新鍵從後面接續
		Local $exist = IniReadSection($ini, $field)
		If Not @error Then $base = $exist[0][0]
	EndIf
	Local $txt = "", $i
	If Not ($merge And FileExists($ini)) Then $txt = "[" & $field & "]" & @CRLF
	For $i = 0 To $n - 1
		$txt &= $field & ($base + $i + 1) & "=" & $g_mlData[$i][1] & @CRLF
	Next
	Local $h = FileOpen($ini, ($merge ? 1 : 2) + 256) ;；合併→附加（1）；否則覆寫（2）
	FileWrite($h, $txt)
	FileClose($h)
	_Msg(64, "完成", "已" & ($merge And $base > 0 ? "附加至" : "產生") & "語言檔:" & @CRLF & $ini & @CRLF & @CRLF & _
			"用法:以 IniRead 讀取各字段,於程式中以對應鍵值取代原字串。")
EndFunc   ;==>_MLRun

; ==================================================================
;  自校驗樣板
; ==================================================================
Func _SelfGen()
	Local $issuer = GUICtrlRead($g_inCertIssuer)
	Local $signer = GUICtrlRead($g_inCertSigner)
	Local $serial = GUICtrlRead($g_inCertSerial)
	Local $f = FileSaveDialog("儲存自校驗樣板", @ScriptDir, "AutoIt (*.au3)", 16, "SelfCheck.au3", $hMain)
	If @error Then Return
	Local $t = "; === 自我校驗樣板(以 WinVerifyTrust 驗證自身數位簽章)===" & @CRLF
	$t &= "#include <WinAPI.au3>" & @CRLF
	$t &= "; 頒發者:" & $issuer & @CRLF
	$t &= "; 簽署者:" & $signer & @CRLF
	$t &= "; 預期序號/指紋:" & $serial & @CRLF & @CRLF
	$t &= "If Not _SelfVerify() Then Exit  ;; 簽章無效/被竄改即結束" & @CRLF & @CRLF
	$t &= "Func _SelfVerify()" & @CRLF
	$t &= "	If Not @Compiled Then Return True  ;; 未編譯時略過" & @CRLF
	$t &= "	Local $g = _WinAPI_GUIDFromString('{00AAC56B-CD44-11D0-8CC2-00C04FC295EE}')" & @CRLF
	$t &= "	Local $tFile = DllStructCreate('dword cb;ptr path;handle hFile;ptr subj')" & @CRLF
	$t &= "	Local $tPath = DllStructCreate('wchar[' & (StringLen(@AutoItExe) + 1) & ']')" & @CRLF
	$t &= "	DllStructSetData($tPath, 1, @AutoItExe)" & @CRLF
	$t &= "	DllStructSetData($tFile, 'cb', DllStructGetSize($tFile))" & @CRLF
	$t &= "	DllStructSetData($tFile, 'path', DllStructGetPtr($tPath))" & @CRLF
	$t &= "	Local $tD = DllStructCreate('dword cb;ptr a;ptr b;dword ui;dword rev;dword uni;ptr file;dword st;handle hs;ptr url;dword prov;dword ctx;ptr sig')" & @CRLF
	$t &= "	DllStructSetData($tD, 'cb', DllStructGetSize($tD))" & @CRLF
	$t &= "	DllStructSetData($tD, 'ui', 2)" & @CRLF
	$t &= "	DllStructSetData($tD, 'uni', 1)" & @CRLF
	$t &= "	DllStructSetData($tD, 'file', DllStructGetPtr($tFile))" & @CRLF
	$t &= "	DllStructSetData($tD, 'st', 1)" & @CRLF
	$t &= "	Local $r = DllCall('wintrust.dll', 'long', 'WinVerifyTrust', 'handle', 0, 'struct*', $g, 'struct*', $tD)" & @CRLF
	$t &= "	DllStructSetData($tD, 'st', 2)" & @CRLF
	$t &= "	DllCall('wintrust.dll', 'long', 'WinVerifyTrust', 'handle', 0, 'struct*', $g, 'struct*', $tD)" & @CRLF
	$t &= "	If @error Or $r[0] <> 0 Then Return False  ;; 0 = 受信任且未被竄改" & @CRLF
	$t &= "	Return True" & @CRLF
	$t &= "EndFunc" & @CRLF
	Local $h = FileOpen($f, 2 + 256)
	FileWrite($h, $t)
	FileClose($h)
	_Msg(64, "完成", "已產生可運作的自我校驗樣板:" & @CRLF & $f & @CRLF & @CRLF & _
			"編譯並以你的憑證對 EXE 簽章後即生效(需 WinAPI.au3)。")
EndFunc   ;==>_SelfGen

; 擷取 PE 檔內嵌的 Authenticode 憑證區塊（挪用自 AutoIt3Wrapper 的 _PEFileCert；僅讀取）
Func _PEFileCert($sFilePath)
	Local $hFile, $bBuffer, $iOffset, $iSucces = 0
	Local $iCertificateAddress, $nCertificateSz = 0, $nSections, $nDataDirectories
	Local $Certificate = "", $stEndian = DllStructCreate("int")
	Local $nFileSize = FileGetSize($sFilePath)
	$hFile = FileOpen($sFilePath, 16) ;；二進位讀取
	If $hFile = -1 Then Return SetError(1, 0, "")
	Do
		$bBuffer = FileRead($hFile, 2)
		If @error Or $bBuffer <> 0x5A4D Then ExitLoop ;;DOS 簽名
		If Not FileSetPos($hFile, 0x3C, 0) Then ExitLoop
		$bBuffer = FileRead($hFile, 4)
		If @error Then ExitLoop
		$iOffset = Number($bBuffer)
		If Not FileSetPos($hFile, $iOffset, 0) Then ExitLoop
		$bBuffer = FileRead($hFile, 26)
		If @error Or BinaryMid($bBuffer, 1, 4) <> 0x00004550 Then ExitLoop ;;PE 簽名
		DllStructSetData($stEndian, 1, BinaryMid($bBuffer, 7, 2))
		$nSections = DllStructGetData($stEndian, 1)
		If $nSections * 40 > $nFileSize Then ExitLoop
		$bBuffer = BinaryMid($bBuffer, 25, 2)
		If $bBuffer = 0x10B Then
			$iOffset += 116 ;;PE32
		ElseIf $bBuffer = 0x20B Then
			$iOffset += 132 ;;PE32+(x64)
		Else
			ExitLoop
		EndIf
		If Not FileSetPos($hFile, $iOffset, 0) Then ExitLoop
		$nDataDirectories = Number(FileRead($hFile, 4))
		If $nDataDirectories < 5 Or $nDataDirectories > 16 Then ExitLoop
		If Not FileSetPos($hFile, $iOffset + 36, 0) Then ExitLoop
		DllStructSetData($stEndian, 1, FileRead($hFile, 4))
		$iCertificateAddress = DllStructGetData($stEndian, 1)
		If $iCertificateAddress = 0 Then ExitLoop ;；未簽章
		DllStructSetData($stEndian, 1, FileRead($hFile, 4))
		$nCertificateSz = DllStructGetData($stEndian, 1)
		If $nCertificateSz = 0 Then ExitLoop
		If Not FileSetPos($hFile, $iCertificateAddress, 0) Then ExitLoop
		$Certificate = FileRead($hFile, $nCertificateSz)
		If @error Then ExitLoop
		$iSucces = 1
	Until 1
	FileClose($hFile)
	If Not $iSucces Then Return SetError(2, 0, "")
	Return $Certificate
EndFunc   ;==>_PEFileCert

; 以 WinVerifyTrust 驗證檔案的 Authenticode 簽章（回傳 0 = 受信任且未竄改）
Func _VerifyTrust($sFile)
	Local $g = _WinAPI_GUIDFromString("{00AAC56B-CD44-11D0-8CC2-00C04FC295EE}")
	Local $tFile = DllStructCreate("dword cb;ptr path;handle hFile;ptr subj")
	Local $tPath = DllStructCreate("wchar[" & (StringLen($sFile) + 1) & "]")
	DllStructSetData($tPath, 1, $sFile)
	DllStructSetData($tFile, "cb", DllStructGetSize($tFile))
	DllStructSetData($tFile, "path", DllStructGetPtr($tPath))
	Local $tD = DllStructCreate("dword cb;ptr a;ptr b;dword ui;dword rev;dword uni;ptr file;dword st;handle hs;ptr url;dword prov;dword ctx;ptr sig")
	DllStructSetData($tD, "cb", DllStructGetSize($tD))
	DllStructSetData($tD, "ui", 2)
	DllStructSetData($tD, "uni", 1)
	DllStructSetData($tD, "file", DllStructGetPtr($tFile))
	DllStructSetData($tD, "st", 1)
	Local $r = DllCall("wintrust.dll", "long", "WinVerifyTrust", "handle", 0, "struct*", $g, "struct*", $tD)
	DllStructSetData($tD, "st", 2)
	DllCall("wintrust.dll", "long", "WinVerifyTrust", "handle", 0, "struct*", $g, "struct*", $tD)
	If @error Or Not IsArray($r) Then Return SetError(1, 0, -1)
	Return $r[0]
EndFunc   ;==>_VerifyTrust

; 檢查某 EXE 是否已簽章且通過 WinVerifyTrust
Func _CertCheck()
	Local $exe = FileOpenDialog("選擇要檢查的 EXE", @ScriptDir, "執行檔 (*.exe)|所有檔案 (*.*)", 3, "", $hMain)
	If @error Then Return
	Local $cert = _PEFileCert($exe)
	Local $msg = "檔案:" & $exe & @CRLF & @CRLF
	If $cert <> "" Then
		$msg &= "● 已內嵌數位簽章(憑證區塊 " & _SizeStr(BinaryLen($cert)) & ")" & @CRLF
		Local $vt = _VerifyTrust($exe)
		If $vt = 0 Then
			$msg &= "● WinVerifyTrust:簽章有效、未被竄改。"
		Else
			$msg &= "● WinVerifyTrust 回傳 0x" & Hex($vt, 8) & ":簽章無效 / 不受信任 / 已被竄改。"
		EndIf
	Else
		$msg &= "● 未偵測到數位簽章(此檔未簽章)。"
	EndIf
	_Msg(64, "簽章檢查", $msg)
EndFunc   ;==>_CertCheck

; 讀取 EXE 憑證區塊，以 SHA1 指紋作為序號識別填入欄位
Func _CertRead()
	Local $exe = FileOpenDialog("選擇要讀取憑證的 EXE", @ScriptDir, "執行檔 (*.exe)|所有檔案 (*.*)", 3, "", $hMain)
	If @error Then Return
	Local $cert = _PEFileCert($exe)
	If $cert = "" Then
		_Msg(48, "提示", "此檔未簽章,無憑證可讀取。")
		Return
	EndIf
	Local $hash = _Crypt_HashData($cert, $CALG_SHA1)
	GUICtrlSetData($g_inCertSerial, StringTrimLeft(String($hash), 2))
	GUICtrlSetData($g_inCertSigner, _NameOf($exe))
	_Msg(64, "讀取完成", "已擷取簽章區塊 SHA1 指紋填入「序號」,檔名填入「簽署者」。" & @CRLF & @CRLF & _
			"註:完整憑證序號/頒發者需以 CryptQueryObject 解析 PKCS#7;" & @CRLF & _
			"此處以簽章區塊指紋作唯一識別,已足以用於自我校驗比對。")
EndFunc   ;==>_CertRead

; ==================================================================
;  除錯輔助：實際行號 → 內部行號（近似）
; ==================================================================
Func _DebugMap()
	_DebugTrace("DebugMap entered")
	If $g_bListPopulating Then Return
	Local $f = GUICtrlRead($g_inDbgFile)
	If Not FileExists($f) Then
		_Msg(48, "提示", "請先拖入腳本。")
		Return
	EndIf
	$g_bListPopulating = True
	GUISwitch($g_pg[$PG_DEBUG])
	_DebugTrace("DebugMap before SetItemCount(0)")
	_LvBeginSnapshot($g_lvDbg) ; 建立新快照期間不繪製
	Local $code = FileRead($f)
	Local $lines = StringSplit($code, @LF, 1)
	Local $internal = 0, $contPending = False
	Local $work[$lines[0]][3] ;；一次配置，避免逐列插入（上萬筆不卡）
	For $i = 1 To $lines[0]
		Local $ln = StringStripWS($lines[$i], 3)
		Local $isCode = ($ln <> "" And StringLeft($ln, 1) <> ";" _
				And Not StringRegExp($ln, "(?i)^#(cs|ce|comments-start|comments-end)\b"))
		Local $shown = ""
		If $isCode Then
			If Not $contPending Then
				$internal += 1
				$shown = $internal
			EndIf
			$contPending = (StringRight($ln, 2) = " _")
		EndIf
		$work[$i - 1][0] = $i
		$work[$i - 1][1] = $shown
		$work[$i - 1][2] = StringStripWS($lines[$i], 2)
		If Mod($i, 4000) = 0 Then _Pump()
	Next
	_DebugTrace("DebugMap before SetItemCount(" & $lines[0] & ")")
	_LvCommitSnapshot($g_lvDbg, $g_dbgData, $work, $lines[0]) ;；告知列數，內容由 LVN_GETDISPINFO 供應
	_DebugTrace("DebugMap after SetItemCount")
	$g_bListPopulating = False
    _DebugTrace("DebugMap before status")
	_Status("行號對照完成:" & $lines[0] & " 行")
    _DebugTrace("DebugMap return complete")
EndFunc   ;==>_DebugMap

; ==================================================================
;  代碼轉換（取代 FileInstall）
; ==================================================================
Func _ConvRun()
	Local $f = GUICtrlRead($g_inConvFile)
	If Not FileExists($f) Then
		_Msg(48, "提示", "請先拖入或選擇要轉換的檔案。")
		Return
	EndIf
	_ConvFromFile($f)
EndFunc   ;==>_ConvRun

Func _ConvFromFile($f)
	Local $h = FileOpen($f, 16)
	If $h = -1 Then Return
	Local $bin = FileRead($h)
	FileClose($h)
	Local $hex = StringTrimLeft($bin, 2)

	Local $bpl = Int(GUICtrlRead($g_inBytesPerLine))
	If $bpl < 1 Then $bpl = 100
	Local $lpv = Int(GUICtrlRead($g_inLinesPerVar))
	If $lpv < 1 Then $lpv = 20
	Local $single = (GUICtrlRead($g_rConvVar) = $GUI_CHECKED)
	Local $tmpName = (GUICtrlRead($g_chkTmpName) = $GUI_CHECKED)
	Local $name = StringRegExpReplace($f, "^.*\\", "")
	Local $tab = @TAB

	Local $chunks[0]
	Local $per = $bpl * 2, $len = StringLen($hex), $p = 1
	While $p <= $len
		_ArrayAdd($chunks, StringMid($hex, $p, $per))
		$p += $per
	WEnd
	If UBound($chunks) = 0 Then _ArrayAdd($chunks, "")
	Local $nChunk = UBound($chunks)

	Local $code = ""
	If $single Then
		$code = "Global $g_Data = Binary(""0x"" & _" & @CRLF
		For $i = 0 To $nChunk - 1
			$code &= $tab & '"' & $chunks[$i] & '" & _' & @CRLF
		Next
		$code &= $tab & '"")' & @CRLF
	Else
		Local $groups = Ceiling($nChunk / $lpv)
		$code = "; 用 _ReleaseFile() 取代 FileInstall(""" & $name & """, ...)" & @CRLF
		$code &= "Func _ReleaseFile($sPath)" & @CRLF
		$code &= $tab & "Local $h = FileOpen($sPath, 18)" & @CRLF
		$code &= $tab & "If $h = -1 Then Return SetError(1, 0, False)" & @CRLF
		For $g = 1 To $groups
			$code &= $tab & "FileWrite($h, Binary(""0x"" & _d" & $g & "()))" & @CRLF
		Next
		$code &= $tab & "FileClose($h)" & @CRLF
		$code &= $tab & "Return True" & @CRLF
		$code &= "EndFunc" & @CRLF & @CRLF
		For $g = 1 To $groups
			$code &= "Func _d" & $g & "()" & @CRLF
			$code &= $tab & "Return """" _" & @CRLF
			Local $start = ($g - 1) * $lpv
			Local $end = $start + $lpv - 1
			If $end > $nChunk - 1 Then $end = $nChunk - 1
			For $i = $start To $end
				$code &= $tab & "& """ & $chunks[$i] & '"' & (($i < $end) ? " _" : "") & @CRLF
			Next
			$code &= "EndFunc" & @CRLF & @CRLF
		Next
		Local $out = $tmpName ? "@TempDir & ""\~Tmp"" & Random(1000, 9999, 1)" : "@ScriptDir & ""\" & $name & """"
		$code &= "; 範例：_ReleaseFile(" & $out & ")" & @CRLF
	EndIf
	$g_sConvCode = $code ;;存起來供「複製／另存／重新開啟」使用
	_Status("已產生轉換程式碼(" & _SizeStr(StringLen($code)) & ")")
	If $g_hSci Then
		_SciSetText($g_hSci, $code) ;;內嵌 Scintilla 顯示
	Else
		_ConvShowResult($code) ;;退回:獨立標準視窗
	EndIf
EndFunc   ;==>_ConvFromFile

; ========================= 內嵌 Scintilla(轉換輸出) =========================
; 載入 SciLexer.dll / Scintilla.dll(SciTE 用的編輯器核心)。載入即註冊 "Scintilla" 視窗類別。
; 開發(F5)時從 AutoIt 的 SciTE 資料夾載入;編譯後請把該 DLL 放在 EXE 同資料夾(或 FileInstall)。
; ★ FileInstall 位置 ★ 編譯版把 Scintilla.dll 內嵌進 EXE,首次執行若同資料夾沒有就釋放出來。
; FileInstall 的來源必須是編譯期字面常數:用相對路徑 "Scintilla.dll"(需與本腳本同資料夾)。
; 未編譯(F5)時不處理:直接由 _SciInit 從同資料夾或 AutoIt 的 SciTE 資料夾載入。
Func _SciEnsureDll()
	If Not @Compiled Then Return
	Local $dst = @ScriptDir & "\Scintilla.dll"
	If FileExists($dst) Then Return
	FileInstall("Scintilla.dll", @ScriptDir & "\Scintilla.dll", 1) ;;← FileInstall 就在這一行
EndFunc   ;==>_SciEnsureDll

Func _SciInit()
	If $g_hSciDll Then Return True
	Local $aCand[7] = [ _
			@ScriptDir & "\SciLexer.dll", @ScriptDir & "\Scintilla.dll", _
			@ScriptDir & "\SciTE\SciLexer.dll", _
			@ProgramFilesDir & "\AutoIt3\SciTE\SciLexer.dll", _
			"C:\Program Files (x86)\AutoIt3\SciTE\SciLexer.dll", _
			"C:\Program Files\AutoIt3\SciTE\SciLexer.dll", _
			"C:\Program Files (x86)\AutoIt3\SciTE\Scintilla.dll"]
	Local $i
	For $i = 0 To UBound($aCand) - 1
		If FileExists($aCand[$i]) Then
			$g_hSciDll = _WinAPI_LoadLibrary($aCand[$i])
			If $g_hSciDll Then
				; 舊版 SciLexer 需手動註冊類別;新版載入即註冊,呼叫失敗也無妨。
				DllCall($aCand[$i], "int", "Scintilla_RegisterClasses", "ptr", 0)
				Return True
			EndIf
		EndIf
	Next
	Return False
EndFunc   ;==>_SciInit

Func _SciMsg($h, $msg, $wp, $lp)
	Local $a = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $h, "uint", $msg, "wparam", $wp, "lparam", $lp)
	If @error Or Not IsArray($a) Then Return 0
	Return $a[0]
EndFunc   ;==>_SciMsg

; 建立 Scintilla 子控件(純文字唯讀檢視:UTF-8、不換行、隱藏左側邊界、等寬字)
Func _SciCreate($hParent, $x, $y, $w, $h)
	If Not _SciInit() Then Return 0
	Local $style = BitOR($WS_CHILD, $WS_VISIBLE, $WS_VSCROLL, $WS_HSCROLL, $WS_CLIPSIBLINGS)
	Local $hSci = _WinAPI_CreateWindowEx(0, "Scintilla", "", $style, $x, $y, $w, $h, $hParent)
	If Not $hSci Then Return 0
	_SciMsg($hSci, 2037, 65001, 0) ;;SCI_SETCODEPAGE = UTF-8
	_SciMsg($hSci, 2268, 0, 0)     ;;SCI_SETWRAPMODE = 不換行(保留橫向捲動)
	Local $tFont = DllStructCreate("char[16]")
	DllStructSetData($tFont, 1, "Consolas")
	_SciMsg($hSci, 2056, 32, DllStructGetPtr($tFont)) ;;SCI_STYLESETFONT STYLE_DEFAULT(32)
	_SciMsg($hSci, 2055, 32, 10)   ;;SCI_STYLESETSIZE
	_SciMsg($hSci, 2050, 0, 0)     ;;SCI_STYLECLEARALL(套用到所有樣式)
	_SciMsg($hSci, 2242, 0, 0)     ;;SCI_SETMARGINWIDTHN:隱藏行號/符號/摺疊三個邊界
	_SciMsg($hSci, 2242, 1, 0)
	_SciMsg($hSci, 2242, 2, 0)
	_SciMsg($hSci, 2171, 1, 0)     ;;SCI_SETREADONLY
	Return $hSci
EndFunc   ;==>_SciCreate

; 設定 Scintilla 內容(唯讀需先解除才塞得進去);文字以 UTF-8 傳入
Func _SciSetText($h, $text)
	If Not $h Then Return
	_SciMsg($h, 2171, 0, 0) ;;SCI_SETREADONLY 關
	Local $b = StringToBinary($text, 4) ;;UTF-8
	Local $len = BinaryLen($b)
	Local $t = DllStructCreate("byte[" & ($len + 1) & "]") ;;+1 作為結尾 NUL
	If $len > 0 Then DllStructSetData($t, 1, $b)
	_SciMsg($h, 2181, 0, DllStructGetPtr($t)) ;;SCI_SETTEXT
	_SciMsg($h, 2175, 0, 0) ;;SCI_EMPTYUNDOBUFFER
	_SciMsg($h, 2032, 0, 0) ;;SCI_GOTOPOS 0:回到開頭
	_SciMsg($h, 2171, 1, 0) ;;SCI_SETREADONLY 開
EndFunc   ;==>_SciSetText

; 轉換結果顯示於另開的「標準框架視窗」(有標題列,系統原生繪製),
; 徹底避開無邊框自繪主視窗內嵌多行文字框的重繪殘影。視窗內用一般 Edit + 一般按鈕。
Func _ConvShowResult($code)
	If $code = "" Then Return
	Local $dw = 900, $dh = 620
	Local $dlg = GUICreate(TR("轉換結果 — 程式碼轉換"), $dw, $dh, -1, -1, _
			BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX, $WS_SIZEBOX, $WS_MAXIMIZEBOX), -1, $hMain)
	GUISetBkColor(0xF5F5F7, $dlg)
	Local $ed = GUICtrlCreateEdit($code, 10, 10, $dw - 20, $dh - 56, _
			BitOR($ES_MULTILINE, $ES_READONLY, $WS_VSCROLL, $WS_HSCROLL, $ES_AUTOVSCROLL, $ES_AUTOHSCROLL))
	GUICtrlSetFont($ed, 10, 400, 0, "Consolas")
	GUICtrlSetResizing($ed, BitOR($GUI_DOCKLEFT, $GUI_DOCKRIGHT, $GUI_DOCKTOP, $GUI_DOCKBOTTOM))
	_GUICtrlEdit_SetSel(GUICtrlGetHandle($ed), 0, 0)
	Local $bCopy = GUICtrlCreateButton(TR("複製全部"), 10, $dh - 38, 110, 28)
	GUICtrlSetResizing($bCopy, BitOR($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	Local $bSave = GUICtrlCreateButton(TR("另存為 .au3"), 128, $dh - 38, 120, 28)
	GUICtrlSetResizing($bSave, BitOR($GUI_DOCKLEFT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	Local $bClose = GUICtrlCreateButton(TR("關閉"), $dw - 100, $dh - 38, 90, 28)
	GUICtrlSetResizing($bClose, BitOR($GUI_DOCKRIGHT, $GUI_DOCKBOTTOM, $GUI_DOCKSIZE))
	GUISetState(@SW_DISABLE, $hMain) ;;模態:顯示結果期間暫停主視窗,避免巢狀迴圈吞掉主視窗事件
	GUISetState(@SW_SHOW, $dlg)
	While 1
		Local $m = GUIGetMsg()
		Switch $m
			Case $GUI_EVENT_CLOSE, $bClose
				ExitLoop
			Case $bCopy
				ClipPut(GUICtrlRead($ed))
			Case $bSave
				Local $dst = FileSaveDialog(TR("另存轉換程式碼"), @ScriptDir, "AutoIt (*.au3)", 16, "Convert.au3", $dlg)
				If Not @error Then
					If StringRight($dst, 4) <> ".au3" Then $dst &= ".au3"
					If _WriteOut($dst, $code) Then
						_Msg(64, "完成", "已另存：" & @CRLF & $dst)
					Else
						_Msg(16, "另存失敗", $g_sLastOutputError)
					EndIf
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	GUISetState(@SW_ENABLE, $hMain) ;;恢復主視窗
	GUIDelete($dlg)
	WinActivate($hMain)
EndFunc   ;==>_ConvShowResult

; 複製轉換結果到剪貼簿
Func _ConvCopy()
	If $g_sConvCode = "" Then
		_Msg(48, "提示", "尚無轉換結果，請先『轉換』。")
		Return
	EndIf
	ClipPut($g_sConvCode)
	_Status("已複製轉換程式碼到剪貼簿。")
EndFunc   ;==>_ConvCopy

; 將轉換結果另存為 .au3
Func _ConvSave()
	Local $code = $g_sConvCode
	If $code = "" Then
		_Msg(48, "提示", "尚無轉換結果，請先『轉換』。")
		Return
	EndIf
	Local $dst = FileSaveDialog("另存轉換程式碼", @ScriptDir, "AutoIt (*.au3)", 16, "Convert.au3", $hMain)
	If @error Then Return
	If StringRight($dst, 4) <> ".au3" Then $dst &= ".au3"
	If Not _WriteOut($dst, $code) Then Return _Msg(16, "另存失敗", $g_sLastOutputError)
	_Msg(64, "完成", "已另存：" & @CRLF & $dst)
EndFunc   ;==>_ConvSave

; ==================================================================
;  小工具
; ==================================================================
Func _WriteOut($dst, $code, $bValidate = False)
	; v18.3：暫存寫入、寫入驗證、可選 AU3Check、備份替換；失敗不覆蓋原輸出。
	$g_sLastOutputError = ""
	Local $enc = GUICtrlRead($g_cboEnc)
	Local $mode = 2 + 8 + 256
	If StringInStr($enc, "無BOM") Then $mode = 2 + 8 + 128
	If StringInStr($enc, "UTF16") Then $mode = 2 + 8 + 32
	If StringInStr($enc, "ANSI") Then $mode = 2 + 8
	Return _SafeCommitFile($dst, $code, $mode, $bValidate)
EndFunc   ;==>_WriteOut

Func _WriteBinaryOut($dst, $blob)
	; RC 密文需保持二進位內容，不可套用 GUI 的文字編碼設定。
	Return _SafeCommitFile($dst, $blob, 2, False)
EndFunc   ;==>_WriteBinaryOut

; v18.3.7：正式輸出使用同資料夾暫存檔與 Win32 同磁碟區原子取代。
; 備份經 .part 階段完整寫入才公布成 .backup，意外中斷不會留下可誤判的半成品備份。
Func _SafeCommitFile($dst, $data, $mode, $bValidate)
    ; 若上一輪在舊版的「舊檔已搬到備份」後崩潰，先救回原檔。
    If Not FileExists($dst) Then _RecoverPendingOutput($dst)
    Local $tmp = $dst & ".obscura-" & @AutoItPID & "-" & Hex(Random(0, 0x7FFFFFFF, 1), 8) & ".tmp.au3"
    Local $bak = $dst & ".obscura-" & @AutoItPID & ".backup"
    Local $i = 0
    While FileExists($tmp) Or FileExists($bak) Or FileExists($bak & ".part")
        $i += 1
        If $i > 40 Then
            $g_sLastOutputError = "無法建立不重複的暫存檔名：" & $dst
            Return False
        EndIf
        $tmp = $dst & ".obscura-" & @AutoItPID & "-" & $i & ".tmp.au3"
        $bak = $dst & ".obscura-" & @AutoItPID & "-" & $i & ".backup"
    WEnd
    Local $h = FileOpen($tmp, $mode)
    If $h = -1 Then
        $g_sLastOutputError = "暫存檔無法建立（請檢查資料夾權限／磁碟空間）：" & $tmp
        Return False
    EndIf
    Local $wrote = FileWrite($h, $data)
    Local $closed = FileClose($h)
    If $wrote <> 1 Or $closed <> 1 Or Not FileExists($tmp) Or (StringLen($data) > 0 And FileGetSize($tmp) <= 0) Then
        $g_sLastOutputError = "寫入暫存檔失敗，正式輸出未變更：" & $dst
        FileDelete($tmp)
        Return False
    EndIf
    ; AU3Check 於正式提交前執行，失敗保留已有輸出檔。
    If $bValidate And GUICtrlRead($g_oAutoCheck) = $GUI_CHECKED Then
        If Not _ValidateAu3File($tmp) Then
            Local $detail = $g_sLastOutputError
            FileDelete($tmp)
            $g_sLastOutputError = "AU3Check 未通過，原輸出未覆蓋。" & @CRLF & $detail
            Return False
        EndIf
    EndIf
    Local $hadOld = FileExists($dst)
    If $hadOld Then
        ; 先複製再交換：即使備份過程失敗，原檔始終留在原位置。
        Local $part = $bak & ".part"
        If Not FileCopy($dst, $part, 0) Or FileGetSize($part) <> FileGetSize($dst) Then
            $g_sLastOutputError = "舊輸出備份失敗，原檔未變更：" & $dst
            FileDelete($part)
            FileDelete($tmp)
            Return False
        EndIf
        If Not FileMove($part, $bak, 0) Then
            $g_sLastOutputError = "無法完成舊檔備份，原檔未變更：" & $dst
            FileDelete($part)
            FileDelete($tmp)
            Return False
        EndIf
        ; MoveFileExW(REPLACE_EXISTING | WRITE_THROUGH) 在同一資料夾完成原子取代。
        Local $aMove = DllCall("kernel32.dll", "bool", "MoveFileExW", "wstr", $tmp, "wstr", $dst, "dword", 0x9)
        Local $moved = False
        If Not @error And IsArray($aMove) Then $moved = ($aMove[0] <> 0)
        If Not $moved Then
            $g_sLastOutputError = "無法以原子方式替換正式輸出，原檔已保留：" & $dst & "；備份：" & $bak
            FileDelete($tmp)
            Return False
        EndIf
        If Not FileDelete($bak) Then _DebugTrace("OUTPUT warning: backup retained " & $bak)
    Else
        ; 新輸出沒有舊檔：同磁碟區檔案搬移，目的路徑不存在才提交。
        If Not FileMove($tmp, $dst, 0) Then
            $g_sLastOutputError = "新檔提交失敗（暫存檔未覆蓋其他檔案）：" & $dst
            FileDelete($tmp)
            Return False
        EndIf
    EndIf
    _DebugTrace("OUTPUT commit success dst=" & $dst)
    Return True
EndFunc   ;==>_SafeCommitFile


; 自動檢查已選來源的兩種主要輸出檔。只對不存在的正式檔復原。
; 如已有正式輸出，絕不把殘留備份覆蓋回去。
Func _RecoverKnownOutputs($src)
    If StringLower(StringRight($src, 4)) <> ".au3" Then Return 0
    Local $stem = StringRegExpReplace($src, "\.[^.]*$", "")
    Local $n = 0
    If _RecoverPendingOutput($stem & "_Obfuscation.au3") Then $n += 1
    If _RecoverPendingOutput($stem & "_Integration.au3") Then $n += 1
    Return $n
EndFunc   ;==>_RecoverKnownOutputs

; 復原舊版異常中斷時留下的完整 .backup；若多份，挑最後修改的一份。
; 僅以暫存檔搬回正式路徑，原始備份不刪除，以利人工追查。
Func _RecoverPendingOutput($dst)
    Local $search = FileFindFirstFile($dst & ".obscura-*.backup")
    If $search = -1 Then Return False
    Local $folder = _DirOf($dst), $best = "", $stamp = ""
    While True
        Local $name = FileFindNextFile($search)
        If @error Then ExitLoop
        Local $candidate = $folder & "\" & $name
        If Not FileExists($candidate) Then ContinueLoop
        Local $modified = FileGetTime($candidate, 0, 1)
        If $best = "" Or StringCompare($modified, $stamp) > 0 Then
            $best = $candidate
            $stamp = $modified
        EndIf
    WEnd
    FileClose($search)
    If $best = "" Then Return False
    If FileExists($dst) Then
        _DebugTrace("RECOVERY backup retained; official file exists: " & $best)
        Return False
    EndIf
    Local $staged = $dst & ".obscura-recover-" & @AutoItPID & ".part"
    If FileExists($staged) Then
        _DebugTrace("RECOVERY pending staged file, skip automatic restore: " & $staged)
        Return False
    EndIf
    If Not FileCopy($best, $staged, 0) Or FileGetSize($staged) <> FileGetSize($best) Then
        FileDelete($staged)
        _DebugTrace("RECOVERY failed to copy backup: " & $best)
        Return False
    EndIf
    If Not FileMove($staged, $dst, 0) Then
        FileDelete($staged)
        _DebugTrace("RECOVERY failed to restore original path: " & $dst)
        Return False
    EndIf
    _DebugTrace("RECOVERY restored missing output " & $dst & " from " & $best)
    Return True
EndFunc   ;==>_RecoverPendingOutput


Func _RandName()
	$g_nameCounter += 1
	; 一般:a-z;易混淆:l I 1 O 0(人眼難辨;名稱不分大小寫,靠流水號後綴保證唯一)
	Local $s = "_", $az = $g_confName ? "lI1O0" : "abcdefghijklmnopqrstuvwxyz", $i
	Local $n = StringLen($az)
	For $i = 1 To $g_nameLen
		$s &= StringMid($az, Random(1, $n, 1), 1)
	Next
	Return $s & Hex($g_nameCounter, 4)
EndFunc   ;==>_RandName

Func _StrAdd($strs, $strRaw, $strNoEnc, $strPure, $inner, $raw, $noEnc, $pure)
	Local $idx = $strs.Count
	$strs.Add($idx, $inner)
	$strRaw.Add($idx, $raw)
	$strNoEnc.Add($idx, $noEnc)
	$strPure.Add($idx, $pure)
	Return $idx
EndFunc   ;==>_StrAdd

Func _CmtAdd($cmts, $val)
	Local $idx = $cmts.Count
	$cmts.Add($idx, $val)
	Return $idx
EndFunc   ;==>_CmtAdd

Func _DirOf($p)
	Local $pos = StringInStr($p, "\", 0, -1)
	If $pos = 0 Then Return "."
	Return StringLeft($p, $pos - 1)
EndFunc   ;==>_DirOf

Func _FullPath($p)
	Local $f = _WinAPI_GetFullPathName($p)
	If @error Or $f = "" Then Return $p
	Return $f
EndFunc   ;==>_FullPath

Func _GuessIncludeDir()
	Local $a = "C:\Program Files (x86)\AutoIt3\Include"
	Local $b = "C:\Program Files\AutoIt3\Include"
	If FileExists($a) Then Return $a
	If FileExists($b) Then Return $b
	Return $a
EndFunc   ;==>_GuessIncludeDir

; 猜測 AU3Check.exe 路徑(由標準庫 Include 推回 AutoIt3 根目錄)
Func _GuessAu3Check()
	Local $inc = _GuessIncludeDir()
	Local $root = StringRegExpReplace($inc, "\\[^\\]*$", "") ;;去掉結尾的 \Include
	Local $cand[3] = [$root & "\AU3Check.exe", $root & "\Beta\AU3Check.exe", $inc & "\AU3Check.exe"]
	Local $i
	For $i = 0 To UBound($cand) - 1
		If FileExists($cand[$i]) Then Return $cand[$i]
	Next
	Return ""
EndFunc   ;==>_GuessAu3Check

; v18.3：可選 AU3Check 在暫存檔階段執行，依離開碼與錯誤數判定。
; v18.3.7：使用同步權限行程 Handle（不是 PID 存活輪詢）確認 AU3Check 結束。
; 偵測不到明確的 0 離開碼時一律視為驗證失敗，避免誤提交無效輸出。
Func _ValidateAu3File($file)
    $g_iLastAu3CheckExit = -1
    $g_sLastAu3CheckOutput = ""
    Local $exe = StringStripWS(GUICtrlRead($g_inAu3Check), 3)
    If $exe = "" Then $exe = _GuessAu3Check()
    If $exe = "" Or Not FileExists($exe) Then
        $g_sLastOutputError = "已啟用 AU3Check，但找不到 AU3Check.exe。請在參數設定指定路徑，或關閉自動驗證。"
        Return False
    EndIf
    Local $pid = Run('"' & $exe & '" "' & $file & '"', _DirOf($file), @SW_HIDE, 2 + 4)
    If @error Or $pid <= 0 Then
        $g_sLastOutputError = "AU3Check 無法啟動：" & $exe
        Return False
    EndIf
    ; SYNCHRONIZE (0x100000) + QUERY_LIMITED_INFORMATION (0x1000)；只要查詢和等待權限。
    Local $aOpen = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", 0x101000, "bool", False, "dword", $pid)
    If @error Or Not IsArray($aOpen) Then
        $g_sLastOutputError = "無法開啟 AU3Check 行程 Handle，為安全起見不提交輸出。"
        Return False
    EndIf
    Local $hProcess = $aOpen[0]
    If $hProcess = 0 Then
        $g_sLastOutputError = "AU3Check 行程結束太快或權限不足，無法取得可靠離開碼。"
        Return False
    EndIf
    Local $output = "", $start = TimerInit(), $timedOut = False, $waitFailed = False
    While True
        $output &= StdoutRead($pid)
        $output &= StderrRead($pid)
        Local $aWait = DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $hProcess, "dword", 0)
        If @error Or Not IsArray($aWait) Then
            $waitFailed = True
            ExitLoop
        EndIf
        Switch $aWait[0]
            Case 0 ; WAIT_OBJECT_0: 行程確實結束
                ExitLoop
            Case 258 ; WAIT_TIMEOUT: 行程仍在執行
                If TimerDiff($start) > 90000 Then
                    $timedOut = True
                    ProcessClose($pid)
                    DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $hProcess, "dword", 2000)
                    ExitLoop
                EndIf
            Case Else ; WAIT_FAILED 或未預期狀態
                $waitFailed = True
                ExitLoop
        EndSwitch
        Sleep(30)
    WEnd
    $output &= StdoutRead($pid)
    $output &= StderrRead($pid)
    $g_sLastAu3CheckOutput = StringStripWS($output, 3)
    If Not $timedOut And Not $waitFailed Then
        Local $aExit = DllCall("kernel32.dll", "bool", "GetExitCodeProcess", "handle", $hProcess, "dword*", 0)
        If Not @error And IsArray($aExit) Then
            If $aExit[0] Then $g_iLastAu3CheckExit = $aExit[2]
        EndIf
    EndIf
    DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hProcess)
    If $g_logOn Then _LogLine("AU3Check 離開碼：" & $g_iLastAu3CheckExit & @CRLF & $g_sLastAu3CheckOutput)
    _DebugTrace("OUTPUT AU3Check exit=" & $g_iLastAu3CheckExit & " timeout=" & $timedOut & " waitFailed=" & $waitFailed)
    If $timedOut Then
        $g_sLastOutputError = "AU3Check 超過 90 秒，已中止驗證。"
        Return False
    EndIf
    If $waitFailed Then
        $g_sLastOutputError = "AU3Check 行程等待失敗，未能可靠取得驗證結果。"
        Return False
    EndIf
    If $g_iLastAu3CheckExit <> 0 Or StringRegExp($g_sLastAu3CheckOutput, '(?i)\b[1-9][0-9]*\s+error\(s\)') Then
        $g_sLastOutputError = "AU3Check 離開碼 " & $g_iLastAu3CheckExit & ":" & @CRLF & StringLeft($g_sLastAu3CheckOutput, 3500)
        Return False
    EndIf
    Return True
EndFunc   ;==>_ValidateAu3File


; ==================================================================
; v18.3.7 整合與混淆說明：靜態分區，避免 Win32 EDIT 捲動/重繪重影。
; 所有座標以內容子視窗為原點，不產生可獲得鍵盤焦點的表單控制項。
; ==================================================================
Func _MainHelpLabel($sText, $x, $y, $w, $h, $iSize = 10, $bBold = False, $iColor = 0x24242B, $iBg = 0xFFFFFF)
    Local $id = GUICtrlCreateLabel($sText, S($x), S($y), S($w), S($h), $SS_LEFT)
    GUICtrlSetBkColor($id, $iBg)
    GUICtrlSetColor($id, $iColor)
    If $bBold Then
        GUICtrlSetFont($id, $iSize, 700, 0, "Microsoft JhengHei UI", 5)
    Else
        GUICtrlSetFont($id, $iSize, 400, 0, "Microsoft JhengHei UI", 5)
    EndIf
    Return $id
EndFunc

Func _BuildMainHelpStatic()
    ; 頁面 S(772) x S(560)。文字配置不交疊，也不使用多行 Edit / Radio。
    _MainHelpLabel("操作流程", 22, 46, 714, 27, 11, True, 0x15151B)
    _MainHelpLabel("1. 將 .au3 腳本拖入上方欄位（或按「...」選取）。" & @CRLF & _
            "2. 於「參數設定 → 腳本整合／腳本混淆」勾選所需選項。" & @CRLF & _
            "3. 按上方工具列「腳本整合」或「執行混淆」。" & @CRLF & _
            "4. 在「執行情況」查看進度；輸出檔產生於原腳本資料夾。", _
            22, 80, 715, 114, 10)

    Local $divider1 = GUICtrlCreateLabel("", S(22), S(204), S(714), S(1))
    GUICtrlSetBkColor($divider1, 0xE2E4E8)

    _MainHelpLabel("忽略指令（寫在來源腳本中，支援正規表示式）", 22, 216, 715, 27, 11, True, 0x15151B)
    _MainHelpLabel("#Obfuscator_Ignore_Funcs=func\d,MyFunc" & @CRLF & _
            "#Obfuscator_Ignore_Variables=\$Var\d", 34, 249, 690, 62, 10, False, 0x282C34, 0xF3F5F8)

    Local $divider2 = GUICtrlCreateLabel("", S(22), S(321), S(714), S(1))
    GUICtrlSetBkColor($divider2, 0xE2E4E8)

    _MainHelpLabel("注意事項", 22, 332, 714, 27, 11, True, 0x15151B)
    _MainHelpLabel("• 使用前請先確認原腳本能正常編譯執行。" & @CRLF & _
            "• 以字串註冊／呼叫的函式（Eval／Execute／GUIRegisterMsg 等），" & @CRLF & _
            "  應使用忽略指令排除，或讓字串僅包含完整函式名稱。" & @CRLF & _
            "• 已混淆的腳本請勿再次混淆。" & @CRLF & _
            "• 字串加密會略過 Const／函式宣告／FileInstall 第一個參數。" & @CRLF & _
            "• 清除未使用函式／變數為啟發式功能，啟用後務必測試。", _
            22, 365, 715, 165, 10)
EndFunc

; v18.3.7：原先的 Edit 說明文字函式已移除，避免保留兩套相同說明。   ;==>_MainHelpText

 ; ==================================================================
;  內建函式安全隨機名稱包裝 v18
;  - 只處理有明確參數簽章、無 ByRef/變動參數副作用的內建函式。
;  - 同一內建函式若以不同參數數量呼叫，建立不同名稱的包裝器。
;  - 逐行詞法掃描，不變更引號字串、行註解、# 指令、Func 宣告或物件方法。
;  - 無法在單行內確認配對右括號時略過；不猜測跨行呼叫。
;  - 將來源檔中已宣告的同名 UDF 排除，避免改變使用者函式呼叫目標。
;  - 包裝器只轉送值參數，刻意不支援 ByRef、動態 Call / Eval。
;  - 一般情況會轉送 @error/@extended；極端呼叫堆疊與副作用仍應測試。
; ==================================================================
Func _WrapBuiltinFunctions(ByRef $code)
    ; v18.1：輸出採分批串接，不再為每個函式名稱反覆以 PCRE 掃描全部來源。
    ; 錯誤或逾時時不提交處理到一半的原始碼。
    Local $tStart = TimerInit()
    Local $specs = StringSplit("StringLen:1:1|StringLower:1:1|StringUpper:1:1|StringReverse:1:1|" & _
        "StringLeft:2:2|StringRight:2:2|StringMid:2:3|StringTrimLeft:2:2|StringTrimRight:2:2|StringInStr:2:6|StringReplace:3:5|" & _
        "StringStripWS:2:2|StringStripCR:1:1|StringAddCR:1:1|StringCompare:2:3|StringSplit:2:3|" & _
        "StringRegExp:2:3|StringRegExpReplace:3:4|StringToBinary:1:2|BinaryToString:1:2|" & _
        "StringIsAlNum:1:1|StringIsAlpha:1:1|StringIsASCII:1:1|StringIsDigit:1:1|" & _
        "StringIsFloat:1:1|StringIsInt:1:1|StringIsLower:1:1|StringIsSpace:1:1|StringIsUpper:1:1|StringIsXDigit:1:1|" & _
        "Abs:1:1|Sqrt:1:1|Exp:1:1|Log:1:1|Sin:1:1|Cos:1:1|Tan:1:1|ASin:1:1|ACos:1:1|ATan:1:1|" & _
        "Ceiling:1:1|Floor:1:1|Round:1:2|Int:1:2|Number:1:2|Mod:2:2|" & _
        "Chr:1:1|ChrW:1:1|Asc:1:1|AscW:1:1|Hex:1:2|Dec:1:2|Binary:1:1|BinaryLen:1:1|" & _
        "IsArray:1:1|IsBinary:1:1|IsBool:1:1|IsFloat:1:1|IsHWnd:1:1|IsInt:1:1|IsNumber:1:1|IsObj:1:1|IsPtr:1:1|IsString:1:1|BitNOT:1:1|BitShift:2:2", 2)
    Local $valid = ObjCreate("Scripting.Dictionary")
    If Not IsObj($valid) Then Return -1
    For $i = 0 To UBound($specs) - 1
        Local $parts = StringSplit($specs[$i], ":", 2)
        If UBound($parts) = 3 Then $valid.Item(StringLower($parts[0])) = $specs[$i]
    Next
    Local $udfNames = ObjCreate("Scripting.Dictionary")
    Local $funcs = StringRegExp($code, "(?im)^\s*Func\s+([A-Za-z_]\w*)\s*\(", 3)
    If IsArray($funcs) Then
        For $i = 0 To UBound($funcs) - 1
            $udfNames.Item(StringLower($funcs[$i])) = True
        Next
    EndIf

    Local $wrappers = ObjCreate("Scripting.Dictionary"), $usedNames = ObjCreate("Scripting.Dictionary")
    If Not IsObj($wrappers) Or Not IsObj($usedNames) Then Return -1
    Local $source = $code
    Local $n = StringLen($source), $cursor = 1, $lineCount = 0, $total = 0
    Local $chunk = "", $result = ""
    _DebugTrace("BUILTIN init chars=" & $n)
    While $cursor <= $n
        Local $nl = StringInStr($source, @LF, 0, 1, $cursor)
        Local $ln = ""
        If $nl = 0 Then
            $ln = StringMid($source, $cursor)
            $cursor = $n + 1
        Else
            $ln = StringMid($source, $cursor, $nl - $cursor)
            $cursor = $nl + 1
        EndIf
        ; 極長單行/可能跨行的式子略過，避免解析器反覆尋找配對括號造成卡頓。
        If StringLen($ln) <= 16384 And StringInStr($ln, "(") And Not StringRegExp($ln, "(?i)^\s*(?:#|Func\b|EndFunc\b|(?:Global|Local|Dim|Static)\s+Const\b)") Then
            $ln = _BW_TransformLine($ln, $valid, $udfNames, $wrappers, $usedNames, $source, $total)
        EndIf
        $chunk &= $ln
        If $nl <> 0 Then $chunk &= @LF
        $lineCount += 1
        If Mod($lineCount, 250) = 0 Then
            $result &= $chunk
            $chunk = ""
            If Mod($lineCount, 2000) = 0 Then
                _DebugTrace("BUILTIN progress lines=" & $lineCount & " matches=" & $total & " elapsedMs=" & Int(TimerDiff($tStart)))
            EndIf
            If $g_stop Or TimerDiff($tStart) > 90000 Then
                _DebugTrace("BUILTIN abort lines=" & $lineCount & " stopped=" & $g_stop & " elapsedMs=" & Int(TimerDiff($tStart)))
                Return -1
            EndIf
        EndIf
    WEnd
    $result &= $chunk
    If $g_stop Then Return -1
    ; 名稱碰撞只在建立新包裝器時檢查一次，不對每個呼叫掃描大檔。
    For $key In $wrappers.Keys()
        Local $info = StringSplit($key, "/", 2)
        Local $arity = Number($info[1]), $entry = StringSplit($valid.Item($info[0]), ":", 2)
        Local $name = $entry[0], $alias = $wrappers.Item($key)
        Local $args = "", $params = ""
        For $k = 0 To $arity - 1
            If $k > 0 Then
                $params &= ", "
                $args &= ", "
            EndIf
            $params &= "$_bw" & $k
            $args &= "$_bw" & $k
        Next
        $result &= @LF & "Func " & $alias & "(" & $params & ")" & @LF
        $result &= "    Local $_bwResult = " & $name & "(" & $args & ")" & @LF
        $result &= "    Local $_bwError = @error, $_bwExtended = @extended" & @LF
        $result &= "    Return SetError($_bwError, $_bwExtended, $_bwResult)" & @LF
        $result &= "EndFunc" & @LF
    Next
    $code = $result
    _DebugTrace("BUILTIN complete lines=" & $lineCount & " calls=" & $total & " wrappers=" & $wrappers.Count & " elapsedMs=" & Int(TimerDiff($tStart)))
    Return $total
EndFunc

; 掃描單行：只改寫程式碼識別字；不觸碰字串、註解、字串抽取佔位符。
Func _BW_TransformLine($line, $valid, $udfNames, $wrappers, $usedNames, $source, ByRef $total)
    Local $out = "", $n = StringLen($line), $i = 1
    While $i <= $n
        Local $ch = StringMid($line, $i, 1)
        ; 字串抽取器用 Chr(2)..Chr(5) 保存字串與註解內容。
        If $ch = Chr(2) Or $ch = Chr(4) Then
            Local $close = ($ch = Chr(2)) ? Chr(3) : Chr(5)
            Local $pEnd = StringInStr($line, $close, 0, 1, $i + 1)
            If $pEnd = 0 Then $pEnd = $n
            $out &= StringMid($line, $i, $pEnd - $i + 1)
            $i = $pEnd + 1
            ContinueLoop
        EndIf
        If $ch = ";" Then
            $out &= StringMid($line, $i)
            ExitLoop
        EndIf
        If $ch = '"' Or $ch = "'" Then
            Local $quote = $ch, $j = $i + 1
            While $j <= $n
                If StringMid($line, $j, 1) = $quote Then
                    If $j < $n And StringMid($line, $j + 1, 1) = $quote Then
                        $j += 2
                        ContinueLoop
                    EndIf
                    $j += 1
                    ExitLoop
                EndIf
                $j += 1
            WEnd
            $out &= StringMid($line, $i, $j - $i)
            $i = $j
            ContinueLoop
        EndIf
        Local $ccode = Asc($ch)
        If Not (($ccode >= 65 And $ccode <= 90) Or ($ccode >= 97 And $ccode <= 122) Or $ccode = 95) Then
            $out &= $ch
            $i += 1
            ContinueLoop
        EndIf
        Local $begin = $i
        $i += 1
        While $i <= $n
            $ccode = Asc(StringMid($line, $i, 1))
            If Not (($ccode >= 65 And $ccode <= 90) Or ($ccode >= 97 And $ccode <= 122) Or ($ccode >= 48 And $ccode <= 57) Or $ccode = 95) Then ExitLoop
            $i += 1
        WEnd
        Local $word = StringMid($line, $begin, $i - $begin)
        Local $lower = StringLower($word)
        Local $prev = ($begin > 1) ? StringMid($line, $begin - 1, 1) : ""
        If Not $valid.Exists($lower) Or $udfNames.Exists($lower) Or StringRegExp($prev, "[A-Za-z0-9_.$@]") Then
            $out &= $word
            ContinueLoop
        EndIf
        Local $openPos = $i
        While $openPos <= $n And (StringMid($line, $openPos, 1) = " " Or StringMid($line, $openPos, 1) = @TAB)
            $openPos += 1
        WEnd
        If $openPos > $n Or StringMid($line, $openPos, 1) <> "(" Then
            $out &= $word
            ContinueLoop
        EndIf
        Local $argc = _BW_CountArgs($line, $openPos)
        Local $def = StringSplit($valid.Item($lower), ":", 2)
        If $argc < Number($def[1]) Or $argc > Number($def[2]) Then
            $out &= $word
            ContinueLoop
        EndIf
        Local $key = $lower & "/" & $argc
        If Not $wrappers.Exists($key) Then
            Local $alias = ""
            Do
                $alias = "_OBW_" & Hex(Random(0, 0x7FFFFFFF, 1), 8) & Hex(Random(0, 0x7FFFFFFF, 1), 8)
            Until Not $usedNames.Exists(StringLower($alias)) And StringInStr($source, $alias, 0) = 0
            $usedNames.Item(StringLower($alias)) = 1
            $wrappers.Item($key) = $alias
        EndIf
        $out &= $wrappers.Item($key)
        $total += 1
    WEnd
    Return $out
EndFunc

; 計算單行內呼叫參數數，巢狀括號與陣列 [] 中的逗號不算分隔符。
; 無配對括號、未知字串結構或跨行呼叫都回傳 -1，避免錯誤包裝。
Func _BW_CountArgs($line, $openPos)
    Local $n = StringLen($line), $depth = 0, $brackets = 0, $commas = 0, $hasValue = False
    Local $quote = ""
    For $i = $openPos To $n
        Local $ch = StringMid($line, $i, 1)
        If $quote <> "" Then
            If $ch = $quote Then
                If $i < $n And StringMid($line, $i + 1, 1) = $quote Then
                    $i += 1
                Else
                    $quote = ""
                EndIf
            EndIf
            ContinueLoop
        EndIf
        If $ch = '"' Or $ch = "'" Then
            $quote = $ch
            If $depth = 1 Then $hasValue = True
            ContinueLoop
        EndIf
        If $ch = ";" Or $ch = Chr(4) Then Return -1
        If $ch = "(" Then
            $depth += 1
            If $depth = 2 Then $hasValue = True
        ElseIf $ch = ")" Then
            $depth -= 1
            If $depth = 0 Then
                If Not $hasValue And $commas = 0 Then Return 0
                Return $commas + 1
            EndIf
            If $depth < 0 Then Return -1
        ElseIf $ch = "[" Then
            $brackets += 1
            If $depth = 1 Then $hasValue = True
        ElseIf $ch = "]" Then
            $brackets -= 1
        ElseIf $ch = "," Then
            If $depth = 1 And $brackets = 0 Then $commas += 1
        ElseIf $depth = 1 And $ch <> " " And $ch <> @TAB And $ch <> @CR Then
            $hasValue = True
        EndIf
    Next
    Return -1
EndFunc
