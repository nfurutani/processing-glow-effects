// Hand particle effect using OBJ mesh
// Distributes particles across mesh surface

PShape handMesh;
PShape footMesh;
PShader particleShader;
PShape particleShape;
PVector[] positions1;  // First position set (hand mesh surface)
PVector[] positions2;  // Second position set (foot mesh surface)
int particleCount = 50000;  // Balanced density for good performance

float time = 0;
float meshScale = 1.0;
PVector meshCenter = new PVector();
float camDistance = 300;

void setup() {
  size(1200, 1200, P3D);
  pixelDensity(1);
  hint(ENABLE_STROKE_PURE);

  // Load hand OBJ file
  handMesh = loadShape("hand.obj");
  if (handMesh == null) {
    println("ERROR: Could not load hand.obj");
    exit();
    return;
  }
  println("Hand mesh loaded successfully");

  // Load foot OBJ file
  footMesh = loadShape("feet.obj");
  if (footMesh == null) {
    println("ERROR: Could not load feet.obj");
    exit();
    return;
  }
  println("Foot mesh loaded successfully");

  // Extract mesh data and distribute particles
  distributParticlesOnBothMeshes();

  println("Particles distributed: " + particleCount);

  // Load shader FIRST
  try {
    particleShader = loadShader("particleFrag.glsl", "particleVert.glsl");

    if (particleShader == null) {
      println("ERROR: Could not load shaders");
    } else {
      println("Shaders loaded successfully");
    }
  } catch (Exception e) {
    println("ERROR loading shaders:");
    println(e.getMessage());
    e.printStackTrace();
  }

  // Create PShape
  createParticleShape();
}

void createParticleShape() {
  particleShape = createShape();
  particleShape.beginShape(POINTS);

  for (int i = 0; i < particleCount; i++) {
    if (positions1[i] != null) {
      PVector p = positions1[i];
      particleShape.stroke(255);
      particleShape.vertex(p.x, p.y, p.z);
    }
  }

  particleShape.endShape();
}

void distributParticlesOnBothMeshes() {
  positions1 = new PVector[particleCount];
  positions2 = new PVector[particleCount];

  // Get vertices and faces from HAND mesh
  ArrayList<PVector> handVertices = new ArrayList<PVector>();
  ArrayList<int[]> handFaces = new ArrayList<int[]>();
  extractMeshData(handMesh, handVertices, handFaces);

  // Get vertices and faces from FOOT mesh
  ArrayList<PVector> footVertices = new ArrayList<PVector>();
  ArrayList<int[]> footFaces = new ArrayList<int[]>();
  extractMeshData(footMesh, footVertices, footFaces);

  println("Hand - Vertices: " + handVertices.size() + ", Faces: " + handFaces.size());
  println("Foot - Vertices: " + footVertices.size() + ", Faces: " + footFaces.size());

  // Calculate HAND bounding box
  PVector handMin = handVertices.get(0).copy();
  PVector handMax = handVertices.get(0).copy();
  for (PVector v : handVertices) {
    handMin.x = min(handMin.x, v.x);
    handMin.y = min(handMin.y, v.y);
    handMin.z = min(handMin.z, v.z);
    handMax.x = max(handMax.x, v.x);
    handMax.y = max(handMax.y, v.y);
    handMax.z = max(handMax.z, v.z);
  }
  PVector handCenter = PVector.add(handMin, handMax).mult(0.5);
  float handMaxDim = max(handMax.x - handMin.x, max(handMax.y - handMin.y, handMax.z - handMin.z));

  // Calculate FOOT bounding box
  PVector footMin = footVertices.get(0).copy();
  PVector footMax = footVertices.get(0).copy();
  for (PVector v : footVertices) {
    footMin.x = min(footMin.x, v.x);
    footMin.y = min(footMin.y, v.y);
    footMin.z = min(footMin.z, v.z);
    footMax.x = max(footMax.x, v.x);
    footMax.y = max(footMax.y, v.y);
    footMax.z = max(footMax.z, v.z);
  }
  PVector footCenter = PVector.add(footMin, footMax).mult(0.5);
  float footMaxDim = max(footMax.x - footMin.x, max(footMax.y - footMin.y, footMax.z - footMin.z));

  // Use the same scale for both
  float targetScale = 225.0;  // 1.5x bigger

  println("Hand center: " + handCenter + ", max dim: " + handMaxDim);
  println("Foot center: " + footCenter + ", max dim: " + footMaxDim);

  // Use hand mesh for face area calculation
  ArrayList<PVector> vertices = handVertices;
  ArrayList<int[]> faces = handFaces;

  if (faces.size() == 0) {
    println("No faces found in mesh!");
    // Fallback: use vertices directly
    for (int i = 0; i < particleCount; i++) {
      int idx = (int)random(vertices.size());
      positions1[i] = vertices.get(idx).copy();
      positions2[i] = vertices.get(idx).copy().add(randomOffset(5));
    }
    return;
  }

  // Calculate face areas for weighted sampling
  float[] faceAreas = new float[faces.size()];
  float totalArea = 0;

  for (int i = 0; i < faces.size(); i++) {
    int[] face = faces.get(i);
    if (face.length >= 3) {
      PVector v0 = vertices.get(face[0]);
      PVector v1 = vertices.get(face[1]);
      PVector v2 = vertices.get(face[2]);
      faceAreas[i] = triangleArea(v0, v1, v2);
      totalArea += faceAreas[i];
    }
  }

  // Calculate face areas for FOOT mesh
  float[] footFaceAreas = new float[footFaces.size()];
  float footTotalArea = 0;
  for (int i = 0; i < footFaces.size(); i++) {
    int[] face = footFaces.get(i);
    if (face.length >= 3) {
      PVector v0 = footVertices.get(face[0]);
      PVector v1 = footVertices.get(face[1]);
      PVector v2 = footVertices.get(face[2]);
      footFaceAreas[i] = triangleArea(v0, v1, v2);
      footTotalArea += footFaceAreas[i];
    }
  }

  // Distribute particles
  for (int i = 0; i < particleCount; i++) {
    // Position 1: Random point on HAND mesh
    int handFaceIdx = selectFaceByArea(faceAreas, totalArea);
    int[] handFace = faces.get(handFaceIdx);

    if (handFace.length >= 3) {
      PVector v0 = vertices.get(handFace[0]);
      PVector v1 = vertices.get(handFace[1]);
      PVector v2 = vertices.get(handFace[2]);

      float r1 = random(1);
      float r2 = random(1);
      if (r1 + r2 > 1) {
        r1 = 1 - r1;
        r2 = 1 - r2;
      }
      float r3 = 1 - r1 - r2;

      PVector p1 = new PVector();
      p1.x = v0.x * r1 + v1.x * r2 + v2.x * r3;
      p1.y = v0.y * r1 + v1.y * r2 + v2.y * r3;
      p1.z = v0.z * r1 + v1.z * r2 + v2.z * r3;
      // Center and scale HAND mesh to origin
      p1.sub(handCenter).mult(targetScale / handMaxDim);

      positions1[i] = p1;
    }

    // Position 2: Random point on FOOT mesh
    int footFaceIdx = selectFaceByArea(footFaceAreas, footTotalArea);
    int[] footFace = footFaces.get(footFaceIdx);

    if (footFace.length >= 3) {
      PVector v0 = footVertices.get(footFace[0]);
      PVector v1 = footVertices.get(footFace[1]);
      PVector v2 = footVertices.get(footFace[2]);

      float r1 = random(1);
      float r2 = random(1);
      if (r1 + r2 > 1) {
        r1 = 1 - r1;
        r2 = 1 - r2;
      }
      float r3 = 1 - r1 - r2;

      PVector p2 = new PVector();
      p2.x = v0.x * r1 + v1.x * r2 + v2.x * r3;
      p2.y = v0.y * r1 + v1.y * r2 + v2.y * r3;
      p2.z = v0.z * r1 + v1.z * r2 + v2.z * r3;
      // Center and scale FOOT mesh to origin
      p2.sub(footCenter).mult(targetScale / footMaxDim);

      positions2[i] = p2;
    }
  }
}

void extractMeshData(PShape shape, ArrayList<PVector> vertices, ArrayList<int[]> faces) {
  // Process shape recursively
  int childCount = shape.getChildCount();

  if (childCount > 0) {
    // Has children, recurse
    for (int i = 0; i < childCount; i++) {
      extractMeshData(shape.getChild(i), vertices, faces);
    }
  } else {
    // Leaf shape, extract vertices
    int vertCount = shape.getVertexCount();

    if (vertCount > 0) {
      int startIdx = vertices.size();

      // Add vertices
      for (int i = 0; i < vertCount; i++) {
        PVector v = shape.getVertex(i);
        vertices.add(v.copy());
      }

      // Create faces (triangles)
      // Assume the shape is made of triangles
      for (int i = 0; i < vertCount; i += 3) {
        if (i + 2 < vertCount) {
          int[] face = {startIdx + i, startIdx + i + 1, startIdx + i + 2};
          faces.add(face);
        }
      }
    }
  }
}

float triangleArea(PVector v0, PVector v1, PVector v2) {
  PVector a = PVector.sub(v1, v0);
  PVector b = PVector.sub(v2, v0);
  return a.cross(b).mag() * 0.5;
}

int selectFaceByArea(float[] areas, float totalArea) {
  float r = random(totalArea);
  float sum = 0;
  for (int i = 0; i < areas.length; i++) {
    sum += areas[i];
    if (r <= sum) return i;
  }
  return areas.length - 1;
}

PVector randomOffset(float magnitude) {
  return new PVector(
    random(-magnitude, magnitude),
    random(-magnitude, magnitude),
    random(-magnitude, magnitude)
  );
}

void draw() {
  time += 0.01;

  // Black background
  background(0);

  // Set wider field of view for 3D
  perspective(PI/3.0, float(width)/float(height), 1, 5000);

  // Camera setup - rotate around origin
  float camDist = 400;
  float camX = camDist * sin(time * 0.5);
  float camZ = camDist * cos(time * 0.5);

  camera(camX, 0, camZ,
         0, 0, 0,  // Look at the origin
         0, 1, 0);

  // Set rendering state for points
  stroke(255);
  strokeWeight(1.5);  // Smaller particles
  noFill();

  // Calculate morph factor (oscillates between 0 and 1) - faster speed
  float t = sin(time * 3.0) * 0.5 + 0.5;

  // Draw particles with morphing
  beginShape(POINTS);
  for (int i = 0; i < particleCount; i++) {
    if (positions1[i] != null && positions2[i] != null) {
      // Lerp between hand position and foot position
      PVector p = PVector.lerp(positions1[i], positions2[i], t);
      vertex(p.x, p.y, p.z);
    }
  }
  endShape();
}
