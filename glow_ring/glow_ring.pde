PShader glow;

void setup() {
  size(800, 800, P2D);
  pixelDensity(1);
  noStroke();

  glow = loadShader("frag.glsl", "vert.glsl");
}

void draw() {
  // シェーダーで背景を描画
  shader(glow);
  glow.set("t", millis() / 1000.0);
  glow.set("r", float(width), float(height));

  rectMode(CORNER);
  rect(0, 0, width, height);

  resetShader();
}
