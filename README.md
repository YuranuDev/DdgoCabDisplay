# DdgoCabDisplay

DdgoMascon(Windows / C#)の計器の値を LAN 経由で受け取り、Linux 機や Raspberry Pi につないだモニターに運転台の表示を出すアプリです。Qt6 + QML で作っています。

## デザイン

実際の車両の表示をまねるのではなく、見やすさと操作しやすさを優先した 1 つのデザインです。メニューで次の 3 つを切り替えられます。

| 項目 | 選択肢 |
|---|---|
| 配色 | 暗い(夜・暗い部屋向け)/ 明るい(昼・明るい部屋向け) |
| 並び | 標準(速度計・ノッチ・停止位置・小さな計器 4 つ・運行情報・状態)/ 計器重視(速度計を大きく、左にノッチ、右に空気圧・電流・停止位置) |
| 文字の大きさ | 標準 / 大きい |

- 計器はアナログ(針と弧)で、数字も一緒に出します。光る効果などの飾りはありません。
- 色の意味はどこでも同じです: 青 = 速度・回生、緑 = 力行・定位置、橙 = ブレーキ、赤 = 非常・超過、黄 = 制限・注意。
- 上の帯の中央には、普段は次の駅を出します。非常ブレーキ・速度超過・停止位置の行き過ぎ・分岐の注意・受信なしなどがあると、そこに注意を 1 つ(重要なものから)出します。

`samples/` に画面例があります。

文字には IBM Plex Sans JP(SIL Open Font License 1.1、`fonts/OFL-IBMPlexSansJP.txt`)を実行ファイルに埋め込んで使っています。Linux 側に日本語フォントを入れる必要はありません。

## 準備(Linux 機 / Raspberry Pi)

Qt 6.4 以降が必要です。Raspberry Pi OS bookworm、Debian 12、Ubuntu 24.04 の標準パッケージで足ります。

Windows からコピーすると実行権限が外れるので、最初に `chmod +x *.sh` を実行してください。

```sh
chmod +x *.sh
./install-deps.sh   # 必要なパッケージを入れる(最初の 1 回だけ)
./build.sh          # ビルドすると build/ddgo-cabdisplay ができる
./run.sh            # 全画面で起動して受信を待つ
```

- `./run.sh --demo`: 受信なしでデモ走行を表示します(画面の確認用)
- `./run.sh -w --layout gauges --palette light`: ウィンドウ表示で、計器重視・明るい配色で起動します
- `./run.sh --help`: そのほかのオプション(ポートの変更など)

デスクトップの無い Raspberry Pi で、コンソールから直接画面に出すときは、`run.sh` が自動で `eglfs` を使います。ログイン時に自動で起動したいときは、`autostart/ddgo-cabdisplay.desktop` の Exec のパスを書き換えてから `~/.config/autostart/` に置いてください。

### 操作 (キーボードは要りません)

右上の「メニュー」ボタンを押すと、すべての設定と操作ができます。タッチパネルでもマウスでも同じです。

- 配色 / 並び / 文字の大きさの切り替え
- 全画面のオン/オフ、デモ走行のオン/オフ
- 受信ポートの変更(−10 / −1 / +1 / +10 / 既定)。その場で受信し直すので再起動は要りません
- 接続の状態(受信元・回数、この表示機のホスト名と IP)
- アプリの終了(誤操作を防ぐため、2 回押すと終了)

受信が無いときは画面の中央に案内が出て、「デモ走行を見る」「メニュー」のボタンから操作できます。

設定は `~/.config/DdgoMascon/DdgoCabDisplay.conf` に保存され、次に起動したときもそのまま使われます。

キーボードがあるときは近道として、M / Tab(メニュー)、F11(全画面)、D(デモ)、Esc(閉じる)、Ctrl+Q(終了)も使えます。

## DdgoMascon 側の設定

1. 設定画面の「表示」→「外部表示 (Linux)」で「外部表示へ送信する」をオンにします。
2. 同じ LAN にいる表示機は、自分から名乗り出るので自動で見つかります。見つかった表示機はその画面に表示されます。
3. 見つからないときは「送り先」に表示機の IP(例 `192.168.1.50`)か、ブロードキャストアドレス(例 `192.168.1.255`)を書いてください。
4. Windows のファイアウォールで、DdgoMascon の UDP 受信(ポート 24681)を許可してください。自動検出に使います。

## 通信の仕組み

| 向き | ポート | 中身 |
|---|---|---|
| DdgoMascon → 表示機 | UDP 24680 | 1 パケットに JSON を 1 つ。既定で毎秒 30 回 |
| 表示機 → DdgoMascon | UDP 24681 | 2 秒ごとに `{"hello":"DdgoCabDisplay","name":"<ホスト名>","port":24680,"v":1}` をブロードキャスト |

DdgoMascon は hello を受け取ると、その表示機に 15 秒間送ります。表示機が止まっても DdgoMascon 側には影響しません。表示機は 1.5 秒受信が無いと「受信待ち」を出します。

JSON の例(項目名は `Core/CabLink.cs` の `CabPacket` と同じです):

```json
{"v":1,"seq":120,"t":1763900000000,"connected":true,"output":true,"rx":true,
 "speed":42.5,"speedMax":120,"limit":45,"accel":-2.1,
 "notch":{"p":0,"b":5,"maxP":5,"maxB":8,"sentP":0,"sentB":4,"pending":1,"name":"B5","rev":1},
 "bc":260,"mr":790,"bcTarget":0,"bcService":440,"bcEmergency":500,"mrMin":780,"mrMax":880,
 "current":-210,"currentMax":600,"volt":1554,"voltNominal":1500,"regen":0.6,"mode":"回生","cp":true,"emergency":false,
 "train":"2000A 快速","cars":4,"cab":"main","line":"本線","prev":"西町","next":"中央","nextDist":86,
 "switch":{"dist":40,"way":"左へ","conflict":false},
 "stop":{"station":"中央","marker":"4両","dist":85.6,"tol":0.5},
 "ahead":[{"kind":"station","label":"中央","dist":85.6,"conflict":false}]}
```

- `notch.b` が `maxB` より大きいときは非常ブレーキです。
- `stop.dist` は、プラスなら停止位置の手前、マイナスなら行き過ぎです(単位 m)。
- 届かなかった項目は省きます。表示側では「--」や「—」になります。

## ファイル

```
CMakeLists.txt        ビルド設定
src/main.cpp          起動・オプション・フォントの埋め込み・画像保存
src/cablink.*         UDP の受信と hello の送信
src/demosource.*      デモ走行(駅間を走って止まる列車)
qml/Main.qml          上の帯・注意・メニュー(設定)・受信待ちの案内・画面の拡大縮小
qml/views/*.qml       並び(標準 / 計器重視)
qml/parts/*.qml       配色 (Pal)・計器・ノッチ・停止位置の帯・カード・ボタンなどの部品
fonts/                IBM Plex Sans JP(埋め込み用)とライセンス
samples/              画面例
```

画面は 1600×900 の固定の配置で作っていて、モニターの大きさに合わせて縦横比を保ったまま拡大縮小します。800×480 のタッチパネルでも同じ配置で表示されます。

画像の検証は `QT_QPA_PLATFORM=offscreen ./build/ddgo-cabdisplay --layout standard --palette dark --screenshot out.png --demo-time 95` のように実行します。デモを 75 秒進めた画面を保存して終了します。
