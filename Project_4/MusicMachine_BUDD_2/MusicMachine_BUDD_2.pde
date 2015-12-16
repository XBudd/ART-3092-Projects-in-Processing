/* --------------------------------------------------------------------------
 * Baed on Minim Library's Tick Example Sketch
 * --------------------------------------------------------------------------
 * prog: Colin Budd - www.xbudd.com
 * date:  11/28/2015 
 * school: Cornell University
 * ----------------------------------------------------------------------------
 */
import SimpleOpenNI.*;
import KinectProjectorToolkit.*;
import geomerative.*;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim       minim;
AudioOutput out;

Sampler     kick;
Sampler     snare;
Sampler     hat;

int bpm;
int beat; // which beat we're on

SimpleOpenNI kinect;
KinectProjectorToolkit kpc;

int time;
int wait = 250;
int SIZE_JOINTS = 20;

// VELOCITY
// The system time for this and the previous frame (in milliseconds)
int currTime, prevTime;
// The elapsed time since the last frame (in seconds)
float deltaTime;

float lastMovingX, lastMovingY;
float movingX, movingY;
float velX, velY, speed;


//boolean[] buttonBoolArray = new boolean[48];
BTN drumBTN;
ArrayList<BTN> buttons = new ArrayList<BTN>();
boolean[] hatRow = new boolean[16];
boolean[] snrRow = new boolean[16];
boolean[] kikRow = new boolean[16];

// Geometry
RShape drumLeft;
RPoint[][] pointPathsDrumLeft;

boolean ignoringStyles = false;

void setup()
{
  size(displayWidth, displayHeight, P2D); 

  time = millis(); // store current time;

  // Initialise the timer
  currTime = prevTime = millis();
  // initialize position
  lastMovingX = lastMovingY = Float.MAX_VALUE;


  // setup Kinect
  kinect = new SimpleOpenNI(this); 
  kinect.setMirror(true);
  kinect.enableDepth();
  kinect.enableUser();
  kinect.alternativeViewPointDepthToImage();

  // setup Kinect Projector Toolkit
  kpc = new KinectProjectorToolkit(this, kinect.depthWidth(), kinect.depthHeight());
  kpc.loadCalibration("calibration.txt");



  //load shape geometry for shapes
  RG.init(this);
  ignoringStyles = !ignoringStyles; //show color
  RG.ignoreStyles(ignoringStyles);
  RG.setPolygonizer(RG.ADAPTATIVE);

  //Note: have to have the layers JUST be paths, cant be any further info
  drumLeft = RG.loadShape("shapes/leftBars.svg");
  drumLeft.centerIn(g, 100, 1, 1);
  drumLeft.scale(1.1);
  drumLeft.translate(275, height/2);
  pointPathsDrumLeft = drumLeft.getPointsInPaths();
  // println(drumLeft.countChildren());



  // setup minim
  minim = new Minim(this);
  out   = minim.getLineOut();

  // load all of our samples, using 4 voices for each.
  // this will help ensure we have enough voices to handle even
  // very fast tempos.
  kick  = new Sampler( "BD.wav", 4, minim );
  snare = new Sampler( "SD.wav", 4, minim );
  hat   = new Sampler( "CHH.wav", 4, minim );

  // patch samplers to the output
  kick.patch( out );
  snare.patch( out );
  hat.patch( out );

  // set up Drum Buttons (Left Side of Screen)
  for (int i = 0; i<16; i++) {
    buttons.add( new BTN(drumLeft.children[i], hatRow, i ) ); 
    buttons.add( new BTN(drumLeft.children[i+16], snrRow, i) ); 
    buttons.add( new BTN(drumLeft.children[i+32], kikRow, i) ); 
    //println("hatRow: " + i + " " + hatRow[i]);
  }  

  bpm = 120;

  beat = 0;

  // start the sequencer
  out.setTempo( bpm );
  out.playNote( 0, 0.25f, new Tick() );
}

void draw()
{  
  kinect.update();  
  kpc.setDepthMapRealWorld(kinect.depthMapRealWorld()); 
  background(0);
  drawProjectedSkeletons();

  //BEAT MARKER (Play head)
  if ( beat % 4 == 0 )
  {
    noStroke();
    fill(255, 255);
  } else
  {
    noStroke();
    fill(255, 110);
  }
  // beat marker    
  // rect(((width/2)-840)+beat*110, (height/2)-180, 50, 320);

  ellipse( ((width/2)-810)+beat*110, (height/2)-150, 90, 90);
  ellipse( ((width/2)-810)+beat*110, (height/2), 90, 90);
  ellipse( ((width/2)-810)+beat*110, (height/2)+150, 90, 90);
 
 // drumBTN.playHead(beat);
  
  noStroke();
  for (int i = 0; i < buttons.size (); ++i)
  {
    buttons.get(i).draw();
  }


  // VELOCITY
  // get the current time
  currTime = millis();
  // calculate the elapsed time in seconds
  deltaTime = (currTime - prevTime)/1000.0;
  // remember current time for the next frame
  prevTime = currTime;
  fill(255);
  ellipse(movingX, movingY, 30, 30); 
  // Calculate velocity in X and Y directions (pixels / second)
  if (lastMovingX != Float.MAX_VALUE) {
    velX = (movingX - lastMovingX) / deltaTime;
    velY = (movingY - lastMovingY) / deltaTime;
    speed = sqrt(velX*velX + velY*velY);
  }
  lastMovingX = movingX;
  lastMovingY = movingY;
}


void drawProjectedSkeletons() {
  int[] userList = kinect.getUsers();
  for (int i=0; i<userList.length; i++) {
    if (kinect.isTrackingSkeleton(userList[i])) {
      PVector pHead = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_HEAD);
      PVector pNeck = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_NECK);
      PVector pTorso = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_TORSO);
      PVector pLeftShoulder = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_SHOULDER);
      PVector pRightShoulder = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_SHOULDER);
      PVector pLeftElbow = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_ELBOW);
      PVector pRightElbow = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_ELBOW);
      PVector pLeftHand = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_HAND);
      PVector pRightHand = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_HAND);      
      PVector pLeftHip = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_HIP);
      PVector pRightHip = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_HIP);
      PVector pLeftKnee = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_KNEE);
      PVector pRightKnee = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_KNEE);
      PVector pLeftFoot = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_LEFT_FOOT);
      PVector pRightFoot = getProjectedJoint(userList[i], SimpleOpenNI.SKEL_RIGHT_FOOT);


      movingX = pLeftHand.x;
      movingY = pLeftHand.y;
      stroke(0, 0, 255);
      strokeWeight(16);
      line(pHead.x, pHead.y, pNeck.x, pNeck.y);
      line(pNeck.x, pNeck.y, pTorso.x, pTorso.y);
      line(pNeck.x, pNeck.y, pLeftShoulder.x, pLeftShoulder.y);
      line(pLeftShoulder.x, pLeftShoulder.y, pLeftElbow.x, pLeftElbow.y);
      line(pLeftElbow.x, pLeftElbow.y, pLeftHand.x, pLeftHand.y);
      line(pNeck.x, pNeck.y, pRightShoulder.x, pRightShoulder.y);
      line(pRightShoulder.x, pRightShoulder.y, pRightElbow.x, pRightElbow.y);
      line(pRightElbow.x, pRightElbow.y, pRightHand.x, pRightHand.y);
      line(pTorso.x, pTorso.y, pLeftHip.x, pLeftHip.y);
      line(pLeftHip.x, pLeftHip.y, pLeftKnee.x, pLeftKnee.y);
      line(pLeftKnee.x, pLeftKnee.y, pLeftFoot.x, pLeftFoot.y);
      line(pTorso.x, pTorso.y, pRightHip.x, pRightHip.y);
      line(pRightHip.x, pRightHip.y, pRightKnee.x, pRightKnee.y);
      line(pRightKnee.x, pRightKnee.y, pRightFoot.x, pRightFoot.y);   

      fill(255, 0, 0);
      noStroke();
      ellipse(pHead.x, pHead.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pNeck.x, pNeck.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pTorso.x, pTorso.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftShoulder.x, pLeftShoulder.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightShoulder.x, pRightShoulder.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftElbow.x, pLeftElbow.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightElbow.x, pRightElbow.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftHand.x, pLeftHand.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightHand.x, pRightHand.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftHip.x, pLeftHip.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightHip.x, pRightHip.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftKnee.x, pLeftKnee.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightKnee.x, pRightKnee.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pLeftFoot.x, pLeftFoot.y, SIZE_JOINTS, SIZE_JOINTS);
      ellipse(pRightFoot.x, pRightFoot.y, SIZE_JOINTS, SIZE_JOINTS);
    }
  }
}

PVector getProjectedJoint(int userId, int jointIdx) {
  PVector jointKinectRealWorld = new PVector();
  PVector jointProjected = new PVector();
  kinect.getJointPositionSkeleton(userId, jointIdx, jointKinectRealWorld);
  jointProjected = kpc.convertKinectToProjector(jointKinectRealWorld);
  return jointProjected;
}


// -----------------------------------------------------------------
// SimpleOpenNI events -- do not need to modify these...

void onNewUser(SimpleOpenNI curContext, int userId) {
  println("onNewUser - userId: " + userId);
  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId) {
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId) {
  //println("onVisibleUser - userId: " + userId);
}