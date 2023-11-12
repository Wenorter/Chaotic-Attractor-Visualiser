//3A Individual Project Draft Submmision
//Computer Vision, Strange Attractors and Chaos

//Description: Takes web camera as an input sensor, uses motion tracking to draw strange attractors.
//Uses 5P controls to switch or adjust particles.
//Video inputs: Webcam


//Note to end-user: Please use a camera in a dimly or dark room 
//with a faint light source  and keep threshold to a minimum to maintain
//motion tracking accuracy. If you have epilepsy please don't run it.

import processing.video.*;
import processing.sound.*;
import controlP5.*;

//Camera capture
String[] cameras;
Capture videoCapture;
PImage prevFrame;
boolean showVideo = false;

//Defaults
int threshold = 100;
int invert = 0;
float motion_tracking_speed = 0.07;
float motionXCoord = 0;
float motionYCoord = 0;
float lerpXCoord = 0;
float lerpYCoord = 0;

//Sounds
Amplitude amp;
AudioIn in;
int ampOffset = 100000;
SoundFile soundFile;
String[] soundList;
float volume = 0.1;

//Attractor
boolean changeAttractorEnabled = false;
boolean attractorEnabled = false;

float dT;
float attrScaleFactor = 2.0;
float attrA, attrB, attrC;
  
float attrX = 0.01;
float attrY = 0;
float attrZ = 0;

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
  soundFile.amp(volume);
  //print(volume + "\n");
  
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
                if (amp.analyze()*ampOffset > 600)                           
                    pixels[store] = color(abs(0-invert), abs(255-invert), abs(255-invert)); //cyan
                
                else if (amp.analyze()*ampOffset > 550 && amp.analyze()*ampOffset < 600)                         
                    pixels[store] = color(abs(255-invert), abs(0-invert), abs(0-invert)); //red
                
                else if (amp.analyze()*ampOffset > 200 && amp.analyze()*ampOffset < 550)                          
                    pixels[store] = color(abs(255-invert), abs(255-invert), abs(255-invert)); //white
                 
                else if (amp.analyze()*ampOffset > 150 && amp.analyze()*ampOffset < 200)                             
                    pixels[store] = color(abs(255-invert), abs(215-invert), abs(150-invert)); //pale gold
                
                else if (amp.analyze()*ampOffset > 100 && amp.analyze()*ampOffset < 150)               
                    pixels[store] = color(abs(255-invert), abs(215-invert), abs(100-invert)); //gold
                  
                else if (amp.analyze()*ampOffset > 50 && amp.analyze()*ampOffset < 100)              
                    pixels[store] = color(abs(255-invert), abs(165-invert), abs(0-invert)); //orange
                 
                else              
                    pixels[store] = color(abs(100-invert), abs(70-invert), abs(10-invert)); //golden brown               
            }
            else                 
                pixels[store] = color(invert, invert, invert);     
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
    if (count > 200){      
        motionXCoord = averageX / count;
        motionYCoord = averageY / count;
    }
  
    lerpXCoord = lerp(lerpXCoord, motionXCoord, motion_tracking_speed);
    lerpYCoord = lerp(lerpYCoord, motionYCoord, motion_tracking_speed);
      
    if (attractorEnabled){
        if (changeAttractorEnabled)
           drawRosslerAttractor(lerpXCoord, lerpYCoord);       
        else     
          drawThomasAttractor(lerpXCoord, lerpYCoord);
        
    }
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
    if (cameras.length == 0){        
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
    in = new AudioIn(this, 0);
    in.start();
    amp.input(in);

    soundFile = new SoundFile(this, path + "/" + soundList[int(random(0, soundList.length))]);
    if (soundFile != null){     
        soundFile.play();
        soundFile.loop();  
        
        println("Info: Loading playlist...\n");
        for (int i = 0; i < soundList.length; i++){
            print(soundList[i] + "\n");
        }
    }
    else {    
        print("Info: Music file(s) not found.\nPlease make sure some files are present at dir: " + path);
    }
}

void uiInit(){  
    ui = new ControlP5(this); 
  
    color backCol = color(255, 128), 
          actCol = color(255, 165, 0), 
          foreCol = color(255, 100, 0);
  
    //FPS Counter top right corner
    ui.addFrameRate().setInterval(10).setPosition(videoCapture.width - 20, 0);
  
    String[] sliderNames = {"threshold", "invert", "volume", "motion_tracking_speed"};
    String[] buttonNames = {"toggle_music", "change_attractor", "toggle_attractor"};
    float[] maxValues = {200, 255, 0.5, 0.1};
   
    int uiXPos = 0,
        uiYPos = 10, 
        uiWidth = 100,
        uiHeight = 10;

    //Sliders
    for (int i = 0; i < sliderNames.length; i++){
        uiYPos = uiYPos + 15;
        ui.addSlider(sliderNames[i], uiXPos, maxValues[i])
        .setPosition(uiXPos + 10, uiYPos)
        .setSize(uiWidth, uiHeight)
        .setColorBackground(backCol)
        .setColorActive(actCol)
        .setColorForeground(foreCol);
    }  
        
    //Buttons
    for (int i = 0; i < buttonNames.length; i++)
    {          
        uiYPos = uiYPos + 20;
        ui.addButton(buttonNames[i])
        .setPosition(uiXPos + 10, uiYPos)
        .setSize(uiWidth, uiHeight + 5)
        .setColorBackground(actCol)
        .setColorActive(255)
        .setColorForeground(foreCol);
    }           
}

//Event Control method 
public void controlEvent(ControlEvent theEvent) {
  
    println(theEvent.getController().getName());
    String buttonName = theEvent.getController().getName();
  
    //load the file depends on button
    if (buttonName.equals("toggle_music")){ 
        if (soundFile.isPlaying()){
            soundFile.pause();
            in.stop();
            amp.input(in);
            soundFile.amp(0); 
        }
        else{
            soundFile.play();    
            amp = new Amplitude(this);
            in = new AudioIn(this, 0);
            in.start();
            amp.input(in);
            soundFile.amp(volume); 
        }
    }
    else if(buttonName.equals("change_attractor")){
        if (!changeAttractorEnabled){
           print("Drawing Rossler Attractor");
           attrA = 0.2 * attrScaleFactor;
           attrB = 0.2 * attrScaleFactor;
           attrC = 5.7 * attrScaleFactor;
           changeAttractorEnabled = true;
        }
           
        else {
          print("Drawing Thomas Attractor");
          attrB = 0.208186 * attrScaleFactor;
          changeAttractorEnabled = false;
        }
    }    
    else if(buttonName.equals("toggle_attractor")){
        if (!attractorEnabled)
            attractorEnabled = true;
        else 
          attractorEnabled = false;
    }    
}   

void drawRosslerAttractor(float xCoord, float yCoord){
  
    dT = 0.01;
    
    float dx = -(attrY+attrZ)*dT;
    float dy = attrX+(attrA*attrY)*dT;
    float dz = attrB + attrZ*(attrX-attrC)*dT;
    
    attrX = attrX + dx;
    attrY = attrY + dy;
    attrZ = attrZ + dz;
    
    triangle(attrX+xCoord - 20, attrY+yCoord, attrX+xCoord + 20, attrY+yCoord, attrX+xCoord, attrY+yCoord + 30);    
}

void drawThomasAttractor(float xCoord, float yCoord){
    
    dT = 0.01;
    
    float dx = sin(attrY) - (attrB*attrX)*dT;
    float dy = sin(attrZ) - (attrB*attrY)*dT;
    float dz = sin(attrX) - (attrB*attrZ)*dT;
    
    attrX = attrX + dx;
    attrY = attrY + dy;
    attrZ = attrZ + dz;
  
    triangle(attrX+xCoord - 20, attrY+yCoord, attrX+xCoord + 20, attrY+yCoord, attrX+xCoord, attrY+yCoord + 30);   
}

//https://www.youtube.com/watch?v=WEBOTRboXBE&t=994s&ab_channel=timrodenbr%C3%B6kercreativecoding
void rasterize() {
  
    float tiles = 60;
    float tileSize = width/tiles;
    noStroke();
    
    //checking amplitude and changing colour according to frequency
    if (amp.analyze()*ampOffset > 250 && amp.analyze()*ampOffset < 300) 
        fill(250-invert); //white

    else if (amp.analyze()*ampOffset > 250 && amp.analyze()*ampOffset < 300) 
        fill(abs(230-invert), abs(190-invert), abs(138-invert)); //pale gold
 
    else if (amp.analyze()*ampOffset > 200 && amp.analyze()*ampOffset < 250) 
        fill(abs(255-invert), abs(215-invert), abs(32-invert)); //gold
  
    else if (amp.analyze()*ampOffset > 175 && amp.analyze()*ampOffset < 200) 
        fill(abs(0-invert), abs(183-invert), abs(235-invert)); //cyan

    else if (amp.analyze()*ampOffset > 125 && amp.analyze()*ampOffset < 150)
        fill(abs(220-invert), abs(20-invert), abs(60-invert)); //crimson

    else if (amp.analyze()*ampOffset < 100)  
        fill(abs(20-invert)); //black
  
    //harftone filter
    for (int x = 0; x < tiles; x++) {
        for(int y = 0; y < tiles; y++) {    
            color c = prevFrame.get(int(x*tileSize), int(y*tileSize));
            float b = map(brightness(c), 0, 255, 0, 0);    
            ellipse(x*tileSize, y*tileSize, 2, 2);
        }
    }
}
