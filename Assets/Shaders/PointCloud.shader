// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// https://issuetracker.unity3d.com/issues/upgrade-note-replaced-mul-unity-matrix-mvp-star-with-unityobjecttoclippos-star-faulty-replacement-breaking-shader

Shader "Custom/PointCloud" {
	
	Properties {
		_SpriteTex ("Sprite (RGB)", 2D) = "white" {}
		_Size ("Size", Range(0, 3)) = 0.5
		_DispTex("Displacement Texture", 2D) = "gray" {}
		_Displacement("Displacement", float) = 0.1 
	}

	SubShader {
		Pass {
			Tags { "RenderType"="Opaque" }
			LOD 200
		
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex VS_Main
			#pragma fragment FS_Main
			#pragma geometry GS_Main
			#include "UnityCG.cginc" 

			// **************************************************************
			// Data structures												*
			// **************************************************************
			struct GS_INPUT {
				float4	pos		: POSITION;
				float3	normal	: NORMAL;
				float2  tex0	: TEXCOORD0;
			};

			struct FS_INPUT {
				float4	pos		: POSITION;
				float2  tex0	: TEXCOORD0;
			};

			// **************************************************************
			// Vars															*
			// **************************************************************
			float _Size;
			float4x4 _VP;
			Texture2D _SpriteTex;
			SamplerState sampler_SpriteTex;
			sampler2D _DispTex;
			float _Displacement;

			// **************************************************************
			// Shader Programs												*
			// **************************************************************
			// Vertex Shader ------------------------------------------------
			GS_INPUT VS_Main(appdata_base v) {
				GS_INPUT output = (GS_INPUT)0;

				float3 dcolor = tex2Dlod(_DispTex, float4(v.texcoord.xy, 0, 0));
				float d = dcolor.r;
				v.vertex.xyz += v.normal * d * _Displacement;

				output.pos =  mul(unity_ObjectToWorld, v.vertex);
				output.normal = v.normal;
				output.tex0 = float2(0, 0);
				return output;
			}

			// Geometry Shader -----------------------------------------------------
			[maxvertexcount(4)]
			void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream) {
				float3 up = float3(0, 1, 0);
				float3 look = _WorldSpaceCameraPos - p[0].pos;
				look.y = 0;
				look = normalize(look);
				float3 right = cross(up, look);
					
				float halfS = 0.5f * _Size;
							
				float4 v[4];
				v[0] = float4(p[0].pos + halfS * right - halfS * up, 1.0f);
				v[1] = float4(p[0].pos + halfS * right + halfS * up, 1.0f);
				v[2] = float4(p[0].pos - halfS * right - halfS * up, 1.0f);
				v[3] = float4(p[0].pos - halfS * right + halfS * up, 1.0f);

				float4x4 vp;
				#if UNITY_VERSION >= 560 
				vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);
				#else 
				#if UNITY_SHADER_NO_UPGRADE 
				vp = mul(UNITY_MATRIX_MVP, unity_WorldToObject);
				#endif
				#endif
				FS_INPUT pIn;
				pIn.pos = mul(vp, v[0]);
				pIn.tex0 = float2(1.0f, 0.0f);
				triStream.Append(pIn);

				pIn.pos =  mul(vp, v[1]);
				pIn.tex0 = float2(1.0f, 1.0f);
				triStream.Append(pIn);

				pIn.pos =  mul(vp, v[2]);
				pIn.tex0 = float2(0.0f, 0.0f);
				triStream.Append(pIn);

				pIn.pos =  mul(vp, v[3]);
				pIn.tex0 = float2(0.0f, 1.0f);
				triStream.Append(pIn);
			}

			// Fragment Shader -----------------------------------------------
			float4 FS_Main(FS_INPUT input) : COLOR {
				return _SpriteTex.Sample(sampler_SpriteTex, input.tex0);
			}

			ENDCG
		}
	} 

}
