import gab.opencv.*;
import processing.video.*;
import java.awt.*;

PImage screenMask;
PImage videoImage;

Capture video;
OpenCV opencv;
ShimodairaOpticalFlow sof;
ParticleSystem ps;

Rectangle face;

final int ADD_PARTICLE_DELAY = 2; // Every x draw cycles, add a particle
final int MAX_PARTICLES = 30;

int sourceChannel = int(random(3));
int targetChannel = int(random(3));

PVector largestFlow = new PVector(0, 0);
PVector averageFlow = new PVector(0, 0);

void setup() {
  size(960, 540, P3D);
  frameRate(60);
  
  video = new Capture(this, width, height);

  screenMask = loadImage("Screen Mask.png");
  videoImage = createImage(width, height, RGB);
  
  opencv = new OpenCV(this, width, height); 
  sof = new ShimodairaOpticalFlow(video);
  ps = new ParticleSystem(new PVector(width/2, height/2));
  
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE); 
  video.start();
}

void draw() {
  sof.calculateFlow();
  
  opencv.loadImage(video);
  Rectangle[] faces = opencv.detect();
  
  // Find Largest Face and update ParticleSystem data
  if (faces.length > 0) {
    face = getLargestRectByArea(faces);
    face = new Rectangle(face.x, face.y - (face.height / 5), face.width, face.height + (face.height / 5) * 2); // Increase the bounds
    
    // DEBUG: Face Rect
    //stroke(255,0,0);
    //noFill();
    //rect(face.x, face.y, face.width, face.height);
    //strokeWeight(10);
    //point(face.x + face.width / 2, face.y + face.height * 0.80);
    
    ps.setOrigin(new PVector(face.x + face.width / 2, face.y + face.height / 2)); // Center of Face
  }
  
  if (face != null && frameCount % ADD_PARTICLE_DELAY == 0) {
    Particle particle = new Particle(new PVector(), ps.particles.size()); // z-index: ps.particles.size()
    ps.addParticle(particle);
  }
  
  // Alter Main Video
  videoImage.loadPixels();
  video.loadPixels();
  arrayCopy(video.pixels, videoImage.pixels);
  videoImage.updatePixels();
  // videoImage.filter(BLUR, 2);
  videoImage.filter(GRAY);
  // videoImage.filter(DILATE);
  
  videoImage.loadPixels();
  darkenPixels(videoImage.pixels);
  distortPixels(videoImage.pixels);
  // tintPixels(videoImage.pixels, color(0, 153, 204));
  
  // Color Shift based off optical flow vector
  largestFlow = getLargestFlowForce().copy().mult(0.1);
  averageFlow = getAverageFlowForce().copy();
  
  if (largestFlow.mag() > 10) {
    // Clamp flow vector
    largestFlow = new PVector(min(abs(largestFlow.x), 100), min(abs(largestFlow.y), 100));
    copyChannel(width, height, int(largestFlow.x), int(largestFlow.y), sourceChannel, targetChannel, videoImage.pixels, videoImage.pixels);
  }
  videoImage.updatePixels();

  background(videoImage);
  
  // Run Particle Effects for Moving Screen/Rects
  loadParticleImages();
  ps.run();
}

void loadParticleImages() {
  ArrayList<Particle> particles = ps.getParticles();
  
  video.loadPixels();
  
  for (int i = particles.size()-1; i >= 0; --i) {
    Particle p = particles.get(i);
    Rectangle rect = p.getOffsetRectangle();
    
    int pixelIndex = 0;
    color[] newImagePixels = new color[rect.width * rect.height];
    
    // Copy over the pixels from the offsetted position to the actual position of the rectangle
    for (int y = rect.y; y < rect.y + rect.height; ++y) {
      for (int x = rect.x; x < rect.x + rect.width; ++x) {
        int readPixelIndex = y * width + x;
        
        if (readPixelIndex >= video.pixels.length || readPixelIndex < 0) {
          continue;
        }
        
        newImagePixels[pixelIndex] = video.pixels[readPixelIndex];
        ++pixelIndex;
      }
    }
    
    p.setImagePixels(newImagePixels);
  }
}

Rectangle getLargestRectByArea(Rectangle[] rects) {
  float maxArea = rects[0].width * rects[0].height;
  Rectangle largestRect = rects[0];
  
  for (Rectangle rect : rects) {
    if (rect.width * rect.height > maxArea) {
      maxArea = rect.width * rect.height;
      largestRect = rect;
    }
  }
  
  return largestRect;
}

void distortPixels(color[] imagePixels) {
  for (int i = 0; i < imagePixels.length; ++i) {
    float distortionProbability = random(1); // 0-1;
    
    // 60% Distortion
    if (distortionProbability > 0.6) {
      continue;
    }
      
    color randomColor = color(random(255), random(255), random(255), 255);
    float lerpAmount = random(0.3);
    imagePixels[i] = lerpColor(imagePixels[i], randomColor, lerpAmount);
  }
}

void darkenPixels(color[] imagePixels) {
  for (int i = 0; i < imagePixels.length; ++i) {
    imagePixels[i] = lerpColor(imagePixels[i], color(0,0,0), 0.5); 
  }
}

void tintPixels(color[] imagePixels, color c) {
  for (int i = 0; i < imagePixels.length; ++i) {
    imagePixels[i] = lerpColor(imagePixels[i], c, 0.5);
  }
}

PVector getLargestFlowForce() {
  float maxForce = 0;
  PVector largestForce = new PVector(0, 0);
  
  for (int i = 0; i < sof.flows.size() - 2; i += 2) {
    PVector forceStart = sof.flows.get(i);
    PVector forceEnd = sof.flows.get(i + 1);
    float magnitude = abs(forceStart.dist(forceEnd));
    
    if (maxForce == 0 || magnitude > maxForce) {
      maxForce = magnitude;
      largestForce = forceEnd.sub(forceStart);
    }
  }
  
  return largestForce;
}

PVector getAverageFlowForce() {
  PVector averageFlow = new PVector(0, 0);
  
  for (int i = 0; i < sof.flows.size() - 2; i += 2) {
    PVector forceStart = sof.flows.get(i);
    PVector forceEnd = sof.flows.get(i + 1);
    averageFlow.add(forceEnd.sub(forceStart));
  }
  
  averageFlow.mult(1 / float(sof.flows.size() / 2));
  return averageFlow;
}

// Color Shift Code adapted from http://datamoshing.com/tag/rgb/
void copyChannel(int imgWidth, int imgHeight, int yStart, int xStart, int sourceChannel, int targetChannel, color[] sourcePixels, color[] targetPixels) {
  for (int y = 0; y < imgHeight; ++y) {
    int sourceYOffset = (yStart + y) % imgHeight;
    
    for (int x = 0; x < imgWidth; ++x) {
      int sourceXOffset = (xStart + x) % imgWidth;
      
      color sourcePixel = sourcePixels[sourceYOffset * imgWidth + sourceXOffset];
      color targetPixel = targetPixels[y * imgWidth + x];
      
      float[] sourceRGB = new float[3];
      float[] targetRGB = new float[3];
      sourceRGB[0] = sourcePixel >> 16 & 0xFF; // (RRGGBB >> 16 = RR)
      sourceRGB[1] = sourcePixel >> 8 & 0xFF; // (RRGGBB >> 8 = GG)
      sourceRGB[2] = sourcePixel & 0xFF;
      
      targetRGB[0] = targetPixel >> 16 & 0xFF; // (RRGGBB >> 16 = RR)
      targetRGB[1] = targetPixel >> 8 & 0xFF; // (RRGGBB >> 8 = GG)
      targetRGB[2]= targetPixel & 0xFF;

      if (targetChannel == 0) {
        targetPixels[y * imgWidth + x] = color(sourceRGB[0], targetRGB[1], targetRGB[2]);
      }
      else if (targetChannel == 1) {
        targetPixels[y * imgWidth + x] = color(targetRGB[0], sourceRGB[1], targetRGB[2]);
      }
      else if (targetChannel == 2) {
        targetPixels[y * imgWidth + x] = color(targetRGB[0], targetRGB[1], sourceRGB[2]);
      }
    }
    
  }
}

void captureEvent(Capture c) {
  c.read();
}
