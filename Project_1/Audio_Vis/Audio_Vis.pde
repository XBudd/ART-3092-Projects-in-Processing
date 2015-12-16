/* --------------------------------------------------------------------------
 * Based on Tutorial and samples from www.benfrarahmand.com 
 * --------------------------------------------------------------------------
 * prog: Colin Budd - www.xbudd.com
 * date:  9/8/2015 
 * school: Cornell University
 * ----------------------------------------------------------------------------
 */


import ddf.minim.analysis.*;
import ddf.minim.*;
Minim minim;
AudioPlayer jingle;
FFT fft; // Fast Fourier Transform - analyze audio
AudioInput in;
float[] angle;
float[] y, x;

void setup() {
  size(displayWidth, displayHeight, P3D);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 2048, 192000.0);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  x = new float[fft.specSize()];
  y = new float[fft.specSize()];
  angle = new float[fft.specSize()];
  frameRate(240);
}

void draw() {
  background(0);
  fft.forward(in.mix);
  musicVis(); // run my function
}

void musicVis() {
  noStroke();
  pushMatrix(); // processing.org/reference/pushMatrix_.html
  // RED BOXES
  translate(width/2, height/2);
  for (int i = 0; i < fft.specSize(); i++) {
    y[i] = y[i] + fft.getBand(i)/100;
    x[i] = x[i] + fft.getFreq(i)/100;
    angle[i] = angle[i] +fft.getFreq(i)/2000; //speed of viz
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    fill(fft.getFreq(i)*2, 0, fft.getBand(i)*2); 
    pushMatrix();
    translate((x[i]+50)%width/3, (y[i]+50)%height/3);
    box(fft.getBand(i)/20+fft.getFreq(i)/15);
    popMatrix();
  }
  
  popMatrix();
  pushMatrix();
  // BLUE BOXES
  translate(width/2, height/2, 100);
  for (int i = 0; i < fft.specSize() ; i++) {
    y[i] = y[i] + fft.getBand(i)/10;
    x[i] = x[i] + fft.getFreq(i)/1000;
    angle[i] = angle[i] + fft.getFreq(i)/100000;
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    fill(0, 255-fft.getFreq(i)*20, 255-fft.getBand(i)*2);
    pushMatrix();
    translate((x[i]+250)%width, (y[i]+250)%height);
    box(fft.getBand(i)/20+fft.getFreq(i)/15);
    popMatrix();
  }
  
  popMatrix();
  pushMatrix();
  // TEAL BLOCKS
  translate(width/4, height/2, 100);
  for (int i = 0; i < fft.specSize(); i++) {
    x[i] = x[i] + fft.getFreq(i); // how it progresses  on x axis
    y[i] = y[i] + fft.getBand(i);
    fill(0, 255-fft.getFreq(i)*10, 255-fft.getBand(i)*2);
    pushMatrix();
    translate((x[i]-900)%width, (y[i]-300)%height); //how they will progress on screen
    box(fft.getBand(i)+fft.getFreq(i));
    popMatrix();
  }
  popMatrix();
}
 
void stop()
{
  // always close Minim audio classes when you finish with them
  jingle.close();
  minim.stop();
 
  super.stop();
}
    