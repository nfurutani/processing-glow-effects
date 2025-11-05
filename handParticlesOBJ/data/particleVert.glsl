#define PROCESSING_POINT_SHADER

uniform mat4 transform;
uniform float u_time;

attribute vec4 position;
attribute vec4 color;

varying vec4 vertColor;
varying vec3 vertPosition;

void main() {
  vec3 pos = position.xyz;

  // Use u_time for simple animation (prevent compiler from removing it)
  pos.y += sin(u_time + pos.x * 0.1) * 0.5;

  gl_Position = transform * vec4(pos, 1.0);

  // CRITICAL: Set point size for point rendering (make it larger for testing)
  gl_PointSize = 5.0;

  // Pass data to fragment shader
  vertColor = vec4(1.0, 1.0, 1.0, 1.0);
  vertPosition = pos;
}