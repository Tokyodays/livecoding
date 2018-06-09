import oscP5.*;
import netP5.*;
float gain = 0.0;
OscP5 osc;

void setup() {
  size(800, 800);
  frameRate(60);
  osc = new OscP5(this, 1818);
}

void draw() {
  background(0);
  fill(31, 127, 255);
  float diameter = map(gain, 0, 2, 0, width);
  ellipse(width/2, height/2, diameter, diameter);
}

void oscEvent(OscMessage m) {
  for (int i = 0; i < m.typetag().length(); i+=2) {
    String name;
    name = m.get(i).stringValue();
    switch(name) {
    case "gain":
      gain = m.get(i+1).floatValue();
      break;
    }
  }
}
