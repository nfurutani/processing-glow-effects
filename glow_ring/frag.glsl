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
  for (int i=0; i<MAX; i++) {
    pos[i] = vec2(
      cos(3.1415 * 2.0 / float(MAX) * float(i) + t * 0.5),
      sin(3.1415 * 2.0 / float(MAX) * float(i) + t * 0.5)
    ) * 0.5;
  }

  // 座標修正部分
  vec2 uv = vTexCoord;                 // 0〜1のテクスチャ座標
  vec2 p = (uv - 0.5) * 2.0;           // -1〜1に変換
  p.x *= r.x / r.y;                    // アスペクト比補正

  vec3 col = vec3(0.0);

  for (int i=0; i<MAX; i++) {
    float h = float(i) / float(MAX);
    float b = 0.1 / length(pos[i] - p);
    b = pow(b, 2.1);
    col += hsb2rgb(vec3(h, 0.6, b));
  }

  gl_FragColor = vec4(col, 1.0);
}
