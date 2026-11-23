# DdgoCabDisplay

DdgoMascon(Windows / C#)の計器の値を LAN 経由で受け取り、Linux 機や Raspberry Pi につないだモニターに運転台の表示を出すアプリです。Qt6 + QML で作っています。

## デザイン

表示機の画面で切り替えられます。キーボードなら 1〜5、タッチパネルなら右上の角をタップして出るメニューから選びます。

| キー | デザイン | 参考にした表示 |
|---|---|---|
| 1 | TIMS 風 | JR東日本 E233 系などの運転台モニター。黒地に水色の見出しで、上に情報帯、下に画面切替ボタンが並びます。「運転情報」「車両状態」(編成図・各車の力行/回生/ブレーキ/CP/SIV)「運転記録」(直近 2 分の速度・制限・ノッチのグラフ)「路線」の 4 画面があり、← → キーでも切り替えられます |
| 2 | グラスコックピット | E235 系や新幹線 E7 系のように、速度計も液晶に描く表示。速度の帯と、速度計の下の切れ目にノッチの弧(右が力行、左がブレーキ)があります |
| 3 | 私鉄・JR西 風 | 白地に紺の帯と橙のアクセント(225 系や N700S のモニター風)。車内案内のような横の路線図と、横一列のノッチ |
| 4 | 計器盤 | DdgoMascon の「計器表示(別モニター)」と同じ並び。ヘアライン仕上げのパネルに、クロームの縁・ねじ・ガラスの映り込み付きの計器 5 つ、宝石形の表示灯、2 ハンドルのノッチ |
| 5 | シンプル | 落ち着いた暗い面に角丸のカードを並べた、シンプルでモダンな表示。計器はすべてアナログ(速度・空気圧・電流・架線電圧・加速度)で、文字は控えめな大きさ。発光などの飾りはありません |

`samples/` に各デザインの画面例があります。

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
- `./run.sh -w -t glass`: ウィンドウ表示で、グラスコックピット風で起動します
- `./run.sh --help`: そのほかのオプション(ポートの変更など)

デスクトップの無い Raspberry Pi で、コンソールから直接画面に出すときは、`run.sh` が自動で `eglfs` を使います。ログイン時に自動で起動したいときは、`autostart/ddgo-cabdisplay.desktop` の Exec のパスを書き換えてから `~/.config/autostart/` に置いてください。

### 操作

| キー / 操作 | 動作 |
|---|---|
| 1〜5 | デザインの切り替え |
| ← → | TIMS 風の画面切り替え |
| D | デモ走行のオン/オフ |
| F11 / F | 全画面の切り替え |
| M / Tab / 右上の角をタップ | メニュー |
| Esc | メニューを閉じる / 全画面を抜ける |
| Ctrl+Q | 終了 |

選んだデザインは `~/.config/DdgoMascon/DdgoCabDisplay.conf` に保存され、次に起動したときも同じデザインで始まります。

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
qml/Main.qml          画面の拡大縮小・メニュー・キー操作
qml/themes/*.qml      4 つのデザイン
qml/parts/*.qml       計器・ノッチ・停止位置の帯・路線の帯・表示灯などの部品
fonts/                IBM Plex Sans JP(埋め込み用)とライセンス
samples/              画面例
```

画面は 1600×900 の固定の配置で作っていて、モニターの大きさに合わせて縦横比を保ったまま拡大縮小します。800×480 のタッチパネルでも同じ配置で表示されます。

画像の検証は `QT_QPA_PLATFORM=offscreen ./build/ddgo-cabdisplay -t tims --screenshot out.png --demo-time 75` のように実行します。デモを 75 秒進めた画面を保存して終了します。
