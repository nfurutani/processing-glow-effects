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

  // 各orbを描画
  for (int i=0; i<MAX; i++) {
    float h = 1.0 / float(MAX) * float(i);
    float s = 0.6;
    float b = 0.1 / length(pos[i] - p);
    b = pow(b, 2.1);
    col += hsb2rgb(vec3(h, s, b));
  }

  gl_FragColor = vec4(col, 1.0);
}
