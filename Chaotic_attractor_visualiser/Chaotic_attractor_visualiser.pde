//3A Individual Project Draft Submmision
//Computer Vision, Strange Attractors and Chaos
//Description: Takes web camera as an input sensor, uses motion tracking to draw strange attractors.
//Uses 5P controls to switch or adjust particles.
//Video inputs: Webcam

import processing.video.*;
import processing.sound.*;
import controlP5.*;

//Camera capture
String[] cameras;
Capture videoCapture;
PImage prevFrame;
boolean showVideo = false;

int threshold = 100;
int invert = 0;
float motionXCoord = 0;
float motionYCoord = 0;
float lerpXCoord = 0;
float lerpYCoord = 0;

//Sounds
Amplitude amp;
int ampOffset = 100000;
SoundFile file;
String[] soundList;
float volume = 0.1;

//Attractor
String[] attractors = {"aizawa", "halvorsen", "fourwing", "rabFabrikant", "thomas"};
float z;
float a, b, c, d, e, f;
float attrXNext, attrYNext, attrZNext;

//UI
ControlP5 ui;

//Log
boolean firstPassDone = false;


void setup(){
  
  size(1200, 720); //720p
  
  try {
    camInit();
    soundInit();
    uiInit();
  }
  catch (Exception ex){
    println("Fatal: Project crashed.\n" + ex.toString() + "\n");
  }
}

void draw(){
  
  //load video pixels
  videoCapture.loadPixels();
  prevFrame.loadPixels();
  image(videoCapture, 0, 0);
  
  file.amp(volume);
  
  int count = 0;
  float averageX = 0;
  float averageY = 0;
  
  //load so def pixels are recognized
  loadPixels();
    
    //search through every pixel on x and y coordinate
    for (int x = 0; x < videoCapture.width; x++){
      for (int y = 0; y < videoCapture.height; y++){        
        int store = x + y*videoCapture.width;
                
        //do pixel manipulation if pixel store presents
        if (store != 0){           
          //get current colour from a video capture
          color currColour = videoCapture.pixels[store];     
          float red1 = red(currColour);
          float green1 = green(currColour);
          float blue1 = blue(currColour);
          
          //get colour from the previous frame
          color prevColour = prevFrame.pixels[store];   
          float red2 = red(prevColour);
          float green2 = green(prevColour);
          float blue2 = blue(prevColour);
                 
          float eucDist = dist(red1, green1, blue1, red2, green2, blue2);
          
          if (eucDist > sqrt(threshold)){
            
            averageX += x;
            averageY += y;
            count++;
            
            //checking amplitude and changing colour according to frequency
            if (amp.analyze()*ampOffset > 200)
            {              
              pixels[store] = color(abs(255-invert), abs(255-invert), abs(255-invert)); //white
            } 
            else if (amp.analyze()*ampOffset > 150 && amp.analyze()*ampOffset < 200)
            {              
              pixels[store] = color(abs(255-invert), abs(215-invert), abs(150-invert)); //pale gold
            } 
            else if (amp.analyze()*ampOffset > 100 && amp.analyze()*ampOffset < 150)
            {
               pixels[store] = color(abs(255-invert), abs(215-invert), abs(100-invert)); //gold
            }  
            else if (amp.analyze()*ampOffset > 50 && amp.analyze()*ampOffset < 100)
            {
               pixels[store] = color(abs(255-invert), abs(165-invert), abs(0-invert)); //orange
            }  
            else 
            {
              pixels[store] = color(abs(100-invert), abs(70-invert), abs(10-invert)); //golden brown
            }
          }
          else 
          {      
            pixels[store] = color(invert, invert, invert);
          }
        }
        else 
        {
          //log message is output only once
          if (!firstPassDone){
            print("Error: No loaded pixels.\n");
            firstPassDone = true;
          }
        }
      }
    }
     
    updatePixels();
    rasterize();

    //only found if threshold is less than 10
    if (count > 200) { 
      
      motionXCoord = averageX / count;
      motionYCoord = averageY / count;
    }
  
  lerpXCoord = lerp(lerpXCoord, motionXCoord, 0.1);
  lerpYCoord = lerp(lerpYCoord, motionYCoord, 0.1);
  
  //fill(255, 0, 255);
  //strokeWeight(2.0);
  //stroke(255,0,0);
  
  //here should be switch-case of attractors 

   
  //cal(lerpXCoord, lerpYCoord);     
   ellipse(lerpXCoord, lerpYCoord, 36, 36);
}

//squre root of euclidean distance
float eucDistSq(float x1, float y1, float z1, float x2, float y2, float z2){
  //euclidean distance which is used inside a pixel loop
  float eucDist = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1);
  return eucDist;
}

//whenever new frame available
void captureEvent(Capture videoCapture){
  prevFrame.copy(videoCapture, 0, 0, videoCapture.width, videoCapture.height, 0, 0, prevFrame.width, prevFrame.height);
  prevFrame.updatePixels();
  videoCapture.read();
}

void camInit(){
  cameras = Capture.list();
  printArray(cameras);
  //check if camera input present
  if (cameras.length == 0) {     
    
    println("There are no cameras available for capture.\nExiting...\n");
    exit();
  }
  else {
   
    videoCapture = new Capture(this, width, height, cameras[cameras.length - 1]);
    videoCapture.start();  
    prevFrame = createImage(videoCapture.width, videoCapture.height, RGB);
  } 
}

void soundInit(){ 
  //Sound init
  //Getting filenames from path
  String path = "../resonance";
  File folder = new File(dataPath(path));
  String[] soundList = folder.list();
   
  //Sound input stream 
  amp = new Amplitude(this);
  AudioIn in = new AudioIn(this, 0);
  in.start();
  amp.input(in);
  
  file = new SoundFile(this, path + "/" + soundList[int(random(0, soundList.length))]);
  if (file != null){     
    file.play();
    file.loop();    
    
    println("Info: Loading playlist...\n");
    for (int i = 0; i < soundList.length; i++) {
      print(soundList[i] + "\t");
    }
  }
  else {    
    print("Info: Music file(s) not found.\nPlease make sure some files are present at dir: " + path);
  }
}

void attrInit(){

}
void uiInit(){  
  ui = new ControlP5(this); 
  
  color backCol = color(255, 128); //
  color actCol = color(255, 165, 0); 
  color foreCol = color(255, 100, 0);
  
  ui.addFrameRate().setInterval(10).setPosition(videoCapture.width - 20, 0);
  ui.addSlider("threshold", 0, 200, 10, 10, 100, 10)
    .setColorBackground(backCol)
    .setColorActive(actCol)
    .setColorForeground(foreCol);
    
  ui.addSlider("invert", 0, 255, 10, 25, 100, 10)
    .setColorBackground(backCol)
    .setColorActive(actCol)
    .setColorForeground(foreCol);
    
  ui.addSlider("volume", 0, 0.5, 10, 40, 100, 10)
    .setColorBackground(backCol)
    .setColorActive(actCol)
    .setColorForeground(foreCol);
  
  if (attractors != null && attractors.length > 0) {
    ListBox lb = ui.addListBox("attractors", 10, 55, 100, 10)
       .setColorBackground(backCol)
       .setColorActive(actCol)
       .setColorForeground(foreCol);
       
    for (int i = 0; i < attractors.length; i++){
      lb.addItem("item " + i, i);
      //lb.addItem("test", 1);
    }
  }
  else
  {
    print("Info: Cannot load the attractor list. Make sure to initialise attractor list before uiInit().");
  }
}  


void drawAttractor(String attractor){
  /*switch(attractor){
    case "aizawa":
      a = 0.95; b = 0.7; c = 0.6;
      d = 3.5; e = 0.25; f = 0.1;
      attrXNext= x + ((z-y)/8);
      attrYNext = y + (x + z*y/5);
      attrZNext = z + (f - x*x + f*z*x)/9;
      break;
    case "halvorsen":    
      a = 1.89;
      attrXNext = x;
      attrYNext = y;
      attrZNext = z;
      break;
    case "fourwing":
      a = 0.2; b = 0.01; c = -0.4;
      attrXNext = a*x + y*z;
      attrYNext = b*x + c*y - x*z;
      attrZNext = -z -x*y;
      break;
    case "rabFabrikant":
      a = 0.14; b = 0.10;
      attrXNext = y*(z - 1 + sqrt(x)) + b*x;
      attrYNext = x*(3*z + 1 - sqrt(x)) + b*y;
      attrZNext = -2*z(a + x*y);
      break;
    case "thomas":
      b = 0.208186;
      attrXNext = sin(y) - b*x;
      attrYNext = sin(z) - b*y;
      attrZNext = sin(x) - b*z;
      break;
    default:
      break;   
   }*/
}

//https://www.youtube.com/watch?v=WEBOTRboXBE&t=994s&ab_channel=timrodenbr%C3%B6kercreativecoding
void rasterize() {
  
  float tiles = 60;
  float tileSize = width/tiles;
  noStroke();
  
  //checking amplitude and changing colour according to frequency
  if (amp.analyze()*ampOffset > 250 && amp.analyze()*ampOffset < 300)
  {
    fill(250-invert); //white
  } 
  if (amp.analyze()*ampOffset > 250 && amp.analyze()*ampOffset < 300)
  {
    fill(abs(230-invert), abs(190-invert), abs(138-invert)); //pale gold
  } 
  else if (amp.analyze()*ampOffset > 200 && amp.analyze()*ampOffset < 250)
  {
    fill(abs(255-invert), abs(215-invert), abs(32-invert)); //gold
  } 
  else if (amp.analyze()*ampOffset > 175 && amp.analyze()*ampOffset < 200)
  {
    fill(abs(0-invert), abs(183-invert), abs(235-invert)); //cyan
  }
  else if (amp.analyze()*ampOffset > 125 && amp.analyze()*ampOffset < 150)
  {
    fill(abs(220-invert), abs(20-invert), abs(60-invert)); //crimson
  }
  else if (amp.analyze()*ampOffset < 100)
  {
    fill(abs(20-invert)); //black
  }
  
  //harftone filter
  for (int x = 0; x < tiles; x++) {
    for(int y = 0; y < tiles; y++) {    
      color c = prevFrame.get(int(x*tileSize), int(y*tileSize));
      float b = map(brightness(c), 0, 255, 0, 0);    
      ellipse(x*tileSize, y*tileSize, 2, 2);
    }
  }
}
