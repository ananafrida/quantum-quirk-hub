/*How to run this project:
1. Plug the ADAFruit playground express board through the USB
2. Install and open the arduino IDE 
3. The IDE, go to Tools->Board->Arduino AVR Boards->ADAFruit Circuit Playground
4. Then go to Tools->Board->Port->COM3. Thus, you are done setting the board and port.
5. Click on “Upload” a sketch
6. Open the processing code and run it AND simulation window will show up
7. You are all set!
*/

import processing.serial.*;
import peasy.*;

ArrayList<Shape3D> shapes;  // List to store 3D shapes
ArrayList<Particle> particles;  // List to store particles
Slider speedSlider;  // Slider for controlling shape speed
PeasyCam cam;  // PeasyCam object for easy 3D camera control

Serial myPort;  // Create object from Serial class
float lightValue;  // Variable to store light intensity from Arduino

void setup() {
  noStroke();
  size(800, 600, P3D);

  // Initialize PeasyCam with a distance from the center
  cam = new PeasyCam(this, width/2.0, height/2.0, 0, 500);

  // Initialize Serial communication with Arduino
  myPort = new Serial(this, Serial.list()[0], 9600);

  // Initialize lists
  shapes = new ArrayList<Shape3D>();
  particles = new ArrayList<Particle>();

  // Create a speed slider at the top right corner
  speedSlider = new Slider(width - 150, 20, 100, 10, 1, 5, 2); // Parameters: x, y, width, height, minValue, maxValue, initialValue
}

void draw() {
  background(0);
  // Set background color to dark

  // Read data from Arduino if available
  if (myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      String[] tokens = split(inString, ' ');

      // Check for tap event
      if (tokens.length >= 2 && tokens[0].equals("Tap!")) {
        // Create a new Shape3D object at a random position
        shapes.add(new Shape3D(random(10, width - 10), random(10, height - 10)));

        // Extract tap event integer
        String tapEventString = tokens[1].replace("\n", "");  // Remove newline character if present
        int tapEvent = Integer.parseInt(tapEventString);
        println("Tap Event: " + tapEvent);
      }
      // Check for light event
      else if (tokens.length >= 2 && tokens[0].equals("Light!")) {
        // Extract the light value from the second token
        lightValue = float(tokens[1]);
        println("Light Value: " + lightValue);
      }
    }
  }

  // Update and display particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle particle = particles.get(i);
    particle.update();
    particle.display();

    if (particle.isDead()) {
      particles.remove(i);
    }
  }

  // Update and display shapes with the current speed from the slider
  speedSlider.update(); // Update the slider state
  float currentSpeed = speedSlider.getValue();

  for (Shape3D shape : shapes) {
    shape.setSpeed(currentSpeed);
    shape.update();
    shape.display();
  }
}

// Particle class
class Particle {
  PVector position;
  PVector velocity;
  int lifespan = 255;

  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = new PVector(random(-2, 2), random(-2, 2));
  }

  void update() {
    position.add(velocity);
    lifespan -= 2; // Gradually decrease lifespan
  }

  void display() {
    noStroke();
    fill(255, lifespan);
    ellipse(position.x, position.y, 8, 8);
  }

  boolean isDead() {
    return lifespan <= 0;
  }
}

class Shape3D {
  float x, y, z;
  float size;
  float xSpeed, ySpeed;
  int type; // 0: sphere, 1: cube
  color shapeColor;
  float speedMultiplier = 1.0; // Adjust this multiplier to control the impact of the slider on shape speed

  Shape3D(float x, float y) {
    this.x = x;
    this.y = y;
    this.z = 0;
    this.size = 40;
    this.type = int(random(2)); // Randomly choose a shape type
    this.xSpeed = lightValue / 10;
    this.ySpeed = lightValue / 10;
    this.shapeColor = color(random(255), random(255), random(255)); // Random color
  }

  void setSpeed(float newSpeed) {
    speedMultiplier = newSpeed;
  }

  void update() {
    // Check for collision with walls
    if (x < 0 || x > width) {
      xSpeed *= -1;
      handleCollision();
    }

    if (y < 0 || y > height) {
      ySpeed *= -1;
      handleCollision();
    }

    // Check for collision with other shapes
    for (Shape3D other : shapes) {
      if (other != this) {
        float distance = dist(x, y, other.x, other.y);
        float minDist = size/2 + other.size/2;
        if (distance < minDist) {
          xSpeed *= -1;
          ySpeed *= -1;
          handleCollision();
        }
      }
    }

    // Update position
    x += xSpeed * speedMultiplier; // Apply the speed multiplier
    y += ySpeed * speedMultiplier;
  }

  void display() {
    pushMatrix();
    translate(x, y, z);
    rotateX(frameCount * 0.01);
    rotateY(frameCount * 0.01);

    fill(shapeColor);

    switch(type) {
    case 0:
      drawSphere();
      break;
    case 1:
      drawCube();
      break;
    }

    popMatrix();
  }

  void drawSphere() {
    lights();
    sphere(size/2);
  }

  void drawCube() {
    lights();
    //stroke(3);
    rotateY(1.25);
    rotateX(-0.4);
    box(size);
  }

  void handleCollision() {
    // Change color on collision
    shapeColor = color(random(255), random(255), random(255));

    // Spawn particles on collision
    for (int i = 0; i < 10; i++) {
      particles.add(new Particle(x, y));
    }
  }
}

class Slider {
  float x, y;
  float sliderWidth, sliderHeight;
  float minValue, maxValue;
  float value;

  Slider(float x, float y, float sliderWidth, float sliderHeight, float minValue, float maxValue, float initialValue) {
    this.x = x;
    this.y = y;
    this.sliderWidth = sliderWidth;
    this.sliderHeight = sliderHeight;
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.value = constrain(initialValue, minValue, maxValue);
  }

  void display() {
    fill(150);
    rect(x, y, sliderWidth, sliderHeight);

    float mappedValue = map(value, minValue, maxValue, x, x + sliderWidth);
    fill(255);
    rect(mappedValue - 2, y - 5, 4, sliderHeight + 10);
  }

  float getValue() {
    float mappedValue = map(value, x, x + sliderWidth, minValue, maxValue);
    return constrain(mappedValue, minValue, maxValue);
  }

  boolean isOver() {
    return mouseX > x && mouseX < x + sliderWidth && mouseY > y && mouseY < y + sliderHeight;
  }

  void update() {
    if (isOver() && mousePressed) {
      float mappedValue = constrain(mouseX, x, x + sliderWidth);
      value = map(mappedValue, x, x + sliderWidth, minValue, maxValue);
    }
  }
}
