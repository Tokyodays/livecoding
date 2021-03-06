import oscP5.*;
import netP5.*;
float gain = 0.0;
int n = 0;
float pan = 0.5; 
OscP5 osc;

void setup() {
  size(800, 800);
  frameRate(60);
  osc = new OscP5(this, 1818);
  colorMode(HSB, 360, 100, 100, 100);
}

void draw() {
  background(0);
  float diameter = map(gain, 0, 2, 0, width);
  float hue = map(n, 0, 10, 0, 360);
  float posX = map(pan, 0, 1, width/4, width/4 * 3);
  fill(hue, 80, 100);
  ellipse(posX, height/2, diameter, diameter);
}

void oscEvent(OscMessage m) {
  for (int i = 0; i < m.typetag().length(); i+=2) {
    String name;
    name = m.get(i).stringValue();
    switch(name) {
    case "gain":
      gain = m.get(i+1).floatValue();
      break;
    case "n":
      n = m.get(i+1).intValue();
      break;
    case "pan":
      pan = m.get(i+1).floatValue();
      break;
    }
  }
}
