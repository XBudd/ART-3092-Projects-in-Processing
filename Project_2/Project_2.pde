/* --------------------------------------------------------------------------
 * Based on Daniel Shiffman's Kinect Point Cloud example
 * --------------------------------------------------------------------------
 * prog: Colin Budd - www.xbudd.com
 * date:  10/2/2015 
 * school: Cornell University
 * ----------------------------------------------------------------------------
 */


import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


import org.openkinect.freenect.*;
import org.openkinect.processing.*;

// Kinect Library object
Kinect kinect;
//Mimim Stuff
Minim minim;
AudioPlayer jingle;
FFT fft; 
AudioInput in;
float[] angle;
float[] mX, mY;

// Angle for rotation
float a = 0;


// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

void setup() {
  // Rendering in P3D
  size(displayWidth, displayHeight, P3D);
  kinect = new Kinect(this);
  kinect.initDepth();
  
  // minim
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 2048, 192000.0);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  mX = new float[fft.specSize()];
  mY = new float[fft.specSize()];
  angle = new float[fft.specSize()];

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
}

void draw() {

  background(0);
  fft.forward(in.mix);
  // Get the raw depth as array of integers
  int[] depth = kinect.getRawDepth();
  musicVis();
  // calculate and draw every Xth pixel (lower # to increase density)
  int skip = 8;

  // Translate and rotate
  translate(width/2, height/2, -50);
  scale(2,2);
  rotateY(a);

  for (int x = 0; x < kinect.width; x += skip) {
      mY[x] = mY[x] + fft.getBand(x)/100;
      mX[x] = mX[x] + fft.getFreq(x)/100;
      
    for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y*kinect.width;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      PVector v = depthToWorld(x, y, rawDepth);
     
     
           
      
        
      fill(255-fft.getFreq(mY[x])*20, 255-fft.getFreq(mY[y])*20, 255-fft.getBand(y)*2); //blue - white
      noStroke();
      pushMatrix();
      // Scale up by 200
      float factor = 200;//random(200, (200*(fft.getBand(x)/20+fft.getFreq(x)/20)));
      translate(v.x*factor, v.y*factor, factor-v.z*factor);
      // Draw a point
      ellipse(0,0, fft.getBand(x)/20+fft.getFreq(x)/20, fft.getBand(x)/20+fft.getFreq(x)/15);
      popMatrix();
    }
    a +=  (fft.getBand(x)/20+fft.getFreq(x)/20)/2;
  }

  // Rotate
  //a += -0.015f;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}
void musicVis(){
    noStroke();
  pushMatrix(); // processing.org/reference/pushMatrix_.html
  // RED BOXES
  translate(width/2, height/2);
  for (int i = 0; i < fft.specSize(); i++) {
    mY[i] = mY[i] + fft.getBand(i)/100;
    mX[i] = mX[i] + fft.getFreq(i)/100;
    angle[i] = angle[i] +fft.getFreq(i)/2000; //speed of viz
    rotateX(sin(angle[i]/2));
    rotateY(cos(angle[i]/2));
    fill(fft.getFreq(i)*2, 0, fft.getBand(i)*2); 
    pushMatrix();
    translate((mX[i]+50)%width/3, (mY[i]+50)%height/3);
    box(fft.getBand(i)/20+fft.getFreq(i)/15);
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