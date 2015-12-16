/* --------------------------------------------------------------------------
 * Baed on SimpleOpenNI User3d Test & SimpleOpenNI Hands3d Test by Max Rheiner
 * --------------------------------------------------------------------------
 * Royalty free music samples and loops from  http://www.looperman.com/
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog: Colin Budd - www.xbudd.com
 * date:  10/23/2015 
 * school: Cornell University
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;
import ddf.minim.spi.*;
import ddf.minim.signals.*;wai
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;
import geomerative.*;
import org.apache.batik.svggen.font.table.*;
import org.apache.batik.svggen.font.*;

SimpleOpenNI context;
float        zoomF =0.3f;
float        rotX = radians(180);  // by default rotate the whole scene 180deg around the x-axis, 
// the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;
float rate = 0.f;

PVector      bodyDepth = new PVector();
PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      com = new PVector();                                   
PVector      com2d = new PVector();                                   
color[]       userClr = new color[] { 
  color(255, 0, 0), 
  color(0, 255, 0), 
  color(0, 0, 255), 
  color(255, 255, 0), 
  color(255, 0, 255), 
  color(0, 255, 255)
};
//Geometry
RShape arc1;
RShape timeLine;
RPoint[][] pointPathsArc;
RPoint[][] pointPathsTimeLine;
boolean ignoringStyles = false;

Minim minim;
AudioOutput out;
AudioPlayer song;
AudioSample snare01;
AudioSample party02;
AudioSample beat02;
AudioSample party01;
AudioSample cymbol01;
AudioSample boost02;
AudioSample boost01;
AudioSample scratch01;
AudioSample audio; //no purpose yet
AudioRecordingStream myFile;
Play play;
Rewind rewind;
Forward ffwd;
TickRate rateControl;
FilePlayer filePlayer;
MoogFilter      moog;
SampleRepeat    repeater;

boolean delayed = false;
boolean crushed = false;
boolean filtering = false;


String fileName = "sounds/edm.mp3";

int closestValue;
int closestX;
int closestY;
int closestZ;
int closestXL;
int closestYL;
int closestZL;

int time;
int wait = 250;

void setup()
{
  size(1024, 768, P3D); 
  time = millis(); // store current time;
  //minim 
  minim = new Minim(this);
  out = minim.getLineOut();
  song = minim.loadFile("sounds/edm.mp3");
  // get an AudioRecordingStream from Minim, which is what FilePlayer will control

  myFile = minim.loadFileStream( fileName, // the file to load
  1024, // the size of the buffer. 1024 is a typical buffer size
  true      // whether to load it totally into memory or not
  // we say true because the file is short 
  );
  // this opens the file and puts it in the "play" state.                           
  filePlayer = new FilePlayer( myFile );

  // and then we'll tell the recording to loop indefinitely
  filePlayer.loop();
  // this creates a TickRate UGen with the default playback speed of 1.
  // ie, it will sound as if the file is patched directly to the output
  rateControl = new TickRate(1.f);

  // get a line out from Minim. It's important that the file is the same audio format 
  // as our output (i.e. same sample rate, number of channels, etc).
  out = minim.getLineOut();
  //Glitches
  repeater = new SampleRepeat( 120, 0.25f );
  moog = new MoogFilter( 12000, 0.3f );
  // patch the file player through the TickRate to the output.
  filePlayer.patch( rateControl ).patch( moog ).patch( repeater ).patch( out );                                            

  // load BD.mp3 from the data folder
  snare01 = minim.loadSample( "sounds/FX/snare01.mp3", // filename
  512      // buffer size
  );
  // if a file doesn't exist, loadSample will return null
  if ( snare01 == null ) println("Didn't get snare01!");

  // load party02 from the data folder
  party02 = minim.loadSample("sounds/FX/party02.mp3", 512);
  if ( party02 == null ) println("Didn't get party02!"); 

  // load beat02.mp3 from the data folder
  beat02 = minim.loadSample("sounds/FX/beat02.mp3", 512);
  if ( beat02 == null ) println("Didn't get beat!"); 

  // load  boost02.mp3 from the data folder
  boost02 = minim.loadSample("sounds/FX/boost02.mp3", 512);
  if ( boost02 == null ) println("Didn't get boost01!"); 

  // load  party01.mp3 from the data folder
  party01 = minim.loadSample("sounds/FX/party01.mp3", 512);
  if ( party01 == null ) println("Didn't get party!"); 

  // load  cymbol01.mp3 from the data folder
  cymbol01 = minim.loadSample("sounds/FX/cymbol01.mp3", 512);
  if ( cymbol01 == null ) println("Didn't get cymbol!"); 

  // load  boost01.mp3 from the data folder
  boost01 = minim.loadSample("sounds/FX/boost01.mp3", 512);
  if ( boost01 == null ) println("Didn't get boost!"); 

  // load  boost01.mp3 from the data folder
  scratch01 = minim.loadSample("sounds/FX/scratch01.mp3", 512);
  if ( boost01 == null ) println("Didn't get scratch!"); 


  //rock that kinect
  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  // disable mirror
  context.setMirror(true);

  // enable depthMap generation 
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  stroke(255, 255, 255);
  smooth();  
  perspective(radians(45), 
  float(width)/float(height), 
  10, 150000);

  //load shape geometry for shapes
  RG.init(this);
  ignoringStyles = !ignoringStyles; //show color
  RG.ignoreStyles(ignoringStyles);
  RG.setPolygonizer(RG.ADAPTATIVE);
  //Note: have to have the layers JUST be paths, cant be any further info
  arc1 = RG.loadShape("curve2.svg");
  arc1.centerIn(g, 1, 1, 1);
  pointPathsArc = arc1.getPointsInPaths();

  timeLine = RG.loadShape("timeline.svg");
  timeLine.centerIn(g, -60, 1, 1);
  pointPathsTimeLine = timeLine.getPointsInPaths();
}

void draw()
{
  // update the cam
  context.update();

  background(0, 0, 0);
  // set closestVal
  closestValue = 8000;

  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);

  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps   = 3;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;

  translate(0, 0, -1000);  // set the rotation center of the scene 1000 infront of the camera

  // draw the pointcloud
  beginShape(POINTS);

  for (int y=0; y < context.depthHeight (); y+=steps)
  {
    for (int x=0; x < context.depthWidth (); x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      { 
        // draw the projected point
        //realWorldPoint = context.depthMapRealWorld()[index]; //unhide and move thing below out of else statement to show all dots
        if (userMap[index] == 0) {
          stroke(100);
        } else {
          realWorldPoint = context.depthMapRealWorld()[index]; // Draws the dots on screen!
          stroke(userClr[ (userMap[index] - 1) % userClr.length ]);        

          point(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z); //move outside of else if want to display all dots
        }
      }
    }
  } 
  endShape(); 

  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for (int i=0; i<userList.length; i++)
  {
    if (context.isTrackingSkeleton(userList[i])) {

      playBall(userList[i]);
      drawSkeleton(userList[i]);
    }

    // draw the center of mass
    if (context.getCoM(userList[i], com))
    {
      stroke(100, 255, 0);
      strokeWeight(1);
      beginShape(LINES);
      vertex(com.x - 15, com.y, com.z);
      vertex(com.x + 15, com.y, com.z);

      vertex(com.x, com.y - 15, com.z);
      vertex(com.x, com.y + 15, com.z);

      vertex(com.x, com.y, com.z - 15);
      vertex(com.x, com.y, com.z + 15);
      endShape();

      fill(0, 255, 100);
      text(Integer.toString(userList[i]), com.x, com.y, com.z);
    }
  }    

  // draw the kinect cam
  // context.drawCamFrustum();


  // make those music bars
  rectMode(CENTER);
  noStroke(); 
  fill(255, 0, 0, 70 );
  rect(-280, 0, 40, 40);
  fill(255, 128, 0, 70);
  rect(-200, 0, 40, 40);
  fill(255, 255, 0, 70);
  rect(-120, 0, 40, 40);
  fill(0, 255, 0,70);
  rect(-40, 0, 40, 40);
  fill(0, 255, 255, 70);
  rect(40, 0, 40, 40);
  fill(0, 0, 255, 70);
  rect(120, 0, 40, 40);
  fill(128, 0, 255, 70);
  rect(200, 0, 40, 40);
  fill(255, 0, 255, 70);
  rect(280, 0, 40, 40);

  //draw music time line
  noStroke();
  fill(60, 170, 250, 70);
  timeLine.draw();
  timeLine();
  //draw arc
  fill(255, 0, 0, 50);
  arc1.draw();
}


void timeLine() {

  //float t = map(audio.position(), 0, song.length(), 0, 0.2);
  timeLine.rotate(-0.2); //-t/PI
  //println(t);
}

void playBall(int userId) {
  pushMatrix();
  ellipseMode(CENTER);
  noFill();
  stroke(userClr[ (userId-1) % userClr.length ]);
  ellipse(closestX, closestY, 75, 75);
  popMatrix();
  ellipse(closestXL, closestYL, 20, 20);
  PVector      jointPosR = new PVector();
  PVector      jointPosL = new PVector();
  float rightHand = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, jointPosR);
  float leftHand = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, jointPosL);
  float distanceScalar = (1024/jointPosR.z); //this is the key to scaling for distance accuracy of hand on Z axis
  float distanceScalarL = (1024/jointPosL.z); //this is the key to scaling for distance accuracy of hand on Z axis
  //println("jointPosR.x of " + userId + " is: " + jointPosR.x);

  closestX = (int)(jointPosR.x*distanceScalar);
  closestY = (int)(jointPosR.y*distanceScalar);
  closestZ = (int)jointPosR.z;

  closestXL = (int)(jointPosL.x*distanceScalarL);
  closestYL = (int)(jointPosL.y*distanceScalarL);
  closestZL = (int)jointPosL.z;

  //make shape hoverable/clickable
  RPoint p = new RPoint(closestX, closestY);
  RPoint pL = new RPoint(closestXL, closestYL);

  float rate = map(closestY, -800, 800, 0.0f, 3.f);
  float rateL = map(closestYL, -800, 800, 0.0f, 3.f);


  for (int i=0; i<arc1.countChildren (); i++) {

    if (arc1.children[i].contains(p)) {
      RG.ignoreStyles(true);
      fill(0, 100, 255, 250);
      noStroke();

      if (arc1.getChild("RMid").contains(p)) {
        rateControl.value.setLastValue(rate);
        rateControl.setInterpolation( true );
        println("RMid");
        //timeLine.rotate(rate);
      } 
      if (arc1.getChild("LMid").contains(p)) {
        println("LMid");
      }
      if (arc1.getChild("LTop").contains(p)) {
        println("LTop with R hand");
      }
      if (arc1.getChild("LBottom").contains(p)) {
        println("LBottom");
      }
      filtering = false;
      arc1.children[i].draw();
      RG.ignoreStyles(ignoringStyles);
    }

    //Left Hand
    if (arc1.children[i].contains(pL)) {
      RG.ignoreStyles(true);
      fill(0, 100, 255, 250);
      noStroke();

      if (arc1.getChild("RMid").contains(pL)) {

        println("RMid with L hand");
        //timeLine.rotate(rate);
      } 
      if (arc1.getChild("LMid").contains(pL)) {
        println("LMid");
        musicFX();
      }
      if (arc1.getChild("LTop").contains(pL)) {
        println("LTop with L hand");
      }
      if (arc1.getChild("LBottom").contains(pL)) { //Actually L TOP!!! (circle is flipped)
        println("LBottom");
        if (!arc1.getChild("LBottom").contains(p)) {
          fill(0, 255, 0, 100);
          float freq = constrain( map( closestX, -600, 600, 200, 12000 ), 200, 12000 );
          float rez  = constrain( map( closestY, 600, -600, 0, 1 ), 0, 1 );
          moog.type = MoogFilter.Type.HP;
          moog.frequency.setLastValue( freq );
          moog.resonance.setLastValue( rez  );
        } else {
          fill(0, 100, 255, 250);
          moog.frequency.setLastValue(0);
          moog.resonance.setLastValue(0);
        }
      }

      filtering = false;

      arc1.children[i].draw();
      RG.ignoreStyles(ignoringStyles);
    }
  }
  if (timeLine.contains(p) || timeLine.contains(pL)) {

    fill(255, 0, 0, 100);
    noStroke();
    timeLine.draw();

    int entryY = closestY;
    //println(entryY);
    int deltaPos = 0;
    if (closestY < entryY) {
      deltaPos = closestY - (entryY - closestY);
      println("closestY < entryY");
    }
    if (closestY > entryY) { //NOT working yet
      deltaPos = closestY + (entryY - closestY);
      println("closestY > entryY");
    }
    if (millis() - time >= wait/1) {
      scratch01.trigger();
      float posTL = map(deltaPos, 0, 800, 0, filePlayer.length());
      filePlayer.cue((int)posTL);
      time = millis(); //update stored time
    }
  }
}
void musicFX() {
  //make music
  noStroke();
  //REPEATER
  if (closestX < -240 && closestX > -280 && closestY < 20 && closestY > -20) {
    //out.playNote ("C4");

    if (millis() - time >= wait/1) {
      scratch01.trigger();
      filePlayer.skip(-500);
      time = millis(); //update stored time
    }
    fill(255, 0, 0, 100 );
    rect(-280, 0, 40, 40);
  }

  if (closestX < -160 && closestX > -200 && closestY < 20 && closestY > -20) {
    //out.playNote ("D4");
    if (millis() - time >= wait/1.2) {
      boost01.trigger();
      time = millis(); //update stored time
    }
    fill(255, 128, 0, 100);
    rect(-200, 0, 40, 40);
  }

  if (closestX < -80 && closestX > -120 && closestY < 20 && closestY > -20) {
    if (millis() - time >= wait) {
      cymbol01.trigger();
      time = millis(); //update stored time
    }
    fill(255, 255, 0, 100);
    rect(-120, 0, 40, 40);
  }

  if (closestX < 0 && closestX > -40 && closestY < 20 && closestY > -20) {
    if (millis() - time >= wait/1.2) {
      party01.trigger();
      time = millis(); //update stored time
    }
    fill(0, 255, 0, 100);
    rect(-40, 0, 40, 40);
  }

  if (closestX < 80 && closestX > 40 && closestY < 20 && closestY > -20) {
    if (millis() - time >= wait) {
      boost02.trigger();
      time = millis(); //update stored time
    }
    fill(0, 255, 255, 100);
    rect(40, 0, 40, 40);
  }

  if (closestX < 160 && closestX > 120 && closestY < 20 && closestY > -20) {
    if (millis() - time >= wait/1.4) {
      beat02.trigger();
      time = millis(); //update stored time
    }
    fill(0, 0, 255, 100);
    rect(120, 0, 40, 40);
  }

  if (closestX < 240 && closestX > 200 && closestY < 20 && closestY > -20) {
    //out.playNote ("B4");
    //delay next play
    if (millis() - time >= wait) {
      snare01.trigger();
      time = millis(); //update stored time
    }

    fill(128, 0, 255, 100);
    rect(200, 0, 40, 40);
  }
  //Snare
  if (closestX < 320 && closestX > 280 && closestY < 20 && closestY > -20) {
    //out.playNote ("C5");]
    //delay next play
    if (millis() - time >= wait) {
      party02.trigger();
      time = millis(); //update stored time
    }
    fill(255, 0, 255, 100);
    rect(280, 0, 40, 40);
  }
}


// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(3);

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  

  // draw body direction
  getBodyDirection(userId, bodyCenter, bodyDir);

  bodyDir.mult(200);  // 200mm length
  bodyDir.add(bodyCenter);

  stroke(255, 200, 200);
  line(bodyCenter.x, bodyCenter.y, bodyCenter.z, 
  bodyDir.x, bodyDir.y, bodyDir.z);

  strokeWeight(1);
}
void drawLimb(int userId, int jointType1, int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, jointType1, jointPos1);
  confidence = context.getJointPositionSkeleton(userId, jointType2, jointPos2);

  stroke(255, 0, 0, confidence * 200 + 55);
  line(jointPos1.x, jointPos1.y, jointPos1.z, 
  jointPos2.x, jointPos2.y, jointPos2.z);

  drawJointOrientation(userId, jointType1, jointPos1, 50);
}

void drawJointOrientation(int userId, int jointType, PVector pos, float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId, jointType, orientation);
  if (confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;

  pushMatrix();
  translate(pos.x, pos.y, pos.z);

  // set the local coordsys
  applyMatrix(orientation);

  // coordsys lines are 100mm long
  // x - r
  stroke(255, 0, 0, confidence * 200 + 55);
  line(0, 0, 0, 
  length, 0, 0);
  // y - g
  stroke(0, 255, 0, confidence * 200 + 55);
  line(0, 0, 0, 
  0, length, 0);
  // z - b    
  stroke(0, 0, 255, confidence * 200 + 55);
  line(0, 0, 0, 
  0, 0, length);
  popMatrix();
}
// -----------------------------------------------------------------
// Music Class
void makeMusic() {
}



// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  context.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
  song.pause();
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}


// -----------------------------------------------------------------
// Keyboard events
/*
void keyPressed()
 {
 switch(key)
 {
 case ' ':
 context.setMirror(!context.mirror());
 break;
 }
 
 switch(keyCode)
 {
 case LEFT:
 rotY += 0.1f;
 break;
 case RIGHT:
 // zoom out
 rotY -= 0.1f;
 break;
 case UP:
 if (keyEvent.isShiftDown())
 zoomF += 0.01f;
 else
 rotX += 0.1f;
 break;
 case DOWN:
 if (keyEvent.isShiftDown())
 {
 zoomF -= 0.01f;
 if (zoomF < 0.01)
 zoomF = 0.01;
 } else
 rotX -= 0.1f;
 break;
 }
 }
 */
void getBodyDirection(int userId, PVector centerPoint, PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;

  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, jointL);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_HEAD, jointH);
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, jointR);

  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_NECK, centerPoint);

  /*  // manually calc the centerPoint
   PVector shoulderDist = PVector.sub(jointL,jointR);
   centerPoint.set(PVector.mult(shoulderDist,.5));
   centerPoint.add(jointR);
   */

  PVector up = PVector.sub(jointH, centerPoint);
  PVector left = PVector.sub(jointR, centerPoint);

  dir.set(up.cross(left));
  dir.normalize();
}