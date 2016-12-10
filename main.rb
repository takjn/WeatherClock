#!mruby
# GR-CITRUS with WA-MIKAN
# 利用できるピンは、1, 3, 4, 6, 9, 10, 14, 15, 16, 17, 18番ピン

# ピンの設定
PIN_BREAK = 14      # Breakボタン用ピン
PIN_BTN_DATE = 4    # 日付表示ボタン用ピン(MP3停止と兼用)
PIN_BTN_WEATHER = 6 # 天気予報ボタン用ピン
PIN_BTN_MUSIC = 9   # 音楽再生ボタン用ピン

# TM4D595のピンの設定
PIN_TM4D595_DIO = 17
PIN_TM4D595_RCLK = 16
PIN_TM4D595_SCLK = 15

# SDカードに保存されたhttp通信結果からBodyだけを取り出して新しいファイルを作る
def remove_headers(src, dst)
    SD.remove(dst) if SD.exists(dst)

    SD.open(0, src, 0)
    SD.open(1, dst, 2)

    # ヘッダ部分部分を読み飛ばす
    loop do
        c = SD.read(0)
        break if c < 0
        if c == 0x0d
            c = SD.read(0)
            if c > 0 and c == 0x0a
                c = SD.read(0)
                if c > 0 and c == 0x0d
                    c = SD.read(0)
                    if c > 0 and c == 0x0a
                        break
                    end
                end
            end
        end
    end

    # 新しいファイルに書き出す
    buf = []
    a = 1
    loop do
        c = SD.read(0)
        break if c < 0
        buf << c.chr
        if buf.length > 300
            led a
            a = 1 - a
            SD.write(1, buf.join, buf.length)
            buf = []
            delay 1
        end
    end

    SD.write(1, buf.join, buf.length) if buf.length > 0
    buf = nil

    SD.flush(1)
    SD.close(1)
    SD.close(0)
end

# 4桁7セグLEDモジュール [TM4D595] - aitendo
class TM4D595

    LED_BCD = [0xc0,0xf9,0xa4,0xb0,0x99,0x92,0x82,0xf8,0x80,0x90,0x88,0x83,0xc6,0xa1,0x86,0x8e]

    def initialize(dio, rclk, sclk)
        @dio  = dio
        @rclk = rclk
        @sclk = sclk

        pinMode(dio,  0x1)    # set pin to output
        pinMode(rclk, 0x1)    # set pin to output
        pinMode(sclk, 0x1)    # set pin to output

    end

    def write_74HC595(dio_a)
        digitalWrite(@rclk, 0)
        digitalWrite(@sclk, 0)

        (0..15).each do |look|

            if dio_a & 0x0001 == 1
                digitalWrite(@dio, 0x1)
            else
                digitalWrite(@dio, 0x0)
            end

            digitalWrite(@sclk, 1)
            digitalWrite(@sclk, 0)

            dio_a >>= 1

        end

        digitalWrite(@rclk, 1)

    end

    def hc_dio_analyze(led_number, led_display)
	    hc_disp = 0
	    hc_ledcode = 0
	    hc_ledcode_temp = 0

	    led_display = 0 if led_display > 15

    	hc_ledcode = LED_BCD[led_display]

    	8.times do
    	    hc_ledcode_temp <<= 1
    	    hc_ledcode_temp |= 0x01 if hc_ledcode & 0x01 != 0
    	    hc_ledcode >>= 1
    	end

    	hc_ledcode_temp &= 0xfe if led_number == 3
    	hc_disp = hc_ledcode_temp

    	hc_disp =   case led_number
                  when 0
                      hc_disp | 0x8000
                  when 1
                      hc_disp | 0x4000
                  when 2
                      hc_disp | 0x2000
                  when 3
                      hc_disp | 0x1000
                  end

    	write_74HC595(hc_disp);
    end

end

# デバッグ用
class Debug
    @@serial = nil

    def self.init
        @@serial = Serial.new(0, 115200)
    end

    def self.println(message)
        @@serial.println(message) unless @@serial.nil?
    end

    def self.write(val, bytes)
        @@serial.write(val, bytes) unless @@serial.nil?
    end
end
Debug.init

# ボタン用ピンの初期化
pinMode(PIN_BREAK, 0x2)         # set pin to input_pullup
pinMode(PIN_BTN_WEATHER, 0x2)   # set pin to input_pullup
pinMode(PIN_BTN_MUSIC, 0x2)     # set pin to input_pullup

# RTCの初期化
System.exit if Rtc.init == 0
Rtc.setTime([2016, 12, 5, 22, 59, 55])

# TM4D595の初期化
display = TM4D595.new(PIN_TM4D595_DIO, PIN_TM4D595_RCLK, PIN_TM4D595_SCLK)

# MP3の初期化
if System.useMP3(3,4) == 0
  Debug.println "MP3 can't use."
  System.exit
end

# SDカードの初期化
if System.useSD() == 0
  Debug.println "SD Card can't use."
  System.exit
end

#ESP8266を一度停止させる(リセットと同じ)
pinMode(5,1)
digitalWrite(5,0) # LOW:Disable
delay 500
digitalWrite(5,1) # LOW:Disable

if System.useWiFi() == 0 then
  Debug.println "WiFi Card can't use."
  System.exit()
end
# Debug.println WiFi.version
# Debug.println WiFi.disconnect
Debug.println WiFi.setMode 3 #Station-Mode & SoftAPI-Mode
Debug.println WiFi.connect('AirPort15422', '7398899665975')
Debug.println WiFi.ipconfig
Debug.println WiFi.multiConnect 1

if WiFi.httpGetSD('time.txt','192.168.0.10:1880/time').to_s == 0
  Debug.println "Can't connect to server"
  System.exit()
end

SD.open(0, 'time.txt', 0)
buf = []
loop do
  c = SD.read(0)
  break if c < 0
  buf << c.chr
end
SD.close(0)
date = buf.join.split("\r\n").last.chomp.split(",") # 最後の1行を取得し","で分割
(0..5).each do |i|
  date[i] = date[i].to_i
  Debug.println(date[i].to_s)
end
Rtc.setTime([date[0], date[1], date[2], date[3], date[4], date[5]])

buf = []
date = []
delay 1 # GC

# メインループ
loop do
    break if digitalRead(PIN_BREAK) == 0 # デバッグ用(14ピンをGNDに落とすとbreak)

    # 天気予報ボタンが押されたら、天気予報の再生を開始
    if digitalRead(PIN_BTN_WEATHER) == 0
      Debug.println "Download Start"
      if WiFi.httpGetSD('forecast.tmp','192.168.0.10:1880/forecast.wav').to_s == 0
        Debug.println "Can't connect to server"
        System.exit()
      end

      Debug.println "Remove Headers"
      remove_headers('forecast.tmp', 'forecast.wav')
      delay 1 # GC

      Debug.println "Wav Play"
      MP3.play "forecast.wav"
    end

    # 音楽再生ボタンが押されたら、music.wavの再生を開始
    if digitalRead(PIN_BTN_MUSIC) == 0
      Debug.println "Wav Play"
      MP3.play "music.wav"
    end

    # 時刻の表示
    year, month, day, hour, minute, second, weekday = Rtc.getTime

    if digitalRead(PIN_BTN_DATE) == 0
      h1, h0 = month.divmod(10)
      m1, m0 = day.divmod(10)
    else
      h1, h0 = hour.divmod(10)
      m1, m0 = minute.divmod(10)
    end

    display.hc_dio_analyze(3, h1)
    display.hc_dio_analyze(2, h0)
    display.hc_dio_analyze(1, m1)
    display.hc_dio_analyze(0, m0)
    delay 1

end

# ESP8266の接続解除
Debug.println WiFi.disconnect
