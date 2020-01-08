   

//���㲨�Ƶ�������
//float3 ComputeRipple(float4 uv, float t /*,  float w*/)
//{
//	float4 ripple = tex2D(_RippleTex, uv.zw);
//	// ��gbֵ�޶���[-1,1]
//	ripple.gb = ripple.gb * 2.0 - 1.0;			
//	// dropFracΪ�������ߵ���λ,ȡС��������޶���[0,1]
//	float dropFrac = frac(t + ripple.a);		
//	// timeFracΪ�������ߵ���λ��ֻ�Ǹı���ֵ���ú�ɫ֮���λ�ò����ֲ���
//	// [0,1] + [0, 1] - 1����timeFrac�޶���[-1,1]����ô��ɫ����(ripple.r=0)�ĵط���timeFrac<=0
//	float timeFrac = dropFrac + ripple.r - 1.0;	
//	// dropFactorΪ�������ߵ��������ʱ��ƫ��ʱ�����ɸߵ��ͣ�ֱ����1-dropFrac
//	// dropFracԽ��dropFactorԽС��dropFracΪ[0,1]����ôdropFactorΪ[1,0]
//	float dropFactor = 1 - saturate( dropFrac);  
//	//float dropFactor = saturate(0.2 + w * 0.8 - dropFrac);
//	// 9һ�����������Ϊ���Һ����Ľ��ٶ�w�������������ڣ���λ������ˮ������
//	// ����λ������[0-3*PI]���������������У�0��3PI֮�����λ����0�����޸߶ȱ仯����ô�����������ƶ�3PI֮�󣬸߶Ƚ���ƽ��
//	float final = dropFactor * sin(clamp(timeFrac * 9.0, 0.0, 3.0) * PI) * _RainSurfaceRipple;
//	// ���յõ���ǰ���صķ��߷��������߿ռ��£�(0,0,1)��ʾ��ֱ��ƽ��ķ���
//	return float3(ripple.gb * final, 1);
//}


// perceptualRoughness�ֲڶ�0-1 0Ϊ�����ǿ 1Ϊ�޷����
half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

#if !defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#else
    half3 irradiance = encodedIrradiance.rbg;
#endif

    return irradiance;
#endif // GLOSSY_REFLECTIONS

    return _GlossyEnvironmentColor.rgb;
}

uniform sampler2D _SceneHeightMap;
uniform float4 _SceneHeightMapCenterPosition;
uniform float _MaxHeight;
uniform float _SceneHeightMapSize;
uniform float _SceneHeightMapPixelPreMeter;

float3 ComputeWetSurface(float2 uv0, float3 worldNormal, float3 worldPos, float3 viewDir, float3 t2w0, float3 t2w1, float3 t2w2, inout float3 bumpNormal)
{
	float2 waterMaskUV = uv0 * _RainSurfaceWaterMaskTex_ST.xy + _RainSurfaceWaterMaskTex_ST.zw;
	float2 waveUV = uv0 * _RainSurfaceWaveTex_ST.xy + _RainSurfaceWaveTex_ST.zw;

	_GlobalSceneHumidness = clamp(_GlobalSceneHumidness, 0, 0.9);

	// ��ʪ�Ⱥ��������ĵ�ľ���Ҳ�й���
	float posFactor = 1 - (distance(worldPos, _SceneCharacterNearestVolume.xyz) / _SceneCharacterNearestVolume.w);
	posFactor = saturate(posFactor);
	posFactor = pow(posFactor, 0.4);	// 0.4Ϊ��Ե���ɵ�ǿ��

	// ��ǰ�߶Ⱥ͸߶�ͼ�Աȣ�����߶��ڸ߶�ͼ�߶����棬�򲻳�ʪ
	float heightFactor = 1;
	float3 deltaPos = worldPos - _SceneHeightMapCenterPosition.xyz;
	float deltaX = deltaPos.x * _SceneHeightMapPixelPreMeter / _SceneHeightMapSize;
	float deltaY = deltaPos.z * _SceneHeightMapPixelPreMeter / _SceneHeightMapSize;
	float2 uv = float2(0.5f + deltaX, 0.5f + deltaY);
	
	float2 heightMapInfo = tex2D(_SceneHeightMap, uv);
	float rainHeight = heightMapInfo.x * _MaxHeight - _MaxHeight * 0.5f;
	if (rainHeight > worldPos.y + 1 && heightMapInfo.y <= 0.5f)
	{
		heightFactor -= 0.2;
	}
	
	float size = 0.2 / _SceneHeightMapSize;
	heightMapInfo = tex2D(_SceneHeightMap, uv + float2(-1, -1) * size);
	rainHeight = heightMapInfo.x * _MaxHeight - _MaxHeight * 0.5f;
	if (rainHeight > worldPos.y + 1 && heightMapInfo.y <= 0.5f)
	{
		heightFactor -= 0.1;
	}

	heightMapInfo = tex2D(_SceneHeightMap, uv + float2(-1, 1) * size);
	rainHeight = heightMapInfo.x * _MaxHeight - _MaxHeight * 0.5f;
	if (rainHeight > worldPos.y + 1 && heightMapInfo.y <= 0.5f)
	{
		heightFactor -= 0.1;
	}

	heightMapInfo = tex2D(_SceneHeightMap, uv + float2(1, 1) * size);
	rainHeight = heightMapInfo.x * _MaxHeight - _MaxHeight * 0.5f;
	if (rainHeight > worldPos.y + 1 && heightMapInfo.y <= 0.5f)
	{
		heightFactor -= 0.1;
	}

	heightMapInfo = tex2D(_SceneHeightMap, uv + float2(1, -1) * size);
	rainHeight = heightMapInfo.x * _MaxHeight - _MaxHeight * 0.5f;
	if (rainHeight > worldPos.y + 1 && heightMapInfo.y <= 0.5f)
	{
		heightFactor -= 0.1;
	}
	posFactor *=  heightFactor;

	float _FloodLevel1 = min(_GlobalSceneHumidness * 2.0f, 1);		// ��϶��ˮ��Ȳ��ܳ���1
	float _FloodLevel2 = _GlobalSceneHumidness * 1.0f;				// ��ˮ���Ϊ0-2
	// ��������
  	float h = 1 - tex2D(_RainSurfaceWaterMaskTex, waterMaskUV).r;	// ��͹�߶�ͼ����ɫ��Խ��
	//float mask =  tex2D(_MaskTex, uv.xy).r;						// ˮ�����֣���ɫԽ��,����Ŀ���߶�ͼ�ͻ�ˮͼ�ϳ�Ϊһ��
	float mask = h;			// ˮ�����֣���ɫԽ��
	// ˮ��ȣ��ø߶�ͼ��ˮ��ͼ�л�ȡ��ǰˮ��ȼ�
	float2 waterLevel;
	// waterLevel.x��ʾ��϶��ˮ��ȣ�ȡ��С��ȣ�����ⲿ������Ⱥ�С����ȡ�����ȣ�������������Ⱥܴ���ȡ��ͼ���
	waterLevel.x = min(_FloodLevel1, 1.0 - h);	
	// aterLevel.y ��ʾˮ�ӵĻ�ˮϵ����maskԽ�󣬻�ˮԽ��
	waterLevel.y = saturate((_FloodLevel2 - mask) * 4.0f);	// ϵ��2����ˮ�ӹ��ɸ�����	
	// ��ǰ���صĻ�ˮǿ�� ������ѡ�����ģ���϶��ˮ��ˮ�ӻ�ˮ���ߵ�ʱ��ѡ���϶�Ļ�ˮϵ��������ѡ��ˮ�ӵĻ�ˮϵ����
	float accumulatedWater = max(waterLevel.x, waterLevel.y);
	// ��ʱԲ�β�������Ч����������Ҫ��shader��ʵ��	
	//float3 rippleNormal = ComputeRipple(uv, _Time.y * _RainSurfaceRippleSpeed);
				
	// �Ŷ�����
	float2 speed = _Time.x * float2(_RainSurfaceWaveSpeed, -_RainSurfaceWaveSpeed * 1.1f);
	// �ƶ�����,��Ҫģʽ��UV����������Y�����϶��µģ���Ϊ��ֲ��Ŀ���ظ�UV��̫���ݲ���Ҫб����ˮ
	float3 bump1 = UnpackNormal(tex2D(_RainSurfaceWaveTex, (waveUV + speed))).rgb;
	float3 bump2 = UnpackNormal(tex2D(_RainSurfaceWaveTex, (waveUV - speed))).rgb;	 
	float3 distuNormal = normalize(bump1 + bump2);

	// ����+�Ŷ�
	//distuNormal = (rippleNormal * 0.3f + distuNormal * 0.7f);
	// �����ߺͲ��Ʒ���ȡ��ֵ��ˮ��Խ�ȡ���Ʒ��߻���ࡣ
	distuNormal = lerp(bumpNormal, distuNormal, accumulatedWater * posFactor);

	// ����ģ�����������������Ŷ���difference���ڿ���б��Ĳ����Ŷ��̶�
	//float NdotT = dot(worldNormal, float3(0, 1, 0)) * 0.5f + 0.5f;					// �任��0-1
	//float difference = 1 - saturate((1 - NdotT) * 50 * (1 - _GlobalSceneHumidness));	// t�����Ŷ�-���Ŷ�
	//distuNormal = lerp(bumpNormal, distuNormal, difference);

	// �Ż������д����ģ���·����Ϸ�Ϊ[-1,1]��ͨ��[1,0]�õ�[-2,1],����Ϊ[0,1]
	float difference = dot(worldNormal, float3(0, 1, 0)) - lerp(1, 0, _GlobalSceneHumidness);
	difference =  saturate(difference);
	distuNormal = lerp(bumpNormal, distuNormal, difference);

	// ���ظ�surfaceʹ��
	bumpNormal = distuNormal;

	// �����ķ���ת����ռ�
	float3 b = normalize(half3(dot(t2w0, distuNormal), dot(t2w1, distuNormal), dot(t2w2, distuNormal)));
	// ���䣬ˮԽ�����Խ��
	float3 R = reflect(-viewDir, b);
	// ʹ��ϵͳ�Ļ�������
	return GlossyEnvironmentReflection(R, 0) * _GlobalSceneHumidness * difference * clamp(accumulatedWater * difference, 0.3, 1) * posFactor;
}

// V/F			
//float3 ComputeWetSurface(float4 uv, float3 objNormal, float3 viewDir, float4 objTangent, inout float3 bumpNormal)
//{
//	float3 worldNormal = TransformObjectToWorldNormal(objNormal);  
//	float3 worldTangent = TransformObjectToWorldDir(objTangent.xyz);  
//	float3 worldBinormal = cross(worldNormal, worldTangent) * objTangent.w; 
				 
//	float3 TtoW0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);  
//	float3 TtoW1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);  
//	float3 TtoW2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);  
				
//	float3 tempBumpNormal = bumpNormal;
//	//float tmepGloss = gloss;
//	float3 refl = ComputeWetSurface(uv,worldNormal, viewDir, TtoW0, TtoW1, TtoW2, tempBumpNormal);
//	bumpNormal = tempBumpNormal;
//	//gloss =  tmepGloss;

//	return 	refl;
//}