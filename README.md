# WeatherClock
![WeatherClock](https://github.com/takjn/weatherclock/raw/master/images/WeatherClock.jpg)

GR-CITRUS with WA-MIKAN(WiFi、MP3)のデモです。ボタンを押すと、今日と明日の天気予報をインターネットから取得して読み上げます。

## 事前準備

合成音声ファイルの作成には、東芝が提供するリカイアスのAPIを使います。
[RECAIUS™ Developers](https://developer.recaius.io/jp/top.html)からデベロッパー登録を行い、RECAIUS™ APIを利用するためのIDとパスワードを取得してください。

## 天気予報の取得

天気予報の取得にはlivedoorが提供する[お天気Webサービス](http://weather.livedoor.com/weather_hacks/webservice)を使います。天気予報を取得する場所のパラメーターとしてcityを指定する必要があります。 [全国の地点定義表（RSS）](http://weather.livedoor.com/forecast/rss/primary_area.xml)を見てcityのidを確認してください。

## サーバーAPIの実装

サーバーサイドAPIでは、`http://localhost:1880/forecast.wav`にアクセスすると、天気予報の合成音声ファイル(wavファイル)を作成して返します。サーバーサイドAPIは[Node-RED](https://nodered.org/)を利用して実装します。なお、Node-REDには[Node-RED日本ユーザー会](https://nodered.jp/)もあります。

### Node-REDの設定手順
* [Node.js](https://nodejs.org/ja/)をインストールしてください。
* [Node-RED](https://nodered.org/)をインストールしてください。
* コマンドプロンプトで、`node-red`を起動してください。
* ログにServer now runningが表示されたら、ブラウザで [http://127.0.0.1:1880/](http://127.0.0.1:1880/)へアクセスしてください。
* 右上のメニューボタン > import > Clipboardを選び、Import Nodesダイアログを開いてください。後述のNode-REDのソースコードの内容をコピーして、ダイアログにペーストし、Importボタンを押してください。
* 正常にフローが取り込まれたら、`天気予報取得`のノード(箱)をダブルクリックしてください。URLのcityを天気予報を取得したい場所に変更してください。また、`IDとパスワードの設定`のノード（箱）をダブルクリックしてください。service_idとpasswordにリカイアスのデベロッパー登録で取得した音声合成APIの音声合成サービス利用IDとパスワードを設定してください。
* 右上のDeployボタンを押して、反映してください。
*  [http://127.0.0.1:1880/forecast.wav](http://127.0.0.1:1880/forecast.wav)へアクセスすると、天気予報の合成音声ファイル(wavファイル)が取得できます。

### Node-REDのソースコード

```
[
    {
        "id": "8f728e50.32a3a",
        "type": "function",
        "z": "4ec6c862.fe52a8",
        "name": "IDとパスワードの設定",
        "func": "msg.payload=\n{\n \"speech_synthesis\":{\n \"service_id\":\"*****\",\n \"password\":\"*****\"\n }\n};\n\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 184,
        "y": 330,
        "wires": [
            [
                "b20d9f5b.8a2e"
            ]
        ]
    },
    {
        "id": "b20d9f5b.8a2e",
        "type": "http request",
        "z": "4ec6c862.fe52a8",
        "name": "トークンの取得",
        "method": "POST",
        "ret": "obj",
        "url": "https://try-api.recaius.jp/auth/v2/tokens",
        "x": 408,
        "y": 328,
        "wires": [
            [
                "37eda88.2238858"
            ]
        ]
    },
    {
        "id": "acdfe134.02fdc",
        "type": "http request",
        "z": "4ec6c862.fe52a8",
        "name": "合成音声ファイルの取得",
        "method": "POST",
        "ret": "bin",
        "url": "https://try-api.recaius.jp/tts/v2/plaintext2speechwave",
        "tls": "",
        "x": 528,
        "y": 524,
        "wires": [
            [
                "5ef4db0a.d6c134"
            ]
        ]
    },
    {
        "id": "5ef4db0a.d6c134",
        "type": "http response",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "x": 718,
        "y": 524,
        "wires": []
    },
    {
        "id": "dd8f6810.2a9c88",
        "type": "http in",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "url": "/forecast.wav",
        "method": "get",
        "swaggerDoc": "",
        "x": 114,
        "y": 101,
        "wires": [
            [
                "db1b4b6.78afdb8"
            ]
        ]
    },
    {
        "id": "2364ef3a.e615",
        "type": "debug",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "active": true,
        "console": "false",
        "complete": "headers",
        "x": 698,
        "y": 405,
        "wires": []
    },
    {
        "id": "37eda88.2238858",
        "type": "function",
        "z": "4ec6c862.fe52a8",
        "name": "合成音声のパラメーター設定",
        "func": "var token = msg.payload.token;\n\nmsg.headers =\n{\n \"Content-Type\": \"application/json\",\n \"X-Token\": token\n};\n\nmsg.payload =\n{\n \"plain_text\" : msg.forecast,\n \"lang\" : \"ja_JP\",\n \"speaker_id\" : \"ja_JP-F0006-C53T\"\n};\n\n// ja_JP-F0005-U01T, ja_JP-F0006-C53T\n\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 428,
        "y": 405,
        "wires": [
            [
                "acdfe134.02fdc",
                "2364ef3a.e615"
            ]
        ]
    },
    {
        "id": "db1b4b6.78afdb8",
        "type": "http request",
        "z": "4ec6c862.fe52a8",
        "name": "天気予報取得",
        "method": "GET",
        "ret": "obj",
        "url": "http://weather.livedoor.com/forecast/webservice/json/v1?city=130010",
        "tls": "",
        "x": 178,
        "y": 176,
        "wires": [
            [
                "c686bc27.edadd"
            ]
        ]
    },
    {
        "id": "c686bc27.edadd",
        "type": "function",
        "z": "4ec6c862.fe52a8",
        "name": "天気概要の抜き出し",
        "func": "// var str = msg.payload.description.text;\n\n// var str = msg.payload.title + \"。\";\nvar str = \"\";\nfor (var i=0; i<2; i++) {\n    var f = msg.payload.forecasts[i];\n    str = str + f.dateLabel + \"は\" + f.telop + \"です。\";\n}\n\nmsg.forecast = str;\n\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "x": 388,
        "y": 177,
        "wires": [
            [
                "7c64a87f.c18ec8",
                "8f728e50.32a3a"
            ]
        ]
    },
    {
        "id": "c29900d3.88618",
        "type": "http in",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "url": "/time",
        "method": "get",
        "swaggerDoc": "",
        "x": 103,
        "y": 569,
        "wires": [
            [
                "5161ff4d.bd11a"
            ]
        ]
    },
    {
        "id": "5161ff4d.bd11a",
        "type": "function",
        "z": "4ec6c862.fe52a8",
        "name": "日時の取得",
        "func": "var dt = new Date();\n\nvar year = dt.getFullYear();\nvar month = dt.getMonth()+1;\nvar date = dt.getDate();\nvar hours = dt.getHours();\nvar minutes = dt.getMinutes();\nvar seconds = dt.getSeconds();\n\nmsg.payload = year + \",\" + month + \",\" + date + \",\" + hours + \",\" + minutes + \",\" + seconds;\n\nreturn msg;\n",
        "outputs": 1,
        "noerr": 0,
        "x": 257,
        "y": 634,
        "wires": [
            [
                "fa6805dc.f43ef8"
            ]
        ]
    },
    {
        "id": "fa6805dc.f43ef8",
        "type": "http response",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "x": 424,
        "y": 634,
        "wires": []
    },
    {
        "id": "7c64a87f.c18ec8",
        "type": "debug",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "active": true,
        "console": "false",
        "complete": "forecast",
        "x": 635,
        "y": 155,
        "wires": []
    },
    {
        "id": "c72aa321.36302",
        "type": "inject",
        "z": "4ec6c862.fe52a8",
        "name": "",
        "topic": "",
        "payload": "",
        "payloadType": "date",
        "repeat": "",
        "crontab": "",
        "once": false,
        "x": 77,
        "y": 233,
        "wires": [
            [
                "db1b4b6.78afdb8"
            ]
        ]
    }
]
```

## GR-CITRUSの実装

T.B.D.
