#ifdef GL_ES
precision highp float;
precision highp int;
#endif

uniform float t;
uniform vec2 r;
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
  const int MAX = 24;
  vec2 pos[MAX];

  // p5.jsのコードを元にorb位置を計算
  for (int i=0; i<MAX; i++) {
    float angle1 = 3.1415 * 29.0 / float(MAX) * float(i) + t / (300.0 + 20.0 * sin(t / 100.0));
    float angle2 = 3.1415 * 2.0 / float(MAX) * float(i) + t / 60.0;

    pos[i] = vec2(
      cos(angle1),
      sin(angle2)
    ) * 0.6;
  }

  // 座標修正部分
  vec2 uv = vTexCoord;
  vec2 p = (uv - 0.5) * 2.0;
  p.x *= r.x / r.y;

  vec3 col = vec3(0.0);

  // 各orbを描画（白熱球のような色）
  for (int i=0; i<MAX; i++) {
    float dist = length(pos[i] - p);
    float b = 0.1 / dist;
    b = pow(b, 2.1);

    // 白熱球の色: 中心は白、外側はオレンジ〜赤
    // 距離に応じて色を変化
    vec3 incandescentColor;
    if (b > 0.8) {
      // 中心部: 白
      incandescentColor = vec3(1.0, 1.0, 1.0);
    } else if (b > 0.3) {
      // 中間部: 黄色〜白
      float t = (b - 0.3) / 0.5;
      incandescentColor = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 1.0, 1.0), t);
    } else {
      // 外側: オレンジ〜黄色
      float t = b / 0.3;
      incandescentColor = mix(vec3(1.0, 0.3, 0.0), vec3(1.0, 0.9, 0.3), t);
    }

    col += incandescentColor * b;
  }

  gl_FragColor = vec4(col, 1.0);
}
