# App Store — zh-Hant

**Version 0.1.1** — same number as the GitHub release, deliberately: one
number, one binary, one set of changes, wherever someone finds the app.

## Name (30)

CleanMenuBar

## Subtitle (30)

整理你的選單列

## Keywords (100)

隱藏,收起,圖像,選單列,狀態列,整理,清爽,效率,瀏海,快速鍵,極簡

## Promotional text (170)

隱藏你用不到的圖像，需要時再顯示。無需權限，不收集資料，不連網。MIT 授權條款開源。

## Description (4000)

選單列圖像太多？CleanMenuBar 隱藏你不想看到的圖像，需要時再顯示出來。

運作方式

選單列中會出現兩個項目：一個細分隔符號「|」和一個箭頭「>」。

按住 ⌘ 並將想隱藏的圖像拖曳至分隔符號「|」的左側。位於其右側的圖像始終保持可見。點一下箭頭「>」收合，點一下「<」展開——或在任何地方按 ⌃⌥⌘C。

整理完成後，在設定中開啟「隱藏分隔符號」，螢幕上便只留下箭頭。

位置在重新啟動後依然保留。macOS 會記住每個圖像的位置。

功能

• 點一下、全域快速鍵，或僅將指標停留其上即可隱藏與顯示
• 永遠隱藏的區域，用於你永遠不想看到的圖像
• 5、10、15、30 或 60 秒後自動收合
• 啟動時回復上次的狀態
• 登入時自動開啟
• 九種語言

無需權限

CleanMenuBar 不請求任何特殊權限。既不需要「輔助使用」，也不需要「螢幕錄製」——這在選單列工具中並不常見，之所以可行，是因為全域快速鍵使用了無需這些權限的 API，且該 App 從不讀取螢幕。

它也沒有網路權限。即使程式碼嘗試，也無法傳送任何內容。沙箱容器之外的內容一概不讀取。

需要 macOS 27

macOS 27 將選單列重建為單一視窗，部分 App 所用的技術隨之失效。CleanMenuBar 在 macOS 27 公開發布次日，於該系統上直接開發並實測。

不支援更早的 macOS 版本——也無需支援：在那些系統上，舊技術仍然有效。

由於 macOS 27 無法在 Intel 晶片的 Mac 上執行，CleanMenuBar 需要 Apple Silicon。

開源

完整原始碼以 MIT 授權條款公開，其中包括宣告 App 權限範圍的檔案。你無需相信以上任何說法——可以自行查證。

github.com/atilac/CleanMenuBar

致謝

CleanMenuBar 建立在 Dwarves Foundation 的 Hidden Bar 之上，依 MIT 授權條款使用。其選單、設定與文案均源自該專案。感謝六年來讓它持續存在的每一位。

## What's New

CleanMenuBar 的首個公開版本。
