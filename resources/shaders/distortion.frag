
#ifdef GL_ES
precision mediump float;
#endif

uniform float u_time;
uniform vec2 u_resolution;
// change these values to 0.0 to turn off individual effects
float vertJerkOpt = 0.1;
float vertMovementOpt=0.001;
float bottomStaticOpt=0.3;
float scalinesOpt=0.3;
float rgbOffsetOpt=0.1;
float horzFuzzOpt=0.5;

// Noise generation functions borrowed from:
// https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

vec3 mod289(vec3 x){
    return x-floor(x*(1./289.))*289.;
}

vec2 mod289(vec2 x){
    return x-floor(x*(1./289.))*289.;
}

vec3 permute(vec3 x){
    return mod289(((x*34.)+1.)*x);
}

float snoise(vec2 v)
{
    const vec4 C=vec4(.211324865405187,// (3.0-sqrt(3.0))/6.0
    .366025403784439,// 0.5*(sqrt(3.0)-1.0)
    -.577350269189626,// -1.0 + 2.0 * C.x
    .024390243902439);// 1.0 / 41.0
    // First corner
    vec2 i=floor(v+dot(v,C.yy));
    vec2 x0=v-i+dot(i,C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1=(x0.x>x0.y)?vec2(1.,0.):vec2(0.,1.);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12=x0.xyxy+C.xxzz;
    x12.xy-=i1;

    // Permutations
    i=mod289(i);// Avoid truncation effects in permutation
    vec3 p=permute(permute(i.y+vec3(0.,i1.y,1.))
    +i.x+vec3(0.,i1.x,1.));

    vec3 m=max(.5-vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);
    m=m*m;
    m=m*m;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x=2.*fract(p*C.www)-1.;
    vec3 h=abs(x)-.5;
    vec3 ox=floor(x+.5);
    vec3 a0=x-ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m*=1.79284291400159-.85373472095314*(a0*a0+h*h);

    // Compute final noise value at P
    vec3 g;
    g.x=a0.x*x0.x+h.x*x0.y;
    g.yz=a0.yz*x12.xz+h.yz*x12.yw;
    return 130.*dot(m,g);
}

float staticV(vec2 uv){
    float staticHeight=snoise(vec2(9.,u_time*1.2+3.))*.3+5.;
    float staticAmount=snoise(vec2(1.,u_time*1.2-6.))*.1+.3;
    float staticStrength=snoise(vec2(-9.75,u_time*.6-3.))*2.+2.;
    return(1.-step(snoise(vec2(5.*pow(u_time,2.)+pow(uv.x*7.,1.2),pow((mod(u_time,100.)+100.)*uv.y*.3+3.,staticHeight))),staticAmount))*staticStrength;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 uv=texture_coords;

    float jerkOffset=(1.-step(snoise(vec2(u_time*1.3,5.)),.8))*.05;

    float fuzzOffset=snoise(vec2(u_time*15.,uv.y*80.))*.003;
    float largeFuzzOffset=snoise(vec2(u_time*1.,uv.y*25.))*.004;

    float vertMovementOn=(1.-step(snoise(vec2(u_time*.2,8.)),.4))*vertMovementOpt;
    float vertJerk=(1.-step(snoise(vec2(u_time*1.5,5.)),.6))*vertJerkOpt;
    float vertJerk2=(1.-step(snoise(vec2(u_time*5.5,5.)),.2))*vertJerkOpt;
    float yOffset=abs(sin(u_time)*4.)*vertMovementOn+vertJerk*vertJerk2*.3;
    float y=mod(uv.y+yOffset,1.);

    float xOffset=(fuzzOffset+largeFuzzOffset)*horzFuzzOpt;

    float staticVal=0.;

    for(float y=-1.;y<=1.;y+=1.){
        float maxDist=5./200.;
        float dist=y/200.;
        staticVal+=staticV(vec2(uv.x,uv.y+dist))*(maxDist-abs(dist))*1.5;
    }

    staticVal*=bottomStaticOpt;

    float red=Texel(texture,vec2(uv.x+xOffset-.01*rgbOffsetOpt,y)).r+staticVal;
    float green=Texel(texture,vec2(uv.x+xOffset,y)).g+staticVal;
    float blue=Texel(texture,vec2(uv.x+xOffset+.01*rgbOffsetOpt,y)).b+staticVal;

    vec3 final_color=vec3(red,green,blue);
    float scanline=sin(uv.y*800.)*.04*scalinesOpt;
    final_color-=scanline;

    return vec4(final_color,1.);
}
