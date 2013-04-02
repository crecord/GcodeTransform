import org.gicentre.utils.spatial.*;    // For map projections.


ArrayList <Float> longitude; 
ArrayList <Float> longTrans; 
ArrayList <Float> latitude; 
ArrayList <Float> latTrans; 
ArrayList <Double> speedTrans; 
ArrayList <Double> speed; 
ArrayList <Double> timeStamp; 
XML xmlDict;
String coor; 
float xZero;
float yZero;
float xHigh;
float yHigh;

void setup() {
  size(400, 400); 
  longitude = new ArrayList<Float>();
  latitude = new ArrayList<Float>();
  timeStamp = new ArrayList<Double>();
  longTrans = new ArrayList<Float>();
  latTrans = new ArrayList<Float>();
  speed = new ArrayList<Double>();
  speedTrans = new ArrayList<Double>();
  xmlDict = loadXML("firstWalkNoLine.plist");
  //println(xmlDict.getContent());
  //println (xmlDict.listChildren());

  //get the key and hstring elements into their own arrays
  XML[] dict = xmlDict.getChildren("dict");
  XML[]time = dict[0].getChildren("key");  
  XML[]coords = dict[0].getChildren("string");  

  // store time stamps in their own array as ints
  for (int i =0; i < time.length; i++) {
    String theTime = time[i].getContent().toString();
    double timeNum = Double.valueOf(theTime);
    timeStamp.add(timeNum);
  }


  // stores longitude and latitude in their own arrays as floats and tranlated into the UTM system ofmapping
  for (int i =0; i < coords.length; i++) {
    coor = coords[i].getContent();  

    String[] list = split(coor, ",");  

    float tempNumLat = Float.valueOf(list[0]);
    float tempNumLong = Float.valueOf(list[1]);
    // first translates coordinates into the UTM coordinate system  
    utmTrans(tempNumLat, tempNumLong);
    //mercatorTrans(tempNumLat, tempNumLong);
  }



  //determine where you want the origin point to be by finding the limit of the coords
  xZero = getLowest(latitude);
  yZero = getLowest(longitude);
  xHigh = getHigh(latitude);
  yHigh = getHigh(longitude);
  float xbuffer = (xHigh - xZero)/5;
  //println ( "xbuffer: " +xbuffer); 
  float ybuffer = (yHigh-yZero)/5;
  //println ( "ybuffer: " +ybuffer); 
  xZero -= xbuffer; 
  yZero -= ybuffer;
  xHigh += xbuffer;
  yHigh += ybuffer;
  //println ("xZero "+xZero);
  //println ("yZero "+ yZero);
  //println ("xHigh "+ xHigh);
  //println ("yHigh "+ yHigh);


  float drawX; 
  float drawY; 
  float drawXmap; 
  float drawYmap; 

  for (int i=0; i < longitude.size(); i++) {
    drawY = longitude.get(i);
    drawX = latitude.get(i);  
    drawXmap = map(drawX, xZero, xHigh, 0, 48);
    longTrans.add(drawXmap); 
    // restricting between
    //println("mapping varx: " + drawX + " now: " + drawXmap + " originally b/w low:" + xZero + "high "+ xHigh + "now mapped b/w 0 and high:"+ width);
    drawYmap = map(drawY, yZero, yHigh, 0, 48 ); 
    latTrans.add(drawYmap); 
    //println("mapping vary: " + drawY + " now: " + drawYmap + " originally b/w low:" + yZero + "high "+ yHigh + "now mapped b/w 0 and high:"+ height);
    ellipse (drawXmap, drawYmap, 2, 2);
    text( i, drawXmap, drawYmap);
  }

 float fromX;
  float fromY;
  float toX ;
  float toY;
  float distance; 
  double oldTime;
  double newTime;
  double timediff;
  double timeDiffMin;
  double speedz;
  //calculate speed and storing it in an arrayList
  println("stamps"+timeStamp);
  
  for (int i=1; i<latTrans.size(); i++ ) {
    //get the distance in inches
    fromX = latTrans.get(i-1);
    fromY = longTrans.get(i-1);
    toX = latTrans.get(i);
    toY = longTrans.get(i);
    distance = dist(fromX, fromY, toX, toY); 
    println ("timeStampOld" + timeStamp.get(i-1));
    println ("timeStampNew" + timeStamp.get(i));
    oldTime = timeStamp.get(i-1);
    newTime = timeStamp.get(i);
    timediff = newTime - oldTime;
     println ("timeDiff" + timediff);
    timeDiffMin = timediff/60;
    println ("timeDiffMin" + timeDiffMin);
    speedz = distance/timeDiffMin;  
    println ("speed" + speedz);
    speed.add(speedz);
  }
 println( speed);

//write array that scales Xcoordinates to between .5 (fast) .2 (slow).
double fastest  = getHighDouble(speed); 
double slowest = getLowestDouble(speed);
double curSpeed;
double newSpeed;
for(int i=0; i < speed.size(); i++){
  curSpeed = speed.get(i);
  newSpeed = map((float)curSpeed,(float)slowest,(float)fastest,.6,1.2);  
  speedTrans.add(newSpeed);
}  
println(speedTrans);
writeGcode(); 
}

void writeGcode(){
  String words = "G4,M61,G90, (V-Carving),T11,S6500,M3,G0 Z4.0000,G0 X"+ truncateFloat(latTrans.get(0)) + " Y"+ truncateFloat(latTrans.get(0)) ;
  String path ="";
  String end = ",G0 Z4.0,M5,G53 Z,T0,M62,G92,M30";
  for (int i = 1; i < latTrans.size() -1; i++){
   path += ",G1 "+"X"+truncateFloat(latTrans.get(i)) + " Y" + truncateFloat(longTrans.get(i)) + " Z"+ truncateDouble(speedTrans.get(i)) + " F" + truncateDouble(speed.get(i));
  } 
  words += path;
  words += end;
  
String[] list = split(words, ',');

// Writes the strings to a file, each on a separate line
saveStrings("firstWalkRealDeal2.nc", list);
}



void draw() {
}

float getLowest (ArrayList<Float> listOfCoord ) {
  //get lowest longitude and latitude
  float curLarge = listOfCoord.get(0);
  float num;
  for (int i =0; i < listOfCoord.size(); i++) {
    num = listOfCoord.get(i);  
    if (num < curLarge) {
      curLarge = num;
      
    }
  }
  return curLarge;
}


float getHigh (ArrayList<Float> listOfCoord ) {
  //get lowest longitude and latitude
  float curLarge = listOfCoord.get(0);
  float num;
  for (int i =0; i < listOfCoord.size(); i++) {
    num = listOfCoord.get(i);  
    if (num > curLarge) {
      curLarge = num;
    }
  }
  return curLarge;
}

float truncateFloat (float longest){
 String shorter =  String.format("%.4f", longest); 
 float trunc = Float.valueOf(shorter);
 return trunc; 
}

double truncateDouble (double longest){
 String shorter =  String.format("%.4f",longest); 
 double trunc = Double.valueOf(shorter);
 return trunc; 
}

double getLowestDouble (ArrayList<Double> listOfCoord ) {
  //get lowest longitude and latitude
  double curLarge = listOfCoord.get(0);
  double num;
  for (int i =0; i < listOfCoord.size(); i++) {
    num = listOfCoord.get(i);  
    if (num < curLarge) {
      curLarge = num;
      
    }
  }
  return curLarge;
}


double getHighDouble (ArrayList<Double> listOfCoord ) {
  //get lowest longitude and latitude
  double curLarge = listOfCoord.get(0);
  double num;
  for (int i =0; i < listOfCoord.size(); i++) {
    num = listOfCoord.get(i);  
    if (num > curLarge) {
      curLarge = num;
    }
  }
  return curLarge;
}


//use utm
void utmTrans (float lat, float lng) {
  Ellipsoid usEllip = new Ellipsoid(23);
  UTM proj = new UTM( usEllip, 40.4406, 79.9961); 
  PVector geo = new PVector( lng, lat); 
  PVector latLong = proj.transformCoords(geo); 
  //println ("these are the translated coords"+latLong);
  //then add to apropriate array lists
  latitude.add(latLong.y); //add lat
  longitude.add(latLong.x);  //add long
}


// use mercator
void mercatorTrans (float lat, float lng) {
  WebMercator proj = new WebMercator();
  PVector geo = new PVector( lng, lat); 
  PVector latLong = proj.transformCoords(geo); 
  latitude.add(latLong.y); //add lat
  longitude.add(latLong.x);  //add long
}

