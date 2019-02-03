// ParticleSystem adapted from Daniel Shiffman
// https://processing.org/examples/simpleparticlesystem.html

class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;
  int maxParticles;
  
  ParticleSystem(PVector pOrigin) {
    origin = pOrigin.copy();
    particles = new ArrayList<Particle>();
    maxParticles = MAX_PARTICLES;
  }
   
  void setOrigin(PVector pOrigin) {
    origin = pOrigin.copy();
  }
  
  ArrayList<Particle> getParticles() {
    return particles;
  }
  
  void addParticle() {
    addParticle(new Particle(origin, particles.size())); // PVector set as position is irrelevant
  }
  
  void addParticle(Particle particle) {
    if (particles.size() < maxParticles) {
      // Set origin within a radius of the Particle System's origin
      PVector particleOrigin = new PVector(origin.x + random((-face.width / 4), (face.width / 4)), origin.y + random((-face.height / 4), (face.height / 4)));
      particle.setPosition(particleOrigin);
      particles.add(particle);
    }
  }
  
  void run() {
    for (int i = particles.size()-1; i >= 0; --i) {
      Particle p = particles.get(i);
      if (largestFlow.mag() > 40) {
        p.setAcceleration(p.getAcceleration().mult(100));
      }
      p.run();
      
      if (p.isDead()) {
        particles.remove(i);
      }
      else if (p.shouldDestroy()) {
        p.destroy();
      }
    }
  }
}
