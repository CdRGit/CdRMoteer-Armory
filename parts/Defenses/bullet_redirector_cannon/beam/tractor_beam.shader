#include "./Data/base.shader"

struct VERT_OUTPUT2
{
	float4 location : SV_POSITION;
	float2 normalizedLocation : POSITION0;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};

VERT_OUTPUT2 vert(in VERT_INPUT input)
{
	VERT_OUTPUT2 output;
	output.location = mul(input.location, _transform);
	output.normalizedLocation.x = (output.location.x + 1) / 2;
	output.normalizedLocation.y = (-output.location.y + 1) / 2;
	output.color = input.color * _color;
	output.uv = input.uv;
	return output;
}

float _intensity;
float _length;
float _beamTime;

float _fullIntensityThickness;

Texture2D _displacement;
SamplerState _displacement_SS;
float _displacementStrength;
float _displacementSpeed;
float _displacementLength;

Texture2D _capturedBackBuffer;
SamplerState _capturedBackBuffer_SS;

PIX_OUTPUT pix(in VERT_OUTPUT2 input) : SV_TARGET
{
	float t = sin(input.uv.x / HALF_PI);
	float m = lerp(1, lerp(1, 1 / _fullIntensityThickness, _intensity), t);
	input.uv.y = ((input.uv.y * 2 - 1) * m + 1) / 2;

	float4 baseColor = _texture.Sample(_texture_SS, input.uv);
	baseColor.a *= min(input.uv.x * _length, min((1 - input.uv.x) * _length, 1));

	float2 displacementUV = input.uv;
	displacementUV.x += _beamTime * _displacementSpeed;
	float displacement = baseColor.a * input.color.a * _displacement.Sample(_displacement_SS, displacementUV).r;

#ifdef GTE_PS_4_0_level_9_3

	float2 dd = float2(ddx(input.uv.x), ddy(input.uv.x));
	dd = normalize(dd) / length(dd) * float2(ddx(input.normalizedLocation.x), ddy(input.normalizedLocation.y));
	float2 captureUV = input.normalizedLocation + _displacementStrength * dd * displacement * _intensity / _length;
	float4 capturedColor = _capturedBackBuffer.Sample(_capturedBackBuffer_SS, captureUV);

	float4 ret;
	ret.a = baseColor.a;
	baseColor *= input.color;
	float a = displacement;
	ret.rgb = baseColor.rgb * a + capturedColor.rgb * (1 - a);
	return ret;

#else

	baseColor.rgb *= input.color.rgb;
	baseColor.a = displacement;
	return baseColor;

#endif
}
