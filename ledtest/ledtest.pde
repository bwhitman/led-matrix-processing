import processing.net.*;

int BALLS  = 10; // how many balls to draw
int FPS = 30; // frames per second to try to achieve, can be up to 60 
int panel_w = 192; // panel width
int panel_h = 192; // panel height

Client client; // network client for the ledmatrix
String ledmatrix_ip = "led.local"; // ip address of display, can be "x.local" or "192.168.x.x" 
byte[] frame= new byte[panel_w*panel_h*3]; // storage for frame to send to panel

int start = 0;
int frames = 0;

// ball state
int[] draw_x = new int[BALLS]; 
int[] draw_y = new int[BALLS];
int[] dim = new int[BALLS];
int[] x_speed = new int[BALLS];
int[] y_speed = new int[BALLS];
float[] hue = new float[BALLS];

void setup() {
  size(192, 192);
  background(0);
  colorMode(HSB, 360, 100, 100);
  noStroke();
  ellipseMode(RADIUS);
  frameRate(FPS);
  client = new Client(this, ledmatrix_ip, 2117);
  for(int k=0;k<BALLS;k++) {
    draw_x[k] = int(random(panel_w));
    draw_y[k] = int(random(panel_h));
    dim[k] = int(random(100));
    x_speed[k] = int(random(20))-10 + 1;
    y_speed[k] = int(random(20))-10 + 1;
    hue[k] = random(0, 360);
  }
  start = millis();
}

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

void draw() {
  background(0);
  for(int k=0;k<BALLS;k++) {
    
    // Draw the ball
    fill(hue[k], 90, 90);
    ellipse(draw_x[k], draw_y[k], dim[k]/2, dim[k]/2);
    
    // Animate the ball for the next frame
    draw_x[k]=draw_x[k]+x_speed[k];
    draw_y[k]=draw_y[k]+y_speed[k];
    if(draw_x[k]>width) {
      x_speed[k] = -1 * x_speed[k];
      draw_x[k] = width;
    }
    if(draw_x[k]<0) {
      x_speed[k] = -1 * x_speed[k];
      draw_x[k] = 0;
    }
    if(draw_y[k]>height) {
      y_speed[k] = -1 * y_speed[k];
      draw_y[k] = height;
    }
    if(draw_y[k]<0) {
      y_speed[k] = -1 * y_speed[k];
      draw_y[k] = 0;
    }
  }
  
  // Write to the LED
  displayOnMatrix();
  
  // Compute actual FPS and print to the console 
  int tic = millis() - start;
  if(++frames % 100 == 0) println("Actual FPS to the display: "+frames / (tic/1000.0));
}
