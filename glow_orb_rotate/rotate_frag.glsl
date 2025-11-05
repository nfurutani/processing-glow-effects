#ifdef GL_ES
precision highp float;
precision highp int;
#endif

uniform float t;
uniform vec2 r;
uniform sampler2D centerImage;
uniform float imgScale;
varying vec2 vTexCoord;

vec3 hsb2rgb(in vec3 c){
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                         6.0)-3.0)-1.0,
                    0.0,
                    1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb);
  return c.z * mix(vec3(1.0), rgb, c.y);
}

void main() {
  const int MAX = 40;
  vec3 pos3d[MAX];

  // 太陽系のような3D回転を計算（XY平面=水平面で回転）
  for (int i=0; i<MAX; i++) {
    // 軌道半径: 画像の外側を回るように十分に大きく維持 (0.8 -> 1.58)
    float orbitRadius = 0.8 + float(i) * 0.02;

    // ★ 修正箇所1: 回転速度の基本係数を 0.05 から 0.02 に減速
    float orbitSpeed = t * (0.02 / (1.0 + float(i) * 0.1));

    // Z軸（上下位置）のオフセット計算
    float angleBase = float(i) * 3.2; 
    // ★ 修正箇所2: 時間の除数を大きくして、上下運動を減速
    float heightOffset = sin(angleBase + t / 80.0) * 0.7; 
    heightOffset += cos(float(i) * 1.8 + t / 120.0) * 0.5;

    // XY平面（水平面）での回転角度
    float angle = orbitSpeed + float(i) * 0.5;

    // 3D座標を計算
    // x: 前後（奥行き）
    // y: 左右
    // z: 上下（高さ）
    pos3d[i] = vec3(
      cos(angle) * orbitRadius,    // x: 前後
      sin(angle) * orbitRadius,    // y: 左右
      heightOffset                 // z: 上下（動的）
    );
  }

  // 2D投影用の配列
  vec2 pos[MAX];
  for (int i=0; i<MAX; i++) {
    // 簡易的な3D→2D投影（透視投影風）
    float perspective = 1.0 / (1.5 + pos3d[i].x * 0.5);
    pos[i] = vec2(pos3d[i].y, pos3d[i].z) * perspective;
  }

  // 座標修正部分
  vec2 uv = vTexCoord;
  vec2 p = (uv - 0.5) * 2.0;
  p.x *= r.x / r.y;

  vec3 col = vec3(0.0);

  // 中心画像のUV座標を計算（アスペクト比調整なし、サイズ2.0倍）
  vec2 centerP = (vTexCoord - 0.5) * 2.0;
  vec2 centerUV = centerP / (imgScale * 2.0);
  centerUV = centerUV * 0.5 + 0.5;

  // 画像の範囲内かチェックして色を取得
  vec4 imgColor = vec4(0.0);
  bool hasImage = false;
  if (centerUV.x >= 0.0 && centerUV.x <= 1.0 && centerUV.y >= 0.0 && centerUV.y <= 1.0) {
    imgColor = texture2D(centerImage, centerUV);
    if (imgColor.a > 0.01) {
      hasImage = true;

      // エッジからの距離を計算（0.0=中心、1.0=エッジ）
      vec2 toEdge = abs(centerUV - 0.5) * 2.0;
      float edgeDist = max(toEdge.x, toEdge.y);

      // 画像のアルファ値に基づいてエッジの柔らかさを調整
      float alphaEdge = smoothstep(0.0, 0.3, imgColor.a);

      // エッジに向かって暗くする（グローエフェクト）
      float edgeFade = 1.0 - smoothstep(0.6, 1.0, edgeDist);
      edgeFade = mix(0.7, 1.0, edgeFade); // 完全には暗くしない

      // 画像の色にエッジフェードとオレンジ系の環境光を適用
      vec3 ambientGlow = vec3(0.1, 0.05, 0.0); // 微かなオレンジの環境光
      col = imgColor.rgb * edgeFade + ambientGlow * (1.0 - alphaEdge) * 0.3;
    }
  }

  // 各orbを描画（白熱球のような色 + 3D効果）
  for (int i=0; i<MAX; i++) {
    float dist = length(pos[i] - p);

    // 奥行きによるサイズ調整（手前は大きく、奥は小さく）
    float depth = pos3d[i].x;

    float sizeScale = 1.0 / (1.5 + depth * 0.5);

    float b = (0.06 * sizeScale) / dist;
    b = pow(b, 2.1); 

    // 白熱球の色: 中心は白、外側はオレンジ〜赤
    vec3 incandescentColor;
    if (b > 0.8) {
      incandescentColor = vec3(1.0, 1.0, 1.0);
    } else if (b > 0.3) {
      float t_col = (b - 0.3) / 0.5;
      incandescentColor = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 1.0, 1.0), t_col);
    } else {
      float t_col = b / 0.3;
      incandescentColor = mix(vec3(1.0, 0.3, 0.0), vec3(1.0, 0.9, 0.3), t_col);
    }
    
    // 描画ロジック (回り込みを維持)
    if (!hasImage) {
        // 画像がない場合は、前後関係なく描画（奥のオーブは暗くする）
        if (depth > 0.0) {
            col += incandescentColor * b * 0.7; 
        } else {
            col += incandescentColor * b;
        }
    } else {
        // 画像がある場合
        if (depth < 0.0) {
            // 手前のオーブは画像の上に描画
            col += incandescentColor * b;
        } 
        // depth > 0.0 (奥のオーブ) の場合、col に何も加算せず、画像の下（奥）に描画
    }
  }

  gl_FragColor = vec4(col, 1.0);
}