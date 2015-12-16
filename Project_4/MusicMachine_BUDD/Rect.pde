
// simple class for drawing the gui
class Rect  
{


  int x, y, w, h;
  boolean[] steps;
  int stepId;
  boolean[] hands;

  public Rect(int _x, int _y, boolean[] _steps, int _id, boolean[] _hands)
  {
    x = _x;
    y = _y;
    w = 90;
    h = 90;
    steps = _steps;
    stepId = _id;
    hands = _hands;
  }

  public void draw()
  {

    if ( steps[stepId] )
    {
      noStroke();
      fill(0, 255, 0, 100);
    } else
    {
      noStroke();
      fill(255, 0, 0, 100);
    }

    ellipse(x, y, w, h);
  }


  public void handHover(int userId) {
    PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
    PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);
    if ( ((pLeftHand.x >= x) && (pLeftHand.x <= x+w) && (pLeftHand.y >= y) && (pLeftHand.y <= y+h))
      || ((pRightHand.x >= x) && (pRightHand.x <= x+w) && (pRightHand.y >= y) && (pRightHand.y <= y+h))) {
      strokeWeight(8);
      stroke(255);
      noFill();
      ellipse(x, y, w, h);
      if (millis() - time >= wait*1.5) {
        handClick(userId);
        time = millis();
      }
    }
  }


  public void handClick(int userId)
  { 
    PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
    PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);

    if ( (pLeftHand.x >= x) && (pLeftHand.x <= x+w) && (pLeftHand.y >= y) && (pLeftHand.y <= y+h)
      ||((pRightHand.x >= x) && (pRightHand.x <= x+w) && (pRightHand.y >= y) && (pRightHand.y <= y+h))) {

      steps[stepId] = !steps[stepId];
    }
  }


  public void mousePressed()
  {
    if ( mouseX >= x && mouseX <= x+w && mouseY >= y && mouseY <= y+h )
    {
      steps[stepId] = !steps[stepId];
      println(steps);
    }
  }
}



