/* --------------------------------------------------------------------------
 * Baed on Minim Library's Tick Example Sketch
 * --------------------------------------------------------------------------
 * prog: Colin Budd - www.xbudd.com
 * date:  11/28/2015 
 * school: Cornell University
 * ----------------------------------------------------------------------------
 */

import processing.opengl.*;
import gab.opencv.*;
import SimpleOpenNI.*;
import KinectProjectorToolkit.*;
import controlP5.*;
import java.util.*;
SimpleOpenNI kinect;
OpenCV opencv;
KinectProjectorToolkit kpc;
ArrayList<ProjectedContour> projectedContours;

PGraphics pg2;
PShader bodyShade;

// Get time for waiting system 
int time;
// The system time for this and the previous frame (in milliseconds)
int currTime, prevTime;
// The elapsed time since the last frame (in seconds)
float deltaTime;

float lastMovingX, lastMovingY;
float movingX, movingY;
float velX, velY, speed;


int wait = 250;
int SIZE_JOINTS = 20;

import ddf.minim.*;
import ddf.minim.ugens.*;

Minim       minim;
AudioOutput out;

Sampler     kick;
Sampler     snare;
Sampler     hat;

boolean[] hatRow = new boolean[16];
boolean[] snrRow = new boolean[16];
boolean[] kikRow = new boolean[16];

boolean[] topRow = new boolean[16];
boolean[] midRow = new boolean[16];
boolean[] bottomRow = new boolean[16];

ArrayList<Rect> buttons = new ArrayList<Rect>();

boolean[] buttonBoolArray = new boolean[1];
ArrayList<BTN> BTNbuttons = new ArrayList<BTN>();

int bpm;
int bodyShaderSpeed; //speed of shader on body
int beat; // which beat we're on
color bgColor;
int alphaSpeed;

// Geometry
import geomerative.*;

RShape arc1;
RShape drumLeft;
RPoint[][] pointPathsArc;
RPoint[][] pointPathsDrumLeft;

boolean ignoringStyles = false;


void setup()
{
  size(1920, 1080, P2D); 

  // store current time;
  time = millis();
  // Initialise the timer
  currTime = prevTime = millis();
  // initialize position
  lastMovingX = lastMovingY = Float.MAX_VALUE;

  // setup Kinect
  kinect = new SimpleOpenNI(this); 
  if (kinect.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }   
  kinect.setMirror(true);
  kinect.enableDepth();
  kinect.enableUser();
  kinect.alternativeViewPointDepthToImage();

  // setup OpenCV
  opencv = new OpenCV(this, kinect.depthWidth(), kinect.depthHeight());

  // setup Kinect Projector Toolkit
  kpc = new KinectProjectorToolkit(this, kinect.depthWidth(), kinect.depthHeight());
  kpc.loadCalibration("calibration.txt");
  kpc.setContourSmoothness(4);
  kpc.setDepthMapRealWorld(kinect.depthMapRealWorld()); 

  // load shader and PGraphics
  pg2 = createGraphics(600, 800, P2D);
  bodyShade = loadShader("nebula.glsl");
  bodyShade.set("resolution", float(pg2.width), float(pg2.height));
  bodyShade.set("starspeed", bodyShaderSpeed);
  pg2.shader(bodyShade);



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

  for (int i = 0; i < 16; i++)
  {
    //               
    buttons.add( new Rect(((width/2)-810)+i*110, (height/2)-150, hatRow, i, topRow) );
    buttons.add( new Rect(((width/2)-810)+i*110, (height/2)+0, snrRow, i, midRow) );
    buttons.add( new Rect(((width/2)-810)+i*110, (height/2)+150, kikRow, i, bottomRow ) );
  }

  bpm = 120;

  beat = 0;

  // start the sequencer
  out.setTempo( bpm );
  out.playNote( 0, 0.25f, new Tick() );


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
}

void draw()
{
  kinect.update();  
  kpc.setDepthMapRealWorld(kinect.depthMapRealWorld()); 
  kpc.setKinectUserImage(kinect.userImage());
  opencv.loadImage(kpc.getImage());

  // get projected contours
  projectedContours = new ArrayList<ProjectedContour>();
  ArrayList<Contour> contours = opencv.findContours();
  for (Contour contour : contours) {
    if (contour.area() > 2000) {
      ArrayList<PVector> cvContour = contour.getPoints();
      ProjectedContour projectedContour = kpc.getProjectedContour(cvContour, 1.0);
      projectedContours.add(projectedContour);
    }
  }


  background(0);
  noStroke();
  fill(bgColor, alphaSpeed);
  rect(0, 0, width, height);

  // draw PGraphics object for body with shader
  bodyShade.set("time", millis()/1000.0);
  pg2.beginDraw();
  pg2.rect(0, 0, pg2.width, pg2.height);
  pg2.endDraw();


  // draw projected contours
  for (int i=0; i<projectedContours.size (); i++) {
    ProjectedContour projectedContour = projectedContours.get(i);
    beginShape();
    texture(pg2);
    for (PVector p : projectedContour.getProjectedContours ()) {
      PVector t = projectedContour.getTextureCoordinate(p);
      vertex(p.x, p.y, pg2.width * t.x, pg2.height * t.y);
    }
    endShape();
  }


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

  fill(255);
  //text(frameRate, width - 60, 20);

  for (int i = 0; i < buttons.size (); ++i)
  {
    buttons.get(i).draw();
  }


  int[] userList = kinect.getUsers();
  for (int t=0; t<userList.length; t++) {
    if (kinect.isTrackingSkeleton(userList[t])) {
      // drawProjectedSkeletons(userList[t]);
      bodyController(userList[t]);
    }
  }
  // get the current time
  currTime = millis();

  // calculate the elapsed time in seconds
  deltaTime = (currTime - prevTime)/1000.0;

  // remember current time for the next frame
  prevTime = currTime;

  //fill(255);
  //ellipse(movingX, movingY, 30, 30); 

  // Calculate velocity in X and Y directions (pixels / second)
  if (lastMovingX != Float.MAX_VALUE) {
    velX = (movingX - lastMovingX) / deltaTime;
    velY = (movingY - lastMovingY) / deltaTime;
    speed = sqrt(velX*velX + velY*velY);

    //change nebula & bg
    bodyShaderSpeed = int(map(speed, 0.0, 800.0, 0, 100));
    int colorSpeed = int(map(speed, 0.0, 14000.0, 0, 255));
    alphaSpeed = int(map(speed, 0.0, 1000.0, 0, 50));
    bgColor = color(colorSpeed, colorSpeed/2, 255);
  }
  lastMovingX = movingX;
  lastMovingY = movingY;


  //Oddly important... I hate styles in processing
  noStroke();
}


void bodyController(int userId) {
  PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
  PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);
  //Velocity of Left Hand
  movingX = ((pLeftHand.x + pRightHand.y)/2);
  movingY = ((pLeftHand.y + pRightHand.y)/2);
  for (int i = 0; i < buttons.size (); ++i)
  {
    buttons.get(i).handHover(userId);
  }
}




void mousePressed()
{
  for (int i = 0; i < buttons.size (); ++i)
  {
    buttons.get(i).mousePressed();
  }
}

void drawProjectedSkeletons(int userId) {

  PVector pHead = getProjectedJoint(userId, SimpleOpenNI.SKEL_HEAD);
  PVector pNeck = getProjectedJoint(userId, SimpleOpenNI.SKEL_NECK);
  PVector pTorso = getProjectedJoint(userId, SimpleOpenNI.SKEL_TORSO);
  PVector pLeftShoulder = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  PVector pRightShoulder = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  PVector pLeftElbow = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_ELBOW);
  PVector pRightElbow = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
  PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);      
  PVector pLeftHip = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HIP);
  PVector pRightHip = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HIP);
  PVector pLeftKnee = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_KNEE);
  PVector pRightKnee = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_KNEE);
  PVector pLeftFoot = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_FOOT);
  PVector pRightFoot = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_FOOT);



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
  fill(0, 255, 0);
  textSize(80);
  text("LShoulder Y: " + pLeftShoulder.y, pLeftShoulder.x-80, pLeftShoulder.y);
  ellipse(pLeftShoulder.x, pLeftShoulder.y, SIZE_JOINTS, SIZE_JOINTS);
  fill(255, 0, 0);
  ellipse(pRightShoulder.x, pRightShoulder.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pLeftElbow.x, pLeftElbow.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pRightElbow.x, pRightElbow.y, SIZE_JOINTS, SIZE_JOINTS);
  text("LHand Y: " + pLeftHand.y, pLeftHand.x, pLeftHand.y);
  ellipse(pLeftHand.x, pLeftHand.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pRightHand.x, pRightHand.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pLeftHip.x, pLeftHip.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pRightHip.x, pRightHip.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pLeftKnee.x, pLeftKnee.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pRightKnee.x, pRightKnee.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pLeftFoot.x, pLeftFoot.y, SIZE_JOINTS, SIZE_JOINTS);
  ellipse(pRightFoot.x, pRightFoot.y, SIZE_JOINTS, SIZE_JOINTS);
}

PVector getProjectedJoint(int userId, int jointIdx) {
  PVector jointKinectRealWorld = new PVector();
  PVector jointProjected = new PVector();
  kinect.getJointPositionSkeleton(userId, jointIdx, jointKinectRealWorld);
  jointProjected = kpc.convertKinectToProjector(jointKinectRealWorld);
  return jointProjected;
}


// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");

  curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}