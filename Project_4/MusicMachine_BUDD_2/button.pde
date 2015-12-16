class BTN
{


  boolean[] steps;
  int btnId;
  RShape shape;
  int drumId;
  int beat;

  public BTN(RShape _shape, boolean[] _steps, int _id)
  {
    shape = _shape;
    steps = _steps;
    btnId = _id;
  }

  public void draw()
  {
    drumId = 0;
    if (steps == kikRow) {
      drumId = 32;
    }
    if (steps == snrRow) {
      drumId = 16;
    }


    RG.ignoreStyles(true);
    if (steps[btnId]) {
      noStroke();
      fill(0, 255, 0, 250);
    } else {
      noStroke();
      fill(255, 0, 0, 250);
    }
    drumLeft.children[btnId+drumId].draw();


    RG.ignoreStyles(ignoringStyles);

    int[] userList = kinect.getUsers();
    for (int t=0; t<userList.length; t++) {
      if (kinect.isTrackingSkeleton(userList[t])) {
        handHover(userList[t], drumId);
      }
    }
  }

  public void playHead(int _beat) {
    beat = _beat;
    RG.ignoreStyles(true);
    if ( beat % 4 == 0 )
    {
      noStroke();
      fill(255, 255);
    } else
    {
      noStroke();
      fill(255, 110);
    }
    drumLeft.children[beat].draw();
    drumLeft.children[beat+16].draw();
    drumLeft.children[beat+32].draw();

    RG.ignoreStyles(ignoringStyles);
  }

  public void handHover(int userId, int drumId) {
    PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
    PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);
    RPoint pL = new RPoint(pLeftHand.x, pLeftHand.y);
    RPoint pR = new RPoint(pRightHand.x, pRightHand.y);
    for (int i = 0; i <16; ++i) {
      if (drumLeft.children[i+drumId].contains(pL) || drumLeft.children[i+drumId].contains(pR)) {
        RG.ignoreStyles(true);
        strokeWeight(8);
        stroke(255);
        noFill();
        drumLeft.children[i+drumId].draw();
        RG.ignoreStyles(ignoringStyles);
        if (millis() - time >= wait*5) 
        {

          steps[i] = !steps[i];
          println("I touched i: " + (i+drumId));
          time = millis();
        }
      }
    }
  }
}

