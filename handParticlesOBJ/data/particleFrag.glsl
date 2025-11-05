#ifdef GL_ES
precision mediump float;
#endif

varying vec4 vertColor;
varying vec3 vertPosition;

void main() {
  // DEBUG: Force red color to see if fragment shader is running
  gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}