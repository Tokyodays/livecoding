import oscP5.*;
import netP5.*;

OscP5 osc;

void setup() {
  osc = new OscP5(this, 1818);
}

void draw() {
  background(0);
}

void oscEvent(OscMessage m) {
  dumpTidalMsg(m);
}

void dumpTidalMsg(OscMessage m) {
  for (int i = 0; i < m.typetag().length(); i++) {
    String type = m.typetag().substring(i, i+1);
    switch(type) {
    case "s":
      print(m.get(i).stringValue());
      break;
    case "f":
      print(m.get(i).floatValue());
      break;
    case "i":
      print(m.get(i).intValue());
      break;
    }
    print(" ");
  }
  println();
}
