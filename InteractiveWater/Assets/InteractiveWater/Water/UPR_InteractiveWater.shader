Shader "V/URP/InteractiveWaterShader"
{
    Properties
    {
		_MainColor("Main Color", Color) = (1, 1, 1, .5) 
		_MainTex ("Main Texture", 2D) = "white" {}
        _MainTexDistort("Main Texture Distort", Range(0,1)) = 0.1
		_NoiseTex("Wave Noise", 2D) = "white" {}
		_Speed("Wave Speed", Range(0,1)) = 0.5
		_Amount("Wave Amount", Range(0,10)) = 0.5
		_Height("Wave Height", Range(0,1)) = 0.5
		_Foam("Foamline Thickness", Range(0,3)) = 0.5
        _FoamColor("Foam Color", Color) = (1, 1, 1, .5) 
        _DistortStrength("Distort strength", Range(0,1)) = 0
        _Scale("Noise Scale", Range(0,1)) = 0.5
        _RippleColor("Ripple Color", Color) = (1, 1, 1, 1) 
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent+0"
        }
        
        Pass
        {
            Name "Pass"
            Tags 
            { 
                
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            #pragma multi_compile_instancing
            
            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"        
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
            half4 _MainColor;
            float _MainTexDistort;
            float _Speed;
            float _Amount;
            float _Height;
            float _Foam;
            half4 _FoamColor;
            float _DistortStrength;
            float _Scale;
            float3 _Position;
            float _OrthographicCamSize;
            half4 _RippleColor;
            CBUFFER_END
            
            Texture2D _MainTex;
            float4 _MainTex_ST;
            
            Texture2D _NoiseTex;
            float4 _NoiseTex_ST;

            Texture2D _GlobalEffectRT;

			// 贴图采样器
            SamplerState smp_Point_Repeat;

            // 顶点着色器的输入
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv :TEXCOORD0;
            };
            
            // 顶点着色器的输出
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv :TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

			// 将采样的深度贴图中的深度值转换为
            float GetLinearEyeDepth(float2 UV)
            {
                float depth = LinearEyeDepth(SampleSceneDepth(UV.xy), _ZBufferParams);
                return depth;
            }

            // 顶点着色器
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                // 采样噪声贴图
                float4 tex = SAMPLE_TEXTURE2D_LOD(_NoiseTex, smp_Point_Repeat, v.uv, 0);
                // 修改Mesh顶点坐标Y值
				v.positionOS.y += sin(_Time.z * _Speed + (v.positionOS.x * v.positionOS.z * _Amount * tex)) * _Height;
				// 计算裁剪空间位置
                o.positionCS = TransformObjectToHClip(v.positionOS);
                // 计算世界空间位置
                o.worldPos = TransformObjectToWorld(v.positionOS);
                // 计算UV值
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 计算屏幕空间位置(此处还没有进行齐次除法)
				o.screenPos = ComputeScreenPos(o.positionCS);

                return o;
            }

            // 片段着色器
            half4 frag(Varyings i) : SV_TARGET 
            {    
                // 计算rendertexture的UV值
                float2 uv = i.worldPos.xz - _Position.xz; // 像素点相对于相机中心的距离
                uv = uv / (_OrthographicCamSize *2); // 转为 -0.5~0.5
                uv += 0.5; // 转为 0~1
                // 采样rendertexture贴图
                float ripples = SAMPLE_TEXTURE2D(_GlobalEffectRT, smp_Point_Repeat, uv ).b;

                // 采样噪声贴图
                float distortx = SAMPLE_TEXTURE2D(_NoiseTex, smp_Point_Repeat, (i.worldPos.xz * _Scale)  + (_Time.x * 2)).r + ripples*2;
				// 采样主贴图- (distortx * _DistortStrength)
				half4 col = SAMPLE_TEXTURE2D(_MainTex, smp_Point_Repeat, i.uv + _MainTexDistort * distortx ) * _MainColor;
                // 获取深度纹理中的深度值
				half depth = GetLinearEyeDepth(i.screenPos.xy/i.screenPos.w);
                // 通过深度图中的深度值和像素深度值的差值，实现foam效果
				half4 foamLine = 1 - saturate(_Foam * (depth - i.screenPos.w));
				col += foamLine * _FoamColor;
				
                // 采样Noise贴图
                half4 noise = SAMPLE_TEXTURE2D(_NoiseTex, smp_Point_Repeat, i.uv);
                float2 distort = _DistortStrength * (noise.xy);
                // 使用Noise的值对SceneColor进行扰动，达到扭曲的效果
                half3 sceneColor = SampleSceneColor(i.screenPos.xy/i.screenPos.w +  distort);
                
                ripples = step(0.99, ripples * 3);
                float4 ripplesColored = ripples * _RippleColor;

                return col + half4(sceneColor, 1) + ripplesColored;
            }
            
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}