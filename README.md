# led-matrix-processing

I gave a friend a square LED matrix for him to draw his animations on in Processing for his birthday. Here's the writeup on how I did that:

Setup:

 * [Raspberry Pi 4](https://www.amazon.com/Raspberry-Model-2019-Quad-Bluetooth/dp/B07TC2BK1X) with 32GB microSD card running 64 bit Pi OS lite
 * LED matrix, 8 of them, setup in a "V-Mapper:Z" formation (ours is 192x192, made up of 8 96x48 panels). I got the panels from [Waveshare](https://www.waveshare.com/rgb-matrix-p2.5-96x48-f.htm) but you can find them cheaper on [AliExpress](https://www.aliexpress.com/item/1005004448605301.html) (with longer shipping) 
 * A "hat" for the Pi with parallel connections for the panel, we use [HAT-A3](https://www.acmesystems.it/HAT-A3). 
 * [A power supply enough for the panels & Pi, 40A](https://www.amazon.com/dp/B01D8FLYW6)
 * [rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix) installed on the Pi
 * [Processing](https://processing.org), running on a separate computer on the same network, with slight modifications to draw the frames to the LED matrix.


## Physical panel setup

We set up the HAT-A3 to use [Pin 8 for E, by joining the pads](https://github.com/hzeller/rpi-rgb-led-matrix?tab=readme-ov-file#64x64-with-e-line-on-adafruit-hatbonnet)

Our panels are wired like

```
I  3  X     I  7  X
^           ^ 
O  2  I     O  6  I
      ^           ^
I  1  O     I  5  O
^           ^    
O  0  I     O  4  I 
      ^           ^
 Pi TOP    Pi MIDDLE
```

This is "V-Mapper:Z", where every other panel is inverted, to have shorter cables. [See more on mappers](https://github.com/hzeller/rpi-rgb-led-matrix/tree/master/examples-api-use#remapping-coordinates)

We also route power from a 40A power supply to the panels using the Y cables.

We route power from the 40A power supply to the Pi via the 5V input on the "HAT-A3". You don't need to connect ground as the panels supply it through the 16-pin connectors. 

### More panels

If you wanted to add more (for example, 10 more panels to make it a square 288x288) you can use the third parallel connector, and set `--led-parallel=3` and `--led-chain==6`. 

```
I  5  X     I 11  O     I 17  X
^           ^           ^
O  4  I     O 10  I     O 16  I
      ^           ^           ^  
I  3  O     I  9  O     I 15  O
^           ^           ^
O  2  I     O  8  I     O 14  I
      ^           ^           ^
I  1  O     I  7  O     I 13  O
^           ^           ^
O  0  I     O  6  I     O 12  I 
      ^           ^           ^
 Pi TOP    Pi MIDDLE   Pi BOTTOM
```


## Pi network RGB panel setup

On boot, the Pi runs this bash script (called in `/etc/rc.local`), with code in `/home/led/run.sh`. This sets up the parameters of the panel. Edit this to change them if you want to play with the various tunings of the panel. See [the rpi-rgb-led-matrix docs](https://github.com/hzeller/rpi-rgb-led-matrix) for the explanations.


```bash
#!/bin/bash
# This runs the "server" that listens to TCP packets on port 2117 and shows them on the screen
# You can edit the settings here for the panel if you'd like. 
while true;
do
    nc  -l 2117 | sudo /home/led/rpi-rgb-led-matrix/examples-api-use/ledcat \
        --led-cols=96 --led-rows=48 --led-chain=4 --led-parallel=2 \
        --led-pixel-mapper='Rotate:180;V-mapper:Z;Mirror:V;Mirror:H' \
        --led-pwm-lsb-nanoseconds 130 --led-pwm-bits=11  --led-slowdown-gpio=4 --led-brightness=100
    sleep 1
done

```

The program it runs is `ledcat`, which reads LED data in from STDIN. We use a pipe to instead give it the output of `nc` / netcat, listening on TCP port 2117. The bash script will restart the listener when data stops coming in, so that you can stop and start your Processing scripts without having to restart the Pi. 


## Run your Processing scripts on the LED Matrix from your computer

There's an example animation called [`ledtest` that you can download here.](https://github.com/bwhitman/led-matrix-processing/blob/main/ledtest/ledtest.pde) If you download that and run it on the same Wi-Fi as the Pi, you should see the animation both on your computer screen and on the matrix. For your own Processing animations, all you have to do in Processsing is set the screen size to 192,192 and add these lines to `setup()`:

```c
Client client; // network client for the ledmatrix
String ledmatrix_ip = "led.local"; // ip address of display, can be "x.local" or "192.168.x.x" 
byte[] frame= new byte[panel_w*panel_h*3]; // storage for frame to send to panel

void setup() {
    client = new Client(this, ledmatrix_ip, 2117);
    ...
```

And then call this function at the end of `draw()`:

```c

// Display the current frame on the LED matrix
// Call this in your draw() when done drawing.
void displayOnMatrix() {
  int k = 0;
  loadPixels();
  for(int i=0;i<height;i++) {
    for(int j=0;j<width;j++) {
      color c=  pixels[i*width+j];
      frame[k++] = byte((c >> 16) & 0xFF);  
      frame[k++]= byte((c >> 8) & 0xFF);
      frame[k++] = byte(c & 0xFF);
    }
  }
  updatePixels();
  client.write(frame);
}
```

This will emit the current frame to the Pi, which will show it on the LED matrix. You can run this from your computer on the same Wi-Fi. I can easily get up to 60FPS on a 192x192 panel.

## Login details for the Pi

The Pi is set with the IP `led.local`, which should work from your network to find it.

On my network, i find that sometimes resolving `led.local` slows down, so I often just use the IP address directly. You can find it by

```
% ping led.local
PING led.local (192.168.50.59): 56 data bytes
```

From your computer Terminal.

To log in, use:
```
# ssh led@led.local
```

The default username is `led` and the password is `ledmatrix`.

You can also log into graphically using a [VNC client](https://www.realvnc.com/en/connect/download/viewer/macos/), just connect to `led.local` with `led` / `ledmatrix` as the login. You'll be able to see the user interface. 

## Run Processing directly on the Pi

If you want even more performance, or want to run animations without needing a computer running, the Pi can run Processing natively. Processing is installed on the Pi. You can connect an HDMI monitor and keyboard (or use a VNC connection) and run your scripts locally on the Pi. It will be faster as it won't have to use the network to transmit data. (You would want to change `ledmatrix_ip` to `localhost`.)

## Other examples, direct control 

The `rpi-rgb-led-matrix` has a bunch of examples to try with lower-level bindings for C and Python, if you're interested in further experimentation. Just make sure `run.sh` is not running by editing /etc/rc.local and putting a `#` in front of the `/home/led/run.sh` command (so it looks like `#/home/led/run.sh` and doesn't run it at boot. Unplug/replug the matrix, log in again and then `cd rpi-rgb-led-matrix/examples-api-use`. [You can see the docs for the examples here.](https://github.com/hzeller/rpi-rgb-led-matrix/tree/master/examples-api-use)








