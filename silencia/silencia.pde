// Silencia - Snow Particles Morphing to Logo
// パーティクルシステムで雪を表現し、ロゴにモーフィング

ArrayList<Particle> particles;
PImage logo;
PImage background_img;
ArrayList<PVector> logoPoints;
boolean snowing = false; // 雪が降っているか
boolean morphing = false;
float morphProgress = 0;

void setup() {
  size(1200, 800);
  pixelDensity(1); // 高解像度ディスプレイでの座標ずれを防ぐ

  // 背景画像を読み込む
  background_img = loadImage("background.png");
  if (background_img != null) {
    // 縦横比を維持して高さを画面の高さに合わせる
    background_img.resize(0, height);
    println("Background loaded successfully: " + background_img.width + "x" + background_img.height);
  }

  // ロゴ画像を読み込む
  logo = loadImage("logo.png");

  // 画像の読み込みを確認
  if (logo == null) {
    println("ERROR: Could not load logo.png");
    println("Please make sure logo.png is in the data folder");
    exit();
    return;
  }

  println("Logo loaded successfully: " + logo.width + "x" + logo.height);

  // ロゴをリサイズして画面に収まるようにする
  float targetHeight = height * 0.6; // 画面高さの60%
  float scale = targetHeight / logo.height;
  int newWidth = int(logo.width * scale);
  int newHeight = int(logo.height * scale);
  logo.resize(newWidth, newHeight);
  println("Logo resized to: " + logo.width + "x" + logo.height);

  // ロゴのピクセルから目標位置を抽出（パーティクル初期化の前に）
  extractLogoPoints();

  // パーティクルリストを初期化（空の状態で開始）
  particles = new ArrayList<Particle>();

  println("Setup complete. Press 'S' to start snowing.");
}

void draw() {
  // 背景を描画
  if (background_img != null) {
    // 背景を中央に配置
    float bgX = (width - background_img.width) / 2;
    float bgY = (height - background_img.height) / 2;

    // 余白部分を塗りつぶし
    background(0);

    // 背景画像を描画
    image(background_img, bgX, bgY);
  } else {
    background(240, 245, 250); // フォールバック背景
  }

  // モーフィング進行度を更新
  if (morphing) {
    morphProgress += 0.01;
    if (morphProgress >= 1.0) {
      morphProgress = 1.0;
    }
  }

  // すべてのパーティクルを更新・描画
  for (Particle p : particles) {
    p.update();
    p.display();
  }

  // 情報表示
  fill(255);
  textAlign(LEFT);
  textSize(16);
  if (!snowing) {
    text("Press 'S' to start snowing", 20, 30);
  } else if (!morphing) {
    text("Press SPACE to start morphing", 20, 30);
  }
  text("Press 'R' to reset", 20, 50);
  text("Particles: " + particles.size(), 20, 70);
  if (morphing) {
    text("Morphing: " + nf(morphProgress * 100, 0, 1) + "%", 20, 90);
  }
}

void keyPressed() {
  // Sキーで雪を開始
  if (key == 's' || key == 'S') {
    if (!snowing) {
      startSnowing();
    }
  }
  // スペースキーでモーフィング開始
  if (key == ' ') {
    if (snowing && !morphing) {
      morphing = true;
      morphProgress = 0;
    }
  }
  // Rキーでリセット
  if (key == 'r' || key == 'R') {
    reset();
  }
}

void startSnowing() {
  snowing = true;
  particles.clear();
  // 各ロゴポイントに対して1つのパーティクルを作成
  for (int i = 0; i < logoPoints.size(); i++) {
    PVector targetPoint = logoPoints.get(i);
    particles.add(new Particle(random(width), random(-500, 0), targetPoint, i));
  }
  println("Snowing started. Particles created: " + particles.size());
}

void reset() {
  snowing = false;
  morphing = false;
  morphProgress = 0;
  particles.clear();
  println("Reset complete. Press 'S' to start snowing.");
}

// ロゴ画像から黒いピクセルの位置を抽出
void extractLogoPoints() {
  logoPoints = new ArrayList<PVector>();

  if (logo == null) {
    println("ERROR: Logo is null in extractLogoPoints");
    return;
  }

  logo.loadPixels();

  // ロゴを画面中央に配置するためのオフセット
  float logoX = (width - logo.width) / 2;
  float logoY = (height - logo.height) / 2;

  // 画像をサンプリング（全ピクセルを取得して角を綺麗に）
  int step = 1; // ステップを1にして全ピクセルをサンプリング
  for (int y = 0; y < logo.height; y += step) {
    for (int x = 0; x < logo.width; x += step) {
      int index = x + y * logo.width;
      color c = logo.pixels[index];

      // 黒に近い色（ロゴの部分）を抽出
      if (brightness(c) < 50) {
        logoPoints.add(new PVector(logoX + x, logoY + y));
      }
    }
  }

  println("Logo points extracted: " + logoPoints.size());

  if (logoPoints.size() == 0) {
    println("WARNING: No logo points found. Trying with higher brightness threshold...");
    // もう一度、より高い閾値で試す
    for (int y = 0; y < logo.height; y += step) {
      for (int x = 0; x < logo.width; x += step) {
        int index = x + y * logo.width;
        color c = logo.pixels[index];

        // より明るい範囲まで抽出
        if (brightness(c) < 128) {
          logoPoints.add(new PVector(logoX + x, logoY + y));
        }
      }
    }
    println("Logo points with higher threshold: " + logoPoints.size());
  }
}

class Particle {
  PVector pos;
  PVector vel;
  PVector target;
  float size;
  float alpha;
  int id;

  Particle(float x, float y, PVector targetPoint, int particleId) {
    pos = new PVector(x, y);
    vel = new PVector(random(-0.5, 0.5), random(1, 3));
    size = 4; // サイズを小さくして角を綺麗に
    alpha = 255;
    target = targetPoint.copy();
    id = particleId;
  }

  void update() {
    if (!morphing) {
      // 雪として降る
      pos.add(vel);

      // 左右に揺れる
      pos.x += sin(frameCount * 0.01 + pos.y) * 0.5;

      // 画面下に到達したら上に戻す
      if (pos.y > height + 10) {
        pos.y = -10;
        pos.x = random(width);
      }

      // 画面外に出たら反対側に
      if (pos.x < -10) pos.x = width + 10;
      if (pos.x > width + 10) pos.x = -10;

    } else {
      // ロゴにモーフィング
      if (morphProgress >= 1.0) {
        // モーフィング完了後は目標位置に完全固定
        pos.set(target);
        vel.set(0, 0);
      } else {
        // モーフィング中
        PVector desired = PVector.sub(target, pos);
        desired.mult(0.05);

        // イージング
        float easedProgress = easeInOutCubic(morphProgress);
        vel.lerp(desired, easedProgress);
        pos.add(vel);
      }
    }
  }

  void display() {
    noStroke();

    if (!morphing || morphProgress < 0.3) {
      // 雪として描画（白・不透明）
      fill(255);
    } else {
      // ロゴとして描画（黒）
      float colorMix = map(morphProgress, 0.3, 1.0, 0, 1);
      colorMix = constrain(colorMix, 0, 1);
      float r = lerp(255, 0, colorMix);
      float g = lerp(255, 0, colorMix);
      float b = lerp(255, 0, colorMix);
      fill(r, g, b);
    }

    rectMode(CENTER);
    rect(pos.x, pos.y, size, size);
  }
}

// イージング関数
float easeInOutCubic(float t) {
  if (t < 0.5) {
    return 4 * t * t * t;
  } else {
    float f = 2 * t - 2;
    return 0.5 * f * f * f + 1;
  }
}
