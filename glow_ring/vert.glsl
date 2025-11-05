#ifdef GL_ES
precision highp float;
precision highp int;
#endif

uniform mat4 transform;
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

varying vec4 vertColor;
varying vec2 vTexCoord;

void main() {
  gl_Position = transform * position;
  vertColor = color;
  vTexCoord = texCoord;
}
