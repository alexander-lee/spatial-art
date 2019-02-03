// ParticleSystem adapted from Daniel Shiffman
// https://processing.org/examples/simpleparticlesystem.html

// How wide should the particles fly
final float VX_THRESHOLD_MIN = -5;
final float VX_THRESHOLD_MAX = 5;

final int INIT_LIFESPAN = 30;
final float FINAL_SIZE_MULT = 1.05; // At the end it'll grow x1.1 in size

final float DESTROY_EFFECT_LENGTH = 500; // ms

class Particle {
  PVector position; // Center of Particle/Rectangle
  PVector velocity;
  PVector acceleration;
  int lifespan;
  
  PImage image;
  PVector size;
  PVector offset; // Random offset to create an effect
  int zIndex;
  
  int beginRotation;
  int endRotation;
  
  boolean imageLoaded;
  
  int destroyStartTime;
  boolean willDestroy;
  boolean dead;
  
  Particle(PVector pPosition, int pZIndex) {
    position = pPosition.copy();
    velocity = new PVector(random(VX_THRESHOLD_MIN, VX_THRESHOLD_MAX), random(-5, 5));
    acceleration = new PVector(random(-1, 1), random(-1, 1)); // Float up faster over time
    lifespan = INIT_LIFESPAN;
    
    size = new PVector(int(random(50, 100)), int(random(50, 100)));
    offset = new PVector(int(random(-5, 5)), int(random(-5, 5)));
    zIndex = pZIndex;
    image = createImage(int(size.x), int(size.y), ARGB);
    
    beginRotation = int(random(-5, 3));
    endRotation = beginRotation + int(random(10, 20));
    
    imageLoaded = false;
    willDestroy = false;
    dead = false;
  }
  
  PVector getPosition() {
    return position;
  }
  
  void setPosition(PVector pPosition) {
    position = pPosition.copy();
  }
  
  void setVelocity(PVector pVelocity) {
    velocity = pVelocity.copy();
  }
  
  PVector getAcceleration() {
    return acceleration;
  }
  
  void setAcceleration(PVector pAcceleration) {
    acceleration = pAcceleration.copy();
  }
  
  PVector getOffset() {
    return offset;
  }
  
  boolean isDead() {
    return dead; 
  }
  
  Rectangle getRectangle() {
    return new Rectangle(
      int(position.x - (size.x / 2)), 
      int(position.y - (size.y / 2)), 
      int(size.x), 
      int(size.y)
     );
  }
  
  Rectangle getOffsetRectangle() {    
    return new Rectangle(
      int(position.x - (size.x / 2) + offset.x), 
      int(position.y - (size.y / 2) + offset.y), 
      int(size.x), 
      int(size.y)
     );
  }
  
  void setImagePixels(color[] pixelsToUpdate) {
    image.loadPixels();
    arrayCopy(pixelsToUpdate, image.pixels);
    image.updatePixels();
    // image.filter(INVERT);
    
    imageLoaded = true;
  }
  
  boolean shouldDestroy() {
    Rectangle bounds = getRectangle();
    
    return !willDestroy && (
      lifespan <= 0 || 
      largestFlow.mag() > 40 ||
      bounds.x + bounds.width > width || 
      bounds.x < 0 || 
      bounds.y + bounds.height > height ||
      bounds.y < 0
      //|| bounds.x > face.x + face.width ||
      //bounds.x < face.x ||
      //bounds.y > face.y + face.height ||
      //bounds.y < face.y
    );
  }
  
  void run() {
    updatePosition();
    lifespan -= 1;
    render();
    
    // Check if dead (after destroy effect is performed)
    if (willDestroy && millis() >= destroyStartTime + DESTROY_EFFECT_LENGTH) {
      dead = true;
    }
  }
  
  void updatePosition() {
    // Euler's Method way of updating the position
    velocity.add(acceleration); // velocity += acceleration
    position.add(velocity); // position += velocity
    
    Rectangle bounds = getRectangle();
    
    if (bounds.x + bounds.width > face.x + face.width || bounds.x < face.x) {
      velocity = new PVector(-velocity.x, velocity.y);
    }
    if (bounds.y + bounds.height > face.y + face.height || bounds.y < face.y) {
      velocity = new PVector(velocity.x, -velocity.y);
    }
  }
  
  void render() {
    if (!imageLoaded) {
      return;
    }
    
    Rectangle bounds = getRectangle();
    float lifeProgress =  constrain(1 - ((float)lifespan / INIT_LIFESPAN), 0, 1);
    
    // Grow the image over time
    int img_width = int(lerp(bounds.width, bounds.width * FINAL_SIZE_MULT, lifeProgress));
    int img_height = int(lerp(bounds.height, bounds.height * FINAL_SIZE_MULT, lifeProgress));
    
    // Destroy Effect: Fade out
    int alpha = !willDestroy ? 255 : int(lerp(255, 0, (millis() - destroyStartTime) / DESTROY_EFFECT_LENGTH));
    int rotationX = int(lerp(beginRotation, endRotation, lifeProgress));
    int rotationY = int(lerp(beginRotation, endRotation, lifeProgress));
    pushMatrix();
    
    // Transformations

    rotateX(radians(rotationX));
    rotateY(radians(rotationY));
    
    // Main Image
    stroke(0, 0, 0, min(alpha, 20)); // Inner Shadow Effect
    strokeWeight(2);
    
    beginShape();
    tint(199, 255, 183, alpha); // Light Green
    texture(image);
    // CCW (Top Left, Bottom Left, Bottom Right, Top Right)
    vertex(bounds.x, bounds.y, zIndex, 0, 0);
    vertex(bounds.x, bounds.y + img_height, zIndex, 0, img_height);
    vertex(bounds.x + img_width, bounds.y + img_height, zIndex, img_width, img_height);
    vertex(bounds.x + img_width, bounds.y, zIndex, img_width, 0);
    
    endShape();
    // image(image, bounds.x, bounds.y, img_width, img_height);

    // Screen Mask Image
    noStroke();
    beginShape();
    tint(255, alpha);
    texture(screenMask);
    vertex(bounds.x, bounds.y, zIndex, 0, 0);
    vertex(bounds.x, bounds.y + img_height, zIndex, 0, img_height);
    vertex(bounds.x + img_width, bounds.y + img_height, zIndex, img_width, img_height);
    vertex(bounds.x + img_width, bounds.y, zIndex, img_width, 0);
    endShape();
    // image(screenMask, bounds.x, bounds.y);
    
    popMatrix();
  }
  
  void destroy() {
    destroyStartTime = millis();
    willDestroy = true;
  }
  
  PVector cartesianToSpherical(PVector coord) {
    PVector spherical = new PVector();
    spherical.x = coord.mag(); // r
    if (spherical.x > 0) {
      spherical.y = -atan2(coord.z, coord.x); // theta or latitude
      spherical.z = asin(coord.y / spherical.x);
    }
    
    return spherical;
  }
}
