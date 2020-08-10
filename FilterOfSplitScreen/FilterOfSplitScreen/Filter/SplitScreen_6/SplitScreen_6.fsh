
precision highp float;
uniform sampler2D Texture;
varying highp vec2 TextureCoordsVarying;

void main (void) {
    vec2 uv = TextureCoordsVarying.xy;
    if (uv.x < 0.5) {
        uv.x = uv.x + 0.25;
    }else{
        uv.x = uv.x - 0.25;
    }
    
    if (uv.y < 1.0 / 3.0) {
        uv.y = uv.y + 1.0 / 3.0;
    } else if (uv.y > 2.0 / 3.0){
        uv.y = uv.y - 1.0 / 3.0;
    }
    
    gl_FragColor = texture2D(Texture, uv);
}
