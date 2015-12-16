class BTN
{

  int x, y, w, h;
  boolean[] active;
  int btnId;

  public BTN(int _x, int _y, int _w, int _h, boolean[] _active, int _id)
  {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    active = _active;
    btnId = _id;
  }

  public void draw()
  {
    if ( active[btnId] ) //button is active
    {
      noStroke();
      fill(255, 0, 0, 255);
    } else
    {
      noStroke();
      fill(255, 0, 0, 90);
    }
  }
  
  public void handHover(int userId) {
    PVector pLeftHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_LEFT_HAND);
    PVector pRightHand = getProjectedJoint(userId, SimpleOpenNI.SKEL_RIGHT_HAND);
    if ( ((pLeftHand.x >= x) && (pLeftHand.x <= x+w) && (pLeftHand.y >= y) && (pLeftHand.y <= y+h))
      || ((pRightHand.x >= x) && (pRightHand.x <= x+w) && (pRightHand.y >= y) && (pRightHand.y <= y+h))) {
      strokeWeight(8);
      stroke(255);
      noFill();
      rect(x, y, w, h);
      //print ("touched it");
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

      active[btnId] = !active[btnId];
      //reset
      print("hi");
      // instrumentButtons.resetAll();;    }
    }
  }
}
