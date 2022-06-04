#if __INTELLISENSE__
#include "cppIntellisense.h"
#endif

#if TURBO
class STMRecord {
  string trackName;
  array<int> unprocessedTimes;
  array<int> trackTimes;
  int totalTime;

  STMRecord(string name, array<int> times) {
    trackName = name;
    unprocessedTimes = times;
    for (uint i = 0; i < unprocessedTimes.Length; i++) {
      totalTime += unprocessedTimes[i];
    }
  }

  // Data should probably be adjusted to not require this
  // but unsure how many laps each multilap is, assuming 3 but I havent finished
  // the game and dont have an easy way to check
  void PrepareForLapCount(uint numLaps) {
    uint numCpsPerLap =
        uint(Math::Ceil(float(unprocessedTimes.Length) / float(numLaps)));
    DebugText("STM Updating Record for lapcount " + numLaps + "(" +
              numCpsPerLap + "/" + unprocessedTimes.Length + ")");
    for (uint i = 0; i < unprocessedTimes.Length; i++) {
      int time = unprocessedTimes[i];
      if (i < numCpsPerLap) {
        trackTimes.InsertLast(time);
      } else {
        int cp = i % numCpsPerLap;
        if (trackTimes[cp] > time) {
          DebugText("\tUpdating " + cp + ": " + trackTimes[cp] + " > " + time);
          trackTimes[cp] = time;
        }
      }
    }
  }
}

int STMRecordIndex = -1;

void UpdateSTMRecordIndex() {
  STMRecordIndex = -1;
  auto map = GetApp().Challenge;
  if (map is null) {
    DebugText("STM cant find map");
    return;
  }
  int invalid = 0;
  invalid += BoolToInt(string(map.MapInfo.NameForUi).get_Length() != 3);
  invalid += BoolToInt(map.MapInfo.AuthorNickName != "Nadeo");

  if (invalid != 0) {
    DebugText("cant find STM Record");
    return;
  }
  int mapIndex = Text::ParseInt(map.MapInfo.NameForUi);
  if (mapIndex > 200 || mapIndex < 0) {
    DebugText("mapIndex not in range");
    return;
  }
  STMRecordIndex = mapIndex - 1;
  DebugText("STM Map Index: " + STMRecordIndex);
}

// STMRecord[] STMRecords =
// [STMRecord("../SuperTrackmasters/001_C_Discovery_euronics.riolu!(00'32''256)",
// times)];
//  STMRecord@[] STMRecords =
//  {
//      STMRecord("../SuperTrackmasters/001_C_Discovery_euronics.riolu!(00'32''256)",
//      {11545,9857,6559,4295})
//  };
STMRecord @[] STMRecords = {
STMRecord("../SuperTrackmasters/001_C_Discovery_euronics.riolu!(00'32''256)",{11545,9857,6559,4295}),
STMRecord("../SuperTrackmasters/002_C_Speed_euronics.riolu!(00'34''943)",{10360,6611,7297,7979,2696}),
STMRecord("../SuperTrackmasters/003_C_ShowOff_AwS Laurens(00'28''387)",{6528,8042,5071,6187,2559}),
STMRecord("../SuperTrackmasters/004_C_SpeedTech_AwS Laurens(00'25''152)",{10938,7008,3614,3592}),
STMRecord("../SuperTrackmasters/005_C_Multilap_euronics.riolu!(01'13''910)",{10400,6814,5306,6016,5267,6174,5257,6034,5250,6140,5238,6014}),
STMRecord("../SuperTrackmasters/006_C_Discovery_AwS Laurens(00'28''535)",{9604,10952,5037,2942}),
STMRecord("../SuperTrackmasters/007_C_Speed_AwS Laurens(00'25''184)",{7320,4676,5879,4901,2408}),
STMRecord("../SuperTrackmasters/008_C_ShowOff FINAL_AwS Laurens(00'19''885)",{10493,9392}),
STMRecord("../SuperTrackmasters/009_C_SpeedTech_AwS Laurens(00'25''15)",{10938,7008,3614,3592}),
STMRecord("../SuperTrackmasters/010_C_Multilap_AwS Laurens(01'11''968)",{11621,6117,4182,6148,6475,5405,3980,6088,6468,5396,3958}),
STMRecord("../SuperTrackmasters/011_V_Discovery_euronics.riolu!(00'26''473).",{9838,6769,4108,3300}),
STMRecord("../SuperTrackmasters/012_V_Speed_〜ИєΫσ-8826(00'26''966)",{9098,5069,3961,6357,2481}),
STMRecord("../SuperTrackmasters/013_V_ShowOff_euronics.Marius89(00'27''208)",{8401,4021,4006,5337,5443}),
STMRecord("../SuperTrackmasters/014_V_Tech_〜ИєΫσ-8826(00'17''897)",{5134,2517,4010,3473,2763}),
STMRecord("../SuperTrackmasters/015_V_Multilap_euronics.riolu!(01'26''125)",{6561,5221,3814,7331,5404,3165,3376,4495,3658,7322,5390,3144,3354,4437,3644,7272,5360,3177}),
STMRecord("../SuperTrackmasters/016_V_Discovery FINAL_euronics.riolu!(00'26''818)",{9092,2621,3791,4116,7198}),
STMRecord("../SuperTrackmasters/017_V_Speed_euronics.riolu!(00'26''832)",{10876,8808,4599,2549}),
STMRecord("../SuperTrackmasters/018_V_ShowOff_〜ИєΫσ-8826(00'22''765)",{7621,4013,2951,5917,2263}),
STMRecord("../SuperTrackmasters/019_V_SpeedTech FINAL_euronics.riolu!(00'21''062)",{7625,3262,3827,3710,2638}),
STMRecord("../SuperTrackmasters/020_V_Multilap_euronics.riolu!(01'06''764)",{7806,7709,5857,2984,4702,7595,5907,2955,4669,7633,5913,3034}),
STMRecord("../SuperTrackmasters/021_L_Discovery FINAL_euronics.riolu!(00'21''531)",{4995,8195,2062,2913,1845,1521}),
STMRecord("../SuperTrackmasters/022_L_Speed FINAL_euronics.riolu!(00'24''546)",{6405,2453,5733,2960,4747}),
STMRecord("../SuperTrackmasters/023_L_ShowOff FINAL_euronics.riolu!(00'20''681)",{6893,3653,3464,3636,3035}),
STMRecord("../SuperTrackmasters/024_L_Tech_euronics.riolu!(00'18''171)",{5815,4571,4880,2905}),
STMRecord("../SuperTrackmasters/025_L_Multilap_PuffBros~Paco.(01'17''028)",{8070,4075,4328,3822,4707,2690,5346,3736,4278,3819,4724,2691,5351,3745,4329,3853,4758,2706}),
STMRecord("../SuperTrackmasters/026_L_Discovery_euronics.riolu!(00'21''268)",{9715,3140,3108,5305}),
STMRecord("../SuperTrackmasters/027_L_Speed_euronics.riolu!(00'28''558)",{8201,4200,5387,4050,2754,2162,1792}),
STMRecord("../SuperTrackmasters/028_L_ShowOff_euronics.riolu!(00'30''960)",{7123,3029,5253,2329,3032,2560,3337,4297}),
STMRecord("../SuperTrackmasters/029_L_SpeedTech FINAL_euronics.riolu!(00'25''843)",{5528,7245,3475,5784,2569,1242}),
STMRecord("../SuperTrackmasters/030_L_Multilap_euronics.riolu!(01'07''205)",{4264,3421,4955,1672,4452,2620,3124,2200,2777,4548,1660,4418,2609,3133,2197,2773,4532,1661,4429,2630}),
STMRecord("../SuperTrackmasters/031_S_Discovery_acer _ racehans(00'23''65)",{7885,3199,3637,4372}),
STMRecord("../SuperTrackmasters/032_S_Speed_acer _ racehans(00'22''96)",{5638,4087,3179,4170,5894}),
STMRecord("../SuperTrackmasters/033_S_ShowOff_euronics.riolu!(00'22''95)",{8825,7280,6851}),
STMRecord("../SuperTrackmasters/034_S_Tech_acer _ racehans(00'25''46)",{4227,4710,3727,5104,3722}),
STMRecord("../SuperTrackmasters/035_S_Multilap_acer _ racehans(00'53''54)",{8635,6829,4747,5317,6624,4710,5360,6623,4703}),
STMRecord("../SuperTrackmasters/036_S_Discovery_acer _ racehans(00'23''21)",{5948,1610,3583,4667,4842,2567}),
STMRecord("../SuperTrackmasters/037_S_Speed_acer _ racehans(00'26''77)",{4809,4552,3717,4458,4485,4757}),
STMRecord("../SuperTrackmasters/038_S_ShowOff_acer _ racehans(00'17''02)",{9495,3019,4056,455}),
STMRecord("../SuperTrackmasters/039_S_SpeedTech_acer _ racehans(00'27''61)",{8182,6400,4669,5394,2971}),
STMRecord("../SuperTrackmasters/040_S_Multilap_dignitas_Coach Paco eK.(01'12''57)",{5932,5666,1593,5020,2895,2445,4300,1801,4874,1365,4696,2844,2420,4337,1825,4883,1350,4682,2853,2413,4384}),
STMRecord("../SuperTrackmasters/041_C_Discovery_euronics.riolu!(00'33''05)",{7014,6014,7570,7728,4725}),
STMRecord("../SuperTrackmasters/042_C_Speed_euronics.riolu!(00'36''04)",{7200,6242,11428,2137,2165,6169,707}),
STMRecord("../SuperTrackmasters/043_C_ShowOff_CK RedExtraSmurf (00'24''99)",{8127,4780,5769,3489,1253,1575}),
STMRecord("../SuperTrackmasters/044_C_Tech_CK RedExtraSmurf (00'29''10)",{4606,4372,6633,4204,3121,3547,2625}),
STMRecord("../SuperTrackmasters/045_C_Multilap FINAL_CK RedExtraSmurf (02'00''99)",{8391,6126,4435,6996,10335,3800,3773,3909,5559,4363,6873,10322,3734,3800,3902,5522,4360,6893,10333,3780,3792}),
STMRecord("../SuperTrackmasters/046_C_Discovery_euronics.riolu!(00'35''49)",{12611,6624,6573,9687}),
STMRecord("../SuperTrackmasters/047_C_Speed_CK RedExtraSmurf (00'32''41)",{13646,6242,6997,5530}),
STMRecord("../SuperTrackmasters/048_C_ShowOff_euronics.riolu!(00'29''89)",{6178,8653,11927,3140}),
STMRecord("../SuperTrackmasters/049_C_SpeedTech_euronics.riolu!(00'36''88)",{7855,6511,4285,13247,2148,2839}),
STMRecord("../SuperTrackmasters/050_C_Multilap FINAL_euronics.riolu!(01'30''31)",{7168,8204,2002,5086,3994,2542,4679,3090,7098,1894,4961,3995,2524,4771,3120,7202,1875,4963,4008,2498,4640}),
STMRecord("../SuperTrackmasters/051_V_Discovery_euronics.Marius89(00'36''55)",{7227,2951,10334,10939,5105}),
STMRecord("../SuperTrackmasters/052_V_Speed_euronics.riolu!(00'29''83)",{10837,5554,4841,5240,3363}),
STMRecord("../SuperTrackmasters/053_V_ShowOff_euronics.riolu!(00'32''99)",{4477,2347,2263,3168,6838,8195,3529,2177}),
STMRecord("../SuperTrackmasters/054_V_Tech_euronics.Marius89(00'35''20)",{6228,4118,5344,6876,7191,5448}),
STMRecord("../SuperTrackmasters/055_V_Multilap_euronics.riolu!(01'57''23)",{7610,4475,5469,5024,4216,2804,7866,3123,5487,4444,5399,4981,4233,2813,7860,3091,5435,4440,5511,4970,4249,2814,7838,3083}),
STMRecord("../SuperTrackmasters/056_V_Discovery_〜ИєΫσ-8826(00'30''62)",{7496,5627,3389,8166,5945}),
STMRecord("../SuperTrackmasters/057_V_Speed_〜ИєΫσ-8826(00'31''20)",{6115,2893,4524,2992,2881,4882,4120,2799}),
STMRecord("../SuperTrackmasters/058_V_ShowOff_〜ИєΫσ-8826(00'36''26)",{8927,4971,6395,11511,4463}),
STMRecord("../SuperTrackmasters/059_V_SpeedTech_euronics.riolu!(00'36''98)",{10662,3937,8559,3764,3347,3596,3120}),
STMRecord("../SuperTrackmasters/060_V_Multilap_euronics.riolu!(01'46''51)",{4594,3509,3279,3754,3973,4563,4961,2031,3725,2929,1990,3250,3248,3722,3956,4541,5046,2034,3728,2914,1988,3343,3300,3770,3997,4589,5012,2042,3793,2934}),
STMRecord("../SuperTrackmasters/061_L_Discovery_euronics.riolu!(00'32''91)",{6197,5121,9316,4251,3158,4875}),
STMRecord("../SuperTrackmasters/062_L_Speed_euronics.riolu!(00'29''62)",{4158,3812,3294,5832,3631,5236,3659}),
STMRecord("../SuperTrackmasters/063_L_ShowOff_PuffBros~Paco.(00'35''10)",{4686,3856,4622,5844,2634,3345,2938,2393,2709,2077}),
STMRecord("../SuperTrackmasters/064_L_Tech_euronics.riolu!(00'32''79)",{9350,3932,4254,3660,4870,4478,2246}),
STMRecord("../SuperTrackmasters/065_L_Multilap_euronics.riolu!(01'20''17)",{5772,5536,3906,3857,4508,2258,4005,3312,4183,3551,3533,4373,2210,3981,3313,4182,3553,3518,4414,2213,3994}),
STMRecord("../SuperTrackmasters/066_L_Discovery_PuffBros~Paco.(00'29''06)",{7188,4357,3653,4549,4023,3727,1571}),
STMRecord("../SuperTrackmasters/067_L_Speed_euronics.riolu!(00'31''41)",{4764,4094,7775,5459,4600,3074,1652}),
STMRecord("../SuperTrackmasters/068_L_ShowOff_euronics.riolu!(00'35''37)",{6496,2891,3115,3853,6437,9625,2960}),
STMRecord("../SuperTrackmasters/069_L_SpeedTech_euronics.riolu!(00'32''70)",{4165,7406,6046,4138,6207,4740}),
STMRecord("../SuperTrackmasters/070_L_Multilap_euronics.riolu!(02'03''65)",{6151,8073,6938,4323,2880,4091,5681,4120,4564,7968,6923,4360,2911,4111,5698,4154,4579,8001,6919,4353,2903,4101,5698,4153}),
STMRecord("../SuperTrackmasters/071_S_Discovery_acer _ racehans(00'36''17)",{7875,3927,6102,5105,4207,4477,4484}),
STMRecord("../SuperTrackmasters/072_S_Speed_acer _ racehans(00'26''72)",{6745,3006,5671,5233,3676}),
STMRecord("../SuperTrackmasters/073_S_ShowOff_acer _ racehans(00'25''72)",{4328,643,1187,6326,2994,2246,738,7264}),
STMRecord("../SuperTrackmasters/074_S_Tech_acer _ racehans(00'34''44)",{4065,4227,2546,4412,2066,5186,5872,2148,3926}),
STMRecord("../SuperTrackmasters/075_S_Multilap_acer _ racehans(01'39''58)",{7486,4052,3567,5807,4250,4491,5199,4956,3975,3542,5810,4335,4667,5303,4826,3977,3593,5836,4246,4524,5147}),
STMRecord("../SuperTrackmasters/076_S_Discovery_acer _ racehans(00'33''41)",{6443,2272,4207,5942,5021,5603,3923}),
STMRecord("../SuperTrackmasters/077_S_Speed_acer _ racehans(00'31''18)",{8954,3944,8547,4711,3562,1463}),
STMRecord("../SuperTrackmasters/078_S_ShowOff_acer _ racehans(00'28''20)",{5782,5486,2447,5718,2075,417,747,580,4953}),
STMRecord("../SuperTrackmasters/079_S_SpeedTech_acer _ racehans(00'33''90)",{8701,5330,3835,5294,4110,3894,2741}),
STMRecord("../SuperTrackmasters/080_S_Multilap_acer _ racehans(01'48''00)",{6578,3868,7671,5919,3326,3193,5342,3687,2392,2667,7527,5936,3369,3169,5551,3773,2363,2667,7486,5949,3362,3213,5378,3622}),
STMRecord("../SuperTrackmasters/081_C_Discovery_euronics.riolu!(00'38''89)",{6135,6233,5846,8688,5169,6822}),
STMRecord("../SuperTrackmasters/082_C_Speed_Nova.Zypher (00'38''93)",{5968,4797,6308,4763,5452,6502,4331,814}),
STMRecord("../SuperTrackmasters/083_C_ShowOff_Nova.Zypher (00'32''01)",{11271,2759,2273,6668,1256,4373,1028,2390}),
STMRecord("../SuperTrackmasters/084_C_Tech_Nova.Zypher (00'44''00)",{7721,5130,5747,6507,3760,7633,3060,4447}),
STMRecord("../SuperTrackmasters/085_C_Multilap_euronics.riolu!(02'39''17)",{14575,7451,6070,4837,5635,7856,7530,13225,7369,6080,4840,5676,7834,7598,13293,7377,6059,4841,5639,7836,7549}),
STMRecord("../SuperTrackmasters/086_C_Discovery_euronics.riolu!(00'43''01)",{7619,9419,3282,3406,6117,3678,4983,4514}),
STMRecord("../SuperTrackmasters/087_C_Speed_Nova.Zypher (00'46''94)",{9976,5232,5960,3590,3194,6408,6002,3926,2659}),
STMRecord("../SuperTrackmasters/088_C_ShowOff_Nova.Zypher (00'39''40)",{12235,9113,8475,6215,2490,878}),
STMRecord("../SuperTrackmasters/089_C_SpeedTech_euronics.riolu!(00'50''56)",{8194,5791,4139,4769,5271,4983,4084,5169,5586,2582}),
STMRecord("../SuperTrackmasters/090_C_Multilap_Nova.Zypher (02'56''84)",{5368,4644,4380,7103,5415,5498,4752,4694,5103,6777,6591,3741,4571,4409,7144,5413,5523,4692,4749,5046,6512,6530,3658,4559,4391,7107,5397,5460,4744,4717,5066,6454,6632}),
STMRecord("../SuperTrackmasters/091_V_Discovery_euronics.riolu!(00'46''83)",{5182,5847,6458,4499,5783,9921,5165,3980}),
STMRecord("../SuperTrackmasters/092_V_Speed FINAL_euronics.riolu!(00'41''40)",{6411,6624,3320,7486,6677,3968,4527,2388}),
STMRecord("../SuperTrackmasters/093_V_ShowOff_euronics.Marius89(00'41''47)",{7762,8232,5072,7728,2534,10147}),
STMRecord("../SuperTrackmasters/094_V_Tech_euronics.riolu!(00'43''25)",{5185,4483,5315,4643,7871,6291,5606,3857}),
STMRecord("../SuperTrackmasters/095_V_Multilap_euronics.riolu!(01'51''58)",{7607,5327,3602,4701,4603,7365,5748,5192,5286,3613,4757,4533,7304,5638,5198,5333,3596,4657,4588,7284,5655}),
STMRecord("../SuperTrackmasters/096_V_Discovery_euronics.Marius89(00'44''77)",{6258,6804,4715,5353,5452,5766,3760,4857,1811}),
STMRecord("../SuperTrackmasters/097_V_Speed_〜ИєΫσ-8826(00'42''97)",{4912,7704,8091,7364,4863,3428,6610}),
STMRecord("../SuperTrackmasters/098_V_ShowOff_euronics.Marius89(00'45''23)",{8508,5556,5686,3655,7222,3579,3109,4516,3400}),
STMRecord("../SuperTrackmasters/099_V_SpeedTech_euronics.riolu!(00'44''83)",{5525,4888,4955,4606,5218,4988,6316,6552,1790}),
STMRecord("../SuperTrackmasters/100_V_Multilap_euronics.riolu!(02'20''55)",{5467,3681,5859,4143,5388,4203,4457,3786,3765,3625,5058,2360,3297,5763,4145,5341,4060,4370,3725,3768,3599,5097,2375,3292,5755,4097,5372,4112,4397,3723,3779,3566,5130}),
STMRecord("../SuperTrackmasters/101_L_Discovery FINAL_euronics.riolu!(00'41''62)",{6945,6447,3834,4592,8314,4477,3510,3503}),
STMRecord("../SuperTrackmasters/102_L_Speed_PuffBros~Paco.(00'44''01)",{3745,6121,5055,8363,9734,4330,6667}),
STMRecord("../SuperTrackmasters/103_L_ShowOff_euronics.riolu!(00'40''27)",{3984,6453,2867,7286,7906,3942,4386,3454}),
STMRecord("../SuperTrackmasters/104_L_Tech_euronics.riolu!(00'49''97)",{8887,6258,3972,3527,3190,4004,6670,4260,5663,3541}),
STMRecord("../SuperTrackmasters/105_L_Multilap_PuffBros~Paco.(02'00''67)",{6639,6724,3455,3224,4740,7566,2185,3047,4754,4240,6121,3470,3200,4762,7635,2216,2968,4664,4237,6090,3451,3205,4755,7604,2133,2907,4679}),
STMRecord("../SuperTrackmasters/106_L_Discovery_euronics.riolu!(00'42''32)",{6095,3848,2005,2120,5516,4541,2118,2651,3987,2431,2119,2790,2103}),
STMRecord("../SuperTrackmasters/107_L_Speed_euronics.riolu!(00'44''63)",{4381,4777,3138,4704,5761,4090,2425,4894,7781,2687}),
STMRecord("../SuperTrackmasters/108_L_ShowOff_PuffBros~Paco.(00'37''68)",{7344,8584,5340,7030,3439,4291,1655}),
STMRecord("../SuperTrackmasters/109_L_SpeedTech_PuffBros~Paco.(00'42''77)",{7673,6572,3660,6607,5875,4067,6214,2104}),
STMRecord("../SuperTrackmasters/110_L_Multilap_euronics.riolu!(02'24''61)",{5577,3190,1605,3138,3335,3577,2669,2764,4530,8568,4152,3176,4184,2983,2817,1510,3052,3266,3485,2644,2744,4500,8524,4130,3168,4182,3001,2822,1525,3060,3290,3506,2648,2738,4516,8565,4141,3163,4169}),
STMRecord("../SuperTrackmasters/111_S_Discovery_acer _ racehans(00'38''05)",{7448,3779,1914,5187,1689,4794,3631,3480,6130}),
STMRecord("../SuperTrackmasters/112_S_Speed_acer _ racehans(00'41''98)",{7386,3976,3034,4142,2007,3726,5530,3725,3432,5024}),
STMRecord("../SuperTrackmasters/113_S_ShowOff FINAL_acer _ racehans(00'38''33)",{10824,4619,8138,3483,3478,7793}),
STMRecord("../SuperTrackmasters/114_S_Tech_acer _ racehans(00'47''03)",{6314,2551,4830,5947,4750,4836,2309,3121,3790,4356,4229}),
STMRecord("../SuperTrackmasters/115_S_Multilap_acer _ racehans(01'57''40)",{8734,3751,5126,6476,3462,2109,490,1463,4153,4880,6560,3721,5300,6328,3234,2048,483,1450,4250,4818,6426,3736,5183,6527,3221,2023,480,1605,4432,4933}),
STMRecord("../SuperTrackmasters/116_S_Discovery FINAL_eSuba.tween(00'44''89)",{7865,4016,3017,3344,3089,6014,4342,3858,3230,6118}),
STMRecord("../SuperTrackmasters/117_S_Speed_acer _ racehans(00'38''32)",{11284,2528,5626,2156,2406,3748,2158,4140,4275}),
STMRecord("../SuperTrackmasters/118_S_ShowOff FINAL_eSuba.tween(00'41''62)",{5381,127,120,942,1516,221,223,2123,2065,3733,5064,2261,2604,2167,4981,5227,2868}),
STMRecord("../SuperTrackmasters/119_S_SpeedTech_acer _ racehans(00'43''59)",{9254,8154,4996,3143,3899,2240,4516,7389}),
STMRecord("../SuperTrackmasters/120_S_Multilap FINAL_eSuba.tween(01'49''96)",{7430,2652,5431,4309,6790,5133,4739,2687,3813,2467,5265,4291,6711,5192,4751,2707,3810,2463,5337,4437,6866,5124,4782,2780}),
STMRecord("../SuperTrackmasters/121_C_Discovery_euronics.riolu!(00'47''73)",{6985,4413,7369,2404,3077,4108,4082,3067,12228}),
STMRecord("../SuperTrackmasters/122_C_Speed_euronics.riolu!(00'41''40)",{10448,5588,3394,3534,3022,6398,5029,3993}),
STMRecord("../SuperTrackmasters/123_C_ShowOff_euronics.riolu!(00'41''23)",{9856,2382,4519,7868,5538,5153,4858,1063}),
STMRecord("../SuperTrackmasters/124_C_Tech_CK RedExtraSmurf (00'41''73)",{7951,11492,5881,2547,1934,5703,3967,2257}),
STMRecord("../SuperTrackmasters/125_C_Multilap FINAL_CK RedExtraSmurf (02'55''33)",{8375,7735,5565,7341,7804,4063,5783,5385,8324,5483,7420,5533,7397,7760,4074,5868,5398,8413,5455,7482,5736,7497,7782,4095,5857,5409,8303}),
STMRecord("../SuperTrackmasters/126_C_Discovery_CK RedExtraSmurf (01'02''09)",{8048,6932,9427,3260,5574,4640,4783,5682,9569,4178}),
STMRecord("../SuperTrackmasters/127_C_Speed_Nova.Zypher (00'46''80)",{8978,9387,5925,6877,5504,3774,6360}),
STMRecord("../SuperTrackmasters/128_C_Speed FINAL_euronics.riolu!(00'58''67)",{7490,5240,4882,4349,9351,6231,5029,6361,4925,4815}),
STMRecord("../SuperTrackmasters/129_C_SpeedTech_Nova.Zypher (00'55''45)",{8798,3161,3509,4948,6434,5170,6538,6272,6375,4245}),
STMRecord("../SuperTrackmasters/130_C_Multilap_Nova.Zypher (02'50''47)",{10981,5083,5221,7786,6283,4434,3638,8065,6959,8630,5091,5251,7796,6260,4458,3715,8006,6902,8649,5076,5246,7802,6211,4425,3588,7945,6973}),
STMRecord("../SuperTrackmasters/131_V_Discovery_euronics.riolu!(00'56''76)",{8618,5307,4191,4196,4055,3103,4153,3933,5220,5297,3054,3592,2044}),
STMRecord("../SuperTrackmasters/132_V_Speed_〜ИєΫσ-8826(00'53''96)",{7125,4733,4508,5827,8168,5806,4953,6817,6026}),
STMRecord("../SuperTrackmasters/133_V_ShowOff_〜ИєΫσ-8826(00'55''96)",{6998,3430,3934,7746,4303,3674,3173,12695,2935,7077}),
STMRecord("../SuperTrackmasters/134_V_Tech_euronics.riolu!(00'55''63)",{5089,10690,5823,6726,8890,5820,12600}),
STMRecord("../SuperTrackmasters/135_V_Multilap_euronics.Marius89(03'19''01)",{8905,5119,9980,6403,5385,7329,4125,3011,7189,2923,4391,2313,7484,5117,10299,6291,5426,7318,4119,3015,7118,3037,4374,2274,7503,5252,10352,6378,5395,7281,4102,3003,7138,2947,4425,2289}),
STMRecord("../SuperTrackmasters/136_V_Discovery_euronics.riolu!(00'51''17)",{11308,3950,5841,5111,4746,8343,7948,3925}),
STMRecord("../SuperTrackmasters/137_V_Speed_〜ИєΫσ-8826(00'57''90)",{8368,4294,9482,6706,3833,7381,4911,5576,7357}),
STMRecord("../SuperTrackmasters/138_V_ShowOff FINAL_euronics.Marius89(00'56''10)",{11495,14598,9658,6517,6172,7668}),
STMRecord("../SuperTrackmasters/139_V_SpeedTech_euronics.riolu!(00'52''85)",{8309,7488,6417,5410,3975,3549,7780,7324,2599}),
STMRecord("../SuperTrackmasters/140_V_Multilap_euronics.riolu!(02'58''05)",{6650,7903,3684,6374,6985,5199,5480,6467,5438,6711,4398,7822,3872,6434,6931,5197,5467,6459,5354,6694,4385,7829,3692,6414,6961,5206,5476,6473,5385,6716}),
STMRecord("../SuperTrackmasters/141_L_Discovery_euronics.riolu!(00'40''93)",{8837,4128,5453,3978,4421,3051,4669,3013,3384}),
STMRecord("../SuperTrackmasters/142_L_Speed_PuffBros~Paco.(00'38''12)",{5458,7169,5071,6658,2741,2901,2827,2888,2412}),
STMRecord("../SuperTrackmasters/143_L_ShowOff_euronics.riolu!(00'57''12)",{8288,3977,4500,4813,3343,4121,3829,3187,2700,7859,3339,7167}),
STMRecord("../SuperTrackmasters/144_L_Tech FINAL_euronics.riolu!(00'58''26)",{6577,4519,3248,3326,6507,4670,5878,5031,4528,4751,4788,3105,1337}),
STMRecord("../SuperTrackmasters/145_L_Multilap FINAL_euronics.riolu!(02'45''99)",{8068,5920,3332,7975,6032,4407,4367,2850,5355,8372,6266,5857,3327,7926,5991,4437,4396,2838,5359,8318,6133,5815,3325,7928,6003,4428,4383,2800,5414,8376}),
STMRecord("../SuperTrackmasters/146_L_Discovery_euronics.riolu!(00'47''18)",{6260,3117,3478,3163,3270,3006,3996,3681,2705,5832,4129,4549}),
STMRecord("../SuperTrackmasters/147_L_Speed_euronics.riolu!(00'57''28)",{6138,8719,3377,2617,3676,6948,8083,5866,9604,2255}),
STMRecord("../SuperTrackmasters/148_L_ShowOff_euronics.riolu!(00'52''64)",{6993,5681,3592,3851,9781,7234,4833,10676}),
STMRecord("../SuperTrackmasters/148_L_ShowOff FINAL_euronics.riolu!(00'38''97)",{7208,2287,2516,5064,5883,8803,7214}),
STMRecord("../SuperTrackmasters/150_V_Multilap FINAL_euronics.riolu!(02'50''11)",{9247,4108,8027,3828,3443,4768,7021,2624,3206,4134,3955,4512,6619,3761,7761,3774,3524,4700,7022,2638,3205,4144,3597,4089,6526,3727,7726,3800,3451,4775,7055,2641,3170,4124,4362,5051}),
STMRecord("../SuperTrackmasters/151_S_Discovery_acer _ racehans(00'49''99)",{6800,4774,6353,4655,7511,4515,2914,3850,4146,4475}),
STMRecord("../SuperTrackmasters/152_S_Speed FINAL_acer _ racehans(00'40''64)",{8878,7290,2448,3492,743,7027,4137,255,1316,2374,2688}),
STMRecord("../SuperTrackmasters/153_S_ShowOff FINAL_acer _ racehans(00'38''02)",{5370,4584,334,337,3035,916,2085,3684,3781,247,249,3855,5823,3720}),
STMRecord("../SuperTrackmasters/154_S_Tech_acer _ racehans(00'46''95)",{8158,5782,6272,8776,4203,6727,4989,2049}),
STMRecord("../SuperTrackmasters/155_S_Multilap_acer _ racehans(02'01''90)",{6118,8306,8183,2253,6755,9177,2444,2630,7921,8284,2295,6672,8978,2465,2637,7999,8201,2307,6640,9107,2529}),
STMRecord("../SuperTrackmasters/156_S_Discovery FINAL_acer _ racehans(00'43''02)",{9148,3443,2987,6757,6715,6773,7201}),
STMRecord("../SuperTrackmasters/157_S_Speed FINAL_acer _ racehans(00'47''19)",{8697,4674,5009,6996,3269,4108,2220,4748,7471}),
STMRecord("../SuperTrackmasters/158_S_ShowOff FINAL_acer _ racehans(00'41''69)",{5488,7130,10975,3998,2195,4204,7706}),
STMRecord("../SuperTrackmasters/159_S_SpeedTech FINAL_acer _ racehans(01'09''21)",{7208,3964,5522,5910,6514,4147,5773,7286,9870,7423,5033,560}),
STMRecord("../SuperTrackmasters/160_S_Multilap_eSuba.tween(02'52''65)",{12894,2710,12592,2076,2708,2354,3794,5503,5673,3717,6862,7762,2511,12675,2123,2721,2353,3798,5628,5857,3717,6848,7745,2523,12766,2178,2725,2353,3800,5550,5662,3687,6791}),
STMRecord("../SuperTrackmasters/161_C_Discovery_euronics.riolu!(01'05''13)",{9378,6370,4992,4303,6885,5560,4017,6723,5299,7700,3903}),
STMRecord("../SuperTrackmasters/162_C_Speed_euronics.riolu!(00'49''30)",{5810,6531,8574,6840,8965,3695,873,909,970,1047,2673,2421}),
STMRecord("../SuperTrackmasters/163_C_ShowOff_euronics.riolu!(00'41''48)",{9152,5945,8501,3863,4639,4630,4757}),
STMRecord("../SuperTrackmasters/164_C_Tech_Nova.Zypher (01'09''90)",{9280,5096,6152,5120,8530,7653,9414,9386,9277}),
STMRecord("../SuperTrackmasters/165_C_Multilap_Nova.Zypher (03'23''01)",{8442,7586,4912,4061,4849,10185,5627,4810,5972,7010,5325,6764,7533,4904,4072,4725,10115,5600,4814,6032,7084,5364,6688,7744,4933,4047,4779,10368,5461,4805,6141,7046,5215}),
STMRecord("../SuperTrackmasters/166_C_Discovery_Nova.Zypher (01'10''50)",{8991,6141,6495,7588,7140,8183,7067,6806,6739,5354}),
STMRecord("../SuperTrackmasters/167_C_Speed_euronics.riolu!(00'55''99)",{8128,2712,5381,5724,5636,6935,7231,4907,6458,2881}),
STMRecord("../SuperTrackmasters/168_C_ShowOff_euronics.riolu!(00'54''42)",{7096,5691,4046,3194,2148,5016,3025,3867,2725,8036,2731,4500,2351}),
STMRecord("../SuperTrackmasters/169_C_SpeedTech_euronics.riolu!(01'37''17)",{12847,5296,9021,5817,9196,5401,6426,10291,6152,17835,5803,3093}),
STMRecord("../SuperTrackmasters/170_C_Multilap FINAL_euronics.riolu!(02'01''19)",{12194,2829,4889,5694,5974,4332,9451,5371,5492,10730,4837,2282,9646,7940,10355,10285,8894}),
STMRecord("../SuperTrackmasters/171_V_Discovery_euronics.Marius89(01'08''69)",{11945,7003,8769,9475,2897,2713,5325,5969,5366,6379,2857}),
STMRecord("../SuperTrackmasters/172_V_Speed_euronics.riolu!(00'57''94)",{10382,4732,4053,9931,3658,5252,8906,6170,4856}),
STMRecord("../SuperTrackmasters/173_V_ShowOff_〜ИєΫσ-8826(01'31''10)",{10608,7486,3833,11843,3744,7477,3924,10380,8249,6834,8499,8227}),
STMRecord("../SuperTrackmasters/174_V_Tech_〜ИєΫσ-8826(00'51''80)",{9238,9493,11222,10911,8462,2478}),
STMRecord("../SuperTrackmasters/175_V_Multilap_euronics.riolu!(03'18''68)",{9185,10586,4476,3278,3414,3413,7873,4104,5624,4074,5374,6501,6850,10646,4456,3268,3460,3428,7856,4156,5533,4104,5326,6524,6828,10620,4458,3286,3379,3424,7864,3880,5661,4072,5293,6407}),
STMRecord("../SuperTrackmasters/176_V_Discovery_euronics.Marius89(01'33''75)",{10308,5340,4547,5825,5270,5038,4154,5029,5168,5618,3971,5925,8065,9995,9500}),
STMRecord("../SuperTrackmasters/177_V_Speed_〜ИєΫσ-8826(00'57''78)",{8422,2723,7403,5133,1679,5698,6350,4923,3484,5711,6260}),
STMRecord("../SuperTrackmasters/178_V_ShowOff_euronics.Santa89(01'25''24)",{11461,7184,7146,9982,6110,6607,11373,6901,13466,5018}),
STMRecord("../SuperTrackmasters/179_V_SpeedTech_euronics.riolu!(01'50''97)",{9348,6857,6228,4708,5929,4508,5087,4363,9410,2771,6045,10346,6597,9990,8101,10687}),
STMRecord("../SuperTrackmasters/180_V_Multilap FINAL_euronics.riolu!(01'45''60)",{13951,4957,9634,13371,7181,5754,7819,9305,7835,6511,9067,10223}),
STMRecord("../SuperTrackmasters/181_L_Discovery_euronics.riolu!(01'04''44)",{6013,2602,5704,4510,3680,4509,8227,3148,3687,5723,6364,4798,5475}),
STMRecord("../SuperTrackmasters/182_L_Speed_euronics.riolu!(00'55''44)",{6648,3717,3720,3303,5133,3861,4830,8390,15842}),
STMRecord("../SuperTrackmasters/183_L_ShowOff_euronics.riolu!(00'45''34)",{8265,6553,2577,1390,2925,8142,4306,3527,3166,2549,1948}),
STMRecord("../SuperTrackmasters/184_L_Tech_euronics.riolu!(01'11''74)",{5678,6745,7088,8601,7195,6431,5412,4748,8639,3171,6077,1958}),
STMRecord("../SuperTrackmasters/185_L_Multilap FINAL_euronics.riolu!(03'50''43)",{6643,2872,4267,7073,6066,3253,7717,6312,4882,7026,8592,5540,3002,4680,4809,2746,4144,7038,6039,3231,7913,6403,4917,7053,8625,5659,3005,4665,4798,2745,4136,7001,6115,3245,7781,6382,4945,7046,8652,5674,3029,4714}),
STMRecord("../SuperTrackmasters/186_L_Discovery_euronics.riolu!(01'29''35)",{7297,4673,7079,3482,3983,3777,4221,7306,4310,3794,2625,2785,3280,5942,9583,4743,4388,6088}),
STMRecord("../SuperTrackmasters/187_L_Speed_euronics.riolu!(00'55''47)",{11176,4004,4501,5240,5514,5533,4584,4329,5911,4680}),
STMRecord("../SuperTrackmasters/188_L_ShowOff_euronics.riolu!(01'45''35)",{10252,3671,3441,5236,7538,4802,3996,3372,3663,3100,7141,4324,3448,5114,3323,1804,3780,6776,8850,3681,1968,6070}),
STMRecord("../SuperTrackmasters/189_L_SpeedTech_euronics.riolu!(01'05''15)",{13072,3514,2371,5201,3813,4076,5499,4355,6304,2700,3356,6066,4829}),
STMRecord("../SuperTrackmasters/190_L_Multilap FINAL_euronics.riolu!(01'39''29)",{10920,3978,3027,3945,3798,4406,6056,2702,4100,4973,5065,8315,8180,5792,3674,3920,8073,8371}),
STMRecord("../SuperTrackmasters/191_S_Discovery_eSuba.tween(01'04''58)",{7401,4684,4837,6626,5607,5320,5398,5481,4190,2941,3273,4145,4685}),
STMRecord("../SuperTrackmasters/192_S_Speed FINAL_acer _ racehans(00'54''84)",{6048,7556,1824,4252,3830,6808,2836,4863,6163,5561,5101}),
STMRecord("../SuperTrackmasters/193_S_ShowOff_acer _ racehans(00'49''04)",{5601,6640,4295,3557,6002,3989,5213,5749,5402,379,384,387,1448}),
STMRecord("../SuperTrackmasters/194_S_Tech FINAL_acer _ racehans(00'51''14)",{5228,316,317,322,1654,4374,3912,4382,6703,5640,6412,353,358,362,1800,5834,3174}),
STMRecord("../SuperTrackmasters/195_S_Multilap_acer _ racehans(03'14''06)",{6703,305,310,312,1252,4890,3965,4211,4772,497,505,2529,5144,4222,4701,3927,7837,5720,3937,4869,303,304,308,1253,5061,4091,4212,4698,496,503,2518,5043,4144,4726,4034,7870,5665,4024,5026,304,306,309,1252,4875,4115,4197,4690,496,503,2516,5070,4238,4937,3972,7821,5696,3877}),
STMRecord("../SuperTrackmasters/196_S_Discovery_eSuba.tween(01'01''85)",{5948,5507,5143,4584,4565,5136,6419,6052,4214,6396,7893}),
STMRecord("../SuperTrackmasters/197_S_Speed_eSuba.tween(00'58''54)",{8078,6953,9925,2056,6009,5079,4224,778,246,1249,4077,3101,1111,5662}),
STMRecord("../SuperTrackmasters/198_S_ShowOff FINAL_eSuba.tween(00'43''97)",{5844,4363,4847,6381,3768,2075,1455,8672,6566}),
STMRecord("../SuperTrackmasters/199_S_SpeedTech FINAL_eSuba.tween(00'54''69)",{4738,2797,729,1773,7560,851,1462,2228,1840,3552,3730,808,1416,7957,3795,2130,4419,2913}),
STMRecord("../SuperTrackmasters/200_S_Multilap FINAL_eSuba.tween(01'03''77)",{9498,9349,5397,2791,366,370,373,379,382,3756,5135,3969,3702,1844,6110,5137,5218})
};
#endif