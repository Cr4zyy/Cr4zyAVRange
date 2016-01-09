#include <renderer/RenderSetup.hlsl>

struct VS_INPUT
{
   float3 ssPosition   : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct VS_OUTPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
   float4 ssPosition   : SV_POSITION;
};

struct PS_INPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

sampler2D       baseTexture;
sampler2D       depthTexture;
sampler2D       normalTexture;

cbuffer LayerConstants
{
    float        startTime;
    float        amount;
	float        abilityRange;
	float        opacityValue;
};

/**
* Vertex shader.
*/  
VS_OUTPUT SFXBasicVS(VS_INPUT input)
{

   VS_OUTPUT output;

   output.ssPosition = float4(input.ssPosition, 1);
   output.texCoord   = input.texCoord + texelCenter;
   output.color      = input.color;

   return output;

}    

float4 SFXDarkVisionPS(PS_INPUT input) : COLOR0
{
	
	float2 texCoord = input.texCoord;
	float normalColor = 0;
	float4 inputPixel = tex2D(baseTexture, texCoord);
	float  depth = tex2D(depthTexture, texCoord).r;
	float  model = max(0, tex2D(depthTexture, texCoord).g * 2 - 1);
	float3 normal = tex2D(normalTexture, texCoord).xyz;
	float  intensity = pow((abs(normal.z) * 1.4), 2); //abs(normal.y) + 
	float4 edge = 0;
	float2 depth1 = tex2D(depthTexture, input.texCoord).rg;
	
	float red = inputPixel.r;
	float green = inputPixel.g;
	float blue = inputPixel.b;
	
	float x = (input.texCoord.x - 0.5) * 20;
    float y = (input.texCoord.y - 0.5) * 20;	
	float sineX  = sin(-x * .1) * sin(-x * .1);
	float sineY = sin(-y * .02) * sin(-y * .02);
	float biteAreaX  = clamp((sineX * 5),0 ,1);
	float biteAreaY = clamp((sineY * 40),0 ,1);
	float avAreaX  = clamp((sineX * 2),0 ,1);
	float avAreaY = clamp((sineY * 20),0 ,1);

	float meleeRange = 1.8;
	float meleeRange1 = 1.5;
	float meleeRange2 = 1.2;
	float meleeRangeCone1 = 1;
	float meleeRangeCone2 = 0.75;
	float meleeRangeCone3 = 0.5;
	float meleeRangeInvert = 1.8;
	float meleeRangeInvert1 = 1.8;
	float meleeRangeRing = 0;
	float meleeRangeRing1 = 0;

	//if we have no mod our default opacity is 0, it needs to be 1
	float aidOpacity = abs(opacityValue - 1);
	float range = abilityRange;
	
//set depth for bite range marker
//this sets default range to 1.8 which is a good avg value for skulk, lerk and fade melee attacks but isn't perfect
//if we have a mod to pull actual alien ranges we use this to set them and overwrite the default range value above

	//this needs to be below the 'zero number' in the mod
	if (range > 0.1) {
		//this must be above the 'zero number' in the mod but below any of the actual ranges
		if (range > 1) {
		
			if (range > 1.45) {
				if (range > 1.55) {
					//range over 5 only applies to umbra and healspray			
					if (range > 5) {
						meleeRange = max((range + 0.35) - depth, 0);
						meleeRangeCone1 = max(1.25 - depth, 0);
						meleeRangeCone2 = max(1 - depth, 0);
						meleeRangeCone3 = max(.75 - depth, 0);
						meleeRange1 = max((range + 0.1) - depth, 0);
						meleeRange2 = max(range - depth, 0);
					}
					//fade and onos
					else {
					meleeRange = max((range + 0.25) - depth, 0);
					meleeRangeCone1 = max((range - (0.2 * range)) - depth, 0); 
					meleeRangeCone2 = max((range - (0.4 * range)) - depth, 0);
					meleeRangeCone3 = max((range - (0.6 * range)) - depth, 0);
					meleeRange1 = max(range - depth, 0);
					meleeRange2 = max((range - 0.2) - depth, 0);
					}
				}
				//lerk
				else {
					meleeRange = max((range + 0.25) - depth, 0);
					meleeRangeCone1 = max((range - (0.2 * range)) - depth, 0); 
					meleeRangeCone2 = max((range - (0.4 * range)) - depth, 0);
					meleeRangeCone3 = max((range - (0.75 * range)) - depth, 0);
					meleeRange1 = max(range - depth, 0);
					meleeRange2 = max(range - depth, 0);
				}
			}
			//skulk
			else {
				meleeRange = max((range + 0.4) - depth, 0);
				meleeRangeCone1 = max((range - (0.25 * range)) - depth, 0); 
				meleeRangeCone2 = max((range - (0.35 * range)) - depth, 0);
				meleeRangeCone3 = max((range - (0.65 * range)) - depth, 0);
				meleeRange1 = max(range - depth, 0);
				meleeRange2 = max(range - depth, 0);
			}
		}
		else{
			meleeRange = 0;
			meleeRangeCone1 = 0;
			meleeRangeCone2 = 0;
			meleeRangeCone2 = 0;
			meleeRange1 = 0;
			meleeRange2 = 0;
		}
	}
	else{
		meleeRange = max(1.75 - depth, 0);
		meleeRangeCone1 = 0;
		meleeRangeCone2 = 0;
		meleeRangeCone2 = 0;
		meleeRange1 = 0;
		meleeRange2 = 0;
	}
	
//range limit ring
	meleeRangeInvert = clamp(lerp(1,0,meleeRange),0,1);
	meleeRangeInvert1 = clamp(lerp(1,0,meleeRange1),0,1);
	meleeRangeRing = meleeRange1*meleeRangeInvert;
	meleeRangeRing1 = meleeRange2*meleeRangeInvert1;
		 
//vignette the screen
	float2 screenCenter = float2(0.5, 0.5);
	float darkened = 1 - clamp(length(texCoord - screenCenter) - 0.45, 0, 1);
	darkened = pow(darkened, 4);	

	const float offset = 0.0004 + depth1.g * 0.00001;
	float  depth2 = tex2D(depthTexture, texCoord + float2( offset, 0)).r;
	float  depth3 = tex2D(depthTexture, texCoord + float2(-offset, 0)).r;
	float  depth4 = tex2D(depthTexture, texCoord + float2( 0,  offset)).r;
	float  depth5 = tex2D(depthTexture, texCoord + float2( 0, -offset)).r;
	
	edge = abs(depth2 - depth) +  
		   abs(depth3 - depth) + 
		   abs(depth4 - depth) + 
		   abs(depth5 - depth);
		     
	edge = min(1, pow(edge + 0.12, 2));
	
	float fadedist = pow(2.6, -depth1.r * 0.23 + 0.23);
	float fadeout = max(0.0, pow(2, max(depth - 0.5, 0) * -0.3));
	float fadeoff = max(0.12, pow(2, max(depth - 0.5, 0) * -0.2));
	
	float biteCone = 0;
	float coneStrength = 0;
	float biteCircle0 = 0;
	float biteCircle1 = 0;
	float biteCircle2 = 0;
	float biteCircle3 = 0;
	float biteCircle4 = 0;
	float biteCircle5 = 0;
	
//gorge healspray and umbra get larger cones up close
//smaller multipliers are larger circles
	if (range > 1){
		if (range > 5) {
			biteCircle0 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 1.5, 0, 1)),0,1);
			biteCircle1 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 1.25, 0, 1)),0,1);
			biteCircle2 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 1, 0, 1)),0,1);
			biteCircle4 = lerp(1,0,clamp((biteAreaX + biteAreaY) * 2, 0, 1));
			biteCircle5 = lerp(1,0,clamp((biteAreaX + biteAreaY) * 5, 0, 1));
			}
//melee attacks
		else {
			biteCircle0 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 9, 0, 1)),0,1);
			biteCircle1 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 3.2, 0, 1)),0,1);
			biteCircle2 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 1.9, 0, 1)),0,1);
			biteCircle3 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY) * 1, 0, 1)),0,1);
			biteCircle4 = lerp(1,0,clamp((biteAreaX + biteAreaY) * 5, 0, 1));
			biteCircle5 = lerp(1,0,clamp((biteAreaX + biteAreaY) * 10, 0, 1));
		}
	} 
	else{
		biteCircle0 = clamp(lerp(1,0,clamp((biteAreaX + biteAreaY), 0, 1)),0,1);
		biteCircle1 = 0;
		biteCircle2 = 0;
		biteCircle3 = 0;
		biteCircle4 = 0;
		biteCircle5 = 0;
		}

//this makes sure that on high-range abilities the aid isnt blownout
	if (range > 3)
	{
		if (range > 10)
		{
		coneStrength = range / 2000;
		
		}
		else {
			coneStrength = range / 100;
		}
	}
	else 
	{
	coneStrength = 0.2;
	}
	
	if (range > 1){
		if (range > 5){
			biteCone = (model * aidOpacity) * (
			meleeRange * biteCircle0 * coneStrength + 
			meleeRangeCone1 * biteCircle1 + 
			meleeRangeCone2 * biteCircle2 +			
			meleeRangeRing * biteCircle3 + 
			meleeRangeRing1 * biteCircle4);
		}
		else{
			biteCone = (model * aidOpacity) * (
			meleeRange * biteCircle0 + 
			meleeRangeCone1 * biteCircle1 + 
			meleeRangeCone2 * biteCircle2 +
			meleeRangeCone3 * biteCircle3);
		}
	
	}
	else {
		biteCone = (model * aidOpacity) * (meleeRange * biteCircle0);
	}
	
	//old bitecone
	//biteCone = (model * aidOpacity) * ((max(1.75 - depth, 0)) * (clamp(lerp(1,0,clamp((biteAreaX + biteAreaY), 0, 1)),0,1)));

//AV Colouring
	//green to blue | orange bite
	float4 colourOne = float4(0.1, 0.95, -0.2, 1);
	float4 colourTwo = float4(-.1, 0.2, .4, 0);
	float4 colourAid = float4(.2, 0, 0, 1);
	
		//blue to green | orange bite
		//float4 colourOne = float4(-.1, 0.1, 1, 0);
		//float4 colourTwo = float4(0.1, 0.6, -0.1, 1);
		//float4 colourAid = float4(.2, .05, 0, 1);
		
			//red to yellow
			//float4 colourOne = float4(0.95, -0.01, -0.05, 1);
			//float4 colourTwo = float4(0.5, 0.25, 0, 1);
			//float4 colourAid = float4(0, .12, .05, 1);
			 
				//yellow to red
				//float4 colourOne = float4(0.9, 0.35, 0, 1);
				//float4 colourTwo = float4(0.9, -.02, -0.05, 1);
				//float4 colourAid = float4(0, .02, .2, 1);
				
					//white to black
					//float4 colourOne = float4(1, 1, 1, 1);
					//float4 colourTwo = float4(0.05, 0.05, 0.05, 1);
					//float4 colourAid = float4(-.02, -.05, -.06, 1);
					
					
	//default to no bite colouring
		float4 colourBite = float4(1, 0, 0, 1);
		float4 disabledBite = float4(0, 0, 0, 1);
		float4 colourRanged = float4(0, 0, 0, 1);
		
//for melee attacks set one colour
	if (range >= 0) {
		colourBite = colourAid;
		disabledBite = colourBite * .8 + .1;
	} 
//for gorge healspray set another colour
	if (range > 5) {
		colourRanged = float4(0.2, 0.05, .2, 1) * 2;
		disabledBite = colourRanged * .7 + .1;
		colourBite = colourRanged;
	}
			
//setup aid
	float4 biteAid = (biteCone * colourBite) * (1 + 0.3 * pow(0.1 + sin(time * 5 + intensity * .2), 2));
	float4 biteAidDisabled = (biteCone * disabledBite)* (1 + 0.3 * pow(0.1 + sin(time * 5 + intensity * .2), 2));
	
//fog colour | purple
	float4 colourFog = float4(0.07, 0.02, 0.13, 1);
		
//offset colour when models are at an angle to camera
	float4 colourAngle = lerp(colourOne, colourTwo, .8) * .8;
		

	
//set up screen center colouring
	float4 mainColour = 
	model * edge * colourOne * 2 * clamp(fadedist*5,0.02,1) +
	model * edge * colourTwo * 1.1 * clamp(1-fadedist*7,0,1) * clamp(fadedist*300,0.02,1)  +
	model * edge * colourTwo * .4 * clamp(1-fadedist*60,0,1);
		
	
//set up screen edge colouring
	float4 edgeColour = 
	model * edge * colourOne * 2 * clamp(fadedist*.5,0,1) + 
	model * edge * colourTwo * 1.1 * clamp(1-fadedist*2.5,0,1) * clamp(fadedist*10,0.02,1) + 
	model * edge * colourTwo * .5 * (1-clamp(fadedist*1.2,0.02,1));

//outlines for when av is off, edges only
	float4 offOutline = model * (
	((edge * edge) * 3) * colourOne * 2 * clamp(fadedist*2.25,0,1) + 
	((edge * edge) * 2) * colourTwo * 1.2 * clamp(1-fadedist*4.5,0,1) * clamp(fadedist*500,0.02,1) + 
	(edge * edge) * colourTwo * .4 * (1-clamp(fadedist*60,0.02,1)) * 3);
	
//lerp it together
	float4 outline = lerp(mainColour, edgeColour, clamp(avAreaX + avAreaY, 0, 1));
		
//WORLD colours
	float4 environment = (lerp(float4(0.2, 0.2, .2, 1), inputPixel, edge) * edge*edge * .8 );
	float4 world = lerp(inputPixel / float4(-1, -1, -1, 1) * .5 + edge * float4(0.02, 0.02, 0.02, 1), environment, model);


//desaturate
	//float4 desaturate = float4(max(0, max(green, blue) - red), max(0, max(red, blue) - green), max(0, max(green, red) - blue), 0);
	
//desaturate more at range
	float4 desaturate = float4(max(0, max(green, blue) - red), max(0, max(red, blue) - green), max(0, max(green, red) - blue), 0) * 0.03 * clamp(fadedist*2.25,0,1) + float4(max(0, max(green, blue) - red), max(0, max(red, blue) - green), max(0, max(green, red) - blue), 0) * .09 *clamp(1-fadedist*2.5,0,1) * clamp(fadedist*9,0.02,1) + float4(max(0, max(green, blue) - red), max(0, max(red, blue) - green), max(0, max(green, red) - blue), 0) * .15 * (1-clamp(fadedist*9,0.02,1)) * clamp(fadedist*30,0.02,1) + float4(max(0, max(green, blue) - red), max(0, max(red, blue) - green), max(0, max(green, red) - blue), 0) * .2 * (1-clamp(fadedist*30,0.02,1));
	
//FOG setup
	float4 fog = clamp(pow(depth * 0.012, 1), 0, 1.2) * colourFog * (0.6 + edge);
		
//av off effects   
	if (amount < 1){
		//return inputPixel + desaturate * .25 * (1 + edge) + (offOutline + biteAidDisabled) * .4 + world;
			
		//minimal av off
		return inputPixel + world * .1;
	}

//put it all together

	//normal with fog and aid
	//return pow(inputPixel * .9 * darkened, 1.3) + desaturate * 2 + fog * (2 + edge * .2) + ((outline + biteAid) * (model * 1.5)) * 1.75 + model * intensity * colourAngle * (0.5 + 0.2 * pow(0.1 + sin(time * 5 + intensity * 3), 2)) * fadeoff;
	
	//normal with fog
	//return pow(inputPixel * .9 * darkened, 1.3) + desaturate * 2 + fog * (2 + edge * .2) + (outline  * (model * 1.5)) * 1.75 + model * intensity * colourAngle * (0.5 + 0.2 * pow(0.1 + sin(time * 5 + intensity * 3), 2)) * fadeoff;
	
	//minimal with aid
	return pow(inputPixel * .9 * darkened, 1.4) + desaturate * .5 + ((outline + biteAid) * (model * 1.5)) * 2.5 + model * intensity * colourAngle * (0.5 + 0.2 * pow(0.1 + sin(time * 5 + intensity * 3), 2)) * fadeoff + (inputPixel + world * .75);
	
	//minimal
	//return pow(inputPixel * .9 * darkened, 1.4) + desaturate * .5 + (outline * (model * 1.5)) * 2.5 + model * intensity * colourAngle * (0.5 + 0.2 * pow(0.1 + sin(time * 5 + intensity * 3), 2)) * fadeoff + (inputPixel + world * .75);
}