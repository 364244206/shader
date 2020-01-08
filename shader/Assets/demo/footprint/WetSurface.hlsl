   

//计算波纹的主函数
//float3 ComputeRipple(float4 uv, float t /*,  float w*/)
//{
//	float4 ripple = tex2D(_RippleTex, uv.zw);
//	// 将gb值限定在[-1,1]
//	ripple.gb = ripple.gb * 2.0 - 1.0;			
//	// dropFrac为正弦曲线的相位,取小数，结果限定在[0,1]
//	float dropFrac = frac(t + ripple.a);		
//	// timeFrac为正弦曲线的相位，只是改变了值域，让红色之外的位置不出现波纹
//	// [0,1] + [0, 1] - 1，将timeFrac限定在[-1,1]，那么红色以外(ripple.r=0)的地方，timeFrac<=0
//	float timeFrac = dropFrac + ripple.r - 1.0;	
//	// dropFactor为正弦曲线的振幅，随时间偏移时波纹由高到低，直接用1-dropFrac
//	// dropFrac越大，dropFactor越小，dropFrac为[0,1]，那么dropFactor为[1,0]
//	float dropFactor = 1 - saturate( dropFrac);  
//	//float dropFactor = saturate(0.2 + w * 0.8 - dropFrac);
//	// 9一个常量，理解为正弦函数的角速度w，控制正弦周期，单位距离内水波数量
//	// 将相位控制在[0-3*PI]，就是正弦曲线中，0到3PI之外的相位都是0，则无高度变化，那么中心区域在移动3PI之后，高度将持平。
//	float final = dropFactor * sin(clamp(timeFrac * 9.0, 0.0, 3.0) * PI) * _RainSurfaceRipple;
//	// 最终得到当前像素的法线方向，在切线空间下，(0,0,1)表示垂直于平面的法线
//	return float3(ripple.gb * final, 1);
//}


// perceptualRoughness粗糙度0-1 0为反射感强 1为无反射感
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

	// 潮湿度和下雨中心点的距离也有关联
	float posFactor = 1 - (distance(worldPos, _SceneCharacterNearestVolume.xyz) / _SceneCharacterNearestVolume.w);
	posFactor = saturate(posFactor);
	posFactor = pow(posFactor, 0.4);	// 0.4为边缘过渡的强弱

	// 当前高度和高度图对比，如果高度在高度图高度下面，则不潮湿
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

	float _FloodLevel1 = min(_GlobalSceneHumidness * 2.0f, 1);		// 缝隙积水深度不能超过1
	float _FloodLevel2 = _GlobalSceneHumidness * 1.0f;				// 积水深度为0-2
	// 涟漪波纹
  	float h = 1 - tex2D(_RainSurfaceWaterMaskTex, waterMaskUV).r;	// 凹凸高度图，红色的越高
	//float mask =  tex2D(_MaskTex, uv.xy).r;						// 水坑遮罩，白色越深,此项目将高度图和积水图合成为一张
	float mask = h;			// 水坑遮罩，白色越深
	// 水深度，用高度图和水深图中获取当前水深等级
	float2 waterLevel;
	// waterLevel.x表示间隙积水深度，取最小深度，如果外部设置深度很小，则取外界深度，如果外界设置深度很大，则取贴图深度
	waterLevel.x = min(_FloodLevel1, 1.0 - h);	
	// aterLevel.y 表示水坑的积水系数。mask越大，积水越深
	waterLevel.y = saturate((_FloodLevel2 - mask) * 4.0f);	// 系数2是让水坑过渡更明显	
	// 当前像素的积水强度 这两者选择最大的，间隙积水比水坑积水更高的时候，选择间隙的积水系数，否则选择水坑的积水系数。
	float accumulatedWater = max(waterLevel.x, waterLevel.y);
	// 暂时圆形波纹由特效制作，不需要在shader中实现	
	//float3 rippleNormal = ComputeRipple(uv, _Time.y * _RainSurfaceRippleSpeed);
				
	// 扰动法线
	float2 speed = _Time.x * float2(_RainSurfaceWaveSpeed, -_RainSurfaceWaveSpeed * 1.1f);
	// 移动法线,需要模式的UV采样，基于Y轴自上而下的，因为移植项目，重改UV量太大，暂不需要斜体流水
	float3 bump1 = UnpackNormal(tex2D(_RainSurfaceWaveTex, (waveUV + speed))).rgb;
	float3 bump2 = UnpackNormal(tex2D(_RainSurfaceWaveTex, (waveUV - speed))).rgb;	 
	float3 distuNormal = normalize(bump1 + bump2);

	// 波纹+扰动
	//distuNormal = (rippleNormal * 0.3f + distuNormal * 0.7f);
	// 自身法线和波纹法线取插值，水更越深，取波纹法线会更多。
	distuNormal = lerp(bumpNormal, distuNormal, accumulatedWater * posFactor);

	// 根据模型自身法线来处理波纹扰动，difference用于控制斜面的波纹扰动程度
	//float NdotT = dot(worldNormal, float3(0, 1, 0)) * 0.5f + 0.5f;					// 变换到0-1
	//float difference = 1 - saturate((1 - NdotT) * 50 * (1 - _GlobalSceneHumidness));	// t：无扰动-有扰动
	//distuNormal = lerp(bumpNormal, distuNormal, difference);

	// 优化上面的写法，模型下方到上方为[-1,1]，通过[1,0]得到[-2,1],锁定为[0,1]
	float difference = dot(worldNormal, float3(0, 1, 0)) - lerp(1, 0, _GlobalSceneHumidness);
	difference =  saturate(difference);
	distuNormal = lerp(bumpNormal, distuNormal, difference);

	// 返回给surface使用
	bumpNormal = distuNormal;

	// 计算后的法线转世界空间
	float3 b = normalize(half3(dot(t2w0, distuNormal), dot(t2w1, distuNormal), dot(t2w2, distuNormal)));
	// 反射，水越深，反射越大
	float3 R = reflect(-viewDir, b);
	// 使用系统的环境反射
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