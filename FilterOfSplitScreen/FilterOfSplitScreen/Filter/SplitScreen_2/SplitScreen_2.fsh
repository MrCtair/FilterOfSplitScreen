precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

void main (void) {
    vec2 uv = TextureCoordsVarying.xy;
    if (uv.y >= 0.0 && uv.y <= 0.5) {
        uv.y = uv.y + 0.25;
    }else{
        uv.y = uv.y - 0.25;
    }
    gl_FragColor = texture2D(Texture, uv);
}
