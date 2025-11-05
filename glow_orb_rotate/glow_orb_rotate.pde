PShader glow;
PImage centerImage;

void setup() {
  size(800, 800, P2D);
  pixelDensity(1);
  noStroke();

  glow = loadShader("rotate_frag.glsl", "rotate_vert.glsl");

  // 中心に配置する画像を読み込む
  centerImage = loadImage("data/img_nobg.png");
  if (centerImage == null) {
    println("ERROR: Could not load img_nobg.png");
  }
}

void draw() {
  // シェーダーで背景を描画
  shader(glow);
  glow.set("t", float(frameCount));
  glow.set("r", float(width), float(height));

  // 中心画像をシェーダーに渡す
  if (centerImage != null) {
    glow.set("centerImage", centerImage);
    glow.set("imgScale", 0.3);  // 画像のスケール
    glow.set("imgAspect", float(centerImage.width) / float(centerImage.height));  // 画像のアスペクト比
  }

  rectMode(CORNER);
  rect(0, 0, width, height);

  resetShader();
}
