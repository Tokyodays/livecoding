//==== 1. SuperCollider基本 =====

{SinOsc.ar()}.play; //hello world

{SinOsc.ar(880).dup}.play; //ステレオ化、周波数変更

// 1.1 楽器定義 (SynthDef)
(
SynthDef("testsynth",
	{
		var sound;
		sound = SinOsc.ar(880).dup;
		Out.ar(0, sound);
	}
).add;
)
// 1.2 定義した楽器の演奏
Synth("testsynth");

//引数
(
SynthDef("testsynth",
	{
		arg freq = 440;
		var sound;
		sound = SinOsc.ar(freq).dup;
		Out.ar(0, sound);
	}
).add;
)

//引数を指定して演奏
Synth("testsynth", ["freq", 220]);

//==== 2. SuperDirtの楽器へ! =====

// 2.1 シンプルな楽器
(
SynthDef("testsynth", {
    arg out;
    var sound = SinOsc.ar(440.0);
    OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, 0.5));
}).add;
)

// 2.2 定位(pan)と音の持続時間(sustain)を設定
(
SynthDef("testsynth",
  {
   arg out=0, sustain=1.0, pan=0.5;
   var sound, env;
   sound = SinOsc.ar(440);
   env = EnvGen.ar(Env.adsr(0.01, 0.3, 0.5, 1.0),
     timeScale:sustain, doneAction:2);
   OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
} ).add;
)

// 2.3 音程(freq)の設定の追加
(
SynthDef("testsynth",
  {
   arg out=0, freq=440, sustain=1.0, pan=0.5;
   var sound, env;
   sound = SinOsc.ar(freq).dup;
   env = EnvGen.ar(Env.adsr(0.01, 0.3, 0.5, 1.0),
         timeScale:sustain, doneAction:2);
   OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
} ).add;
)

// 2.4 パーカッシブなエンベロープへ
(
SynthDef("testsynth",
  {
   arg out=0, freq=440, sustain=1.0, pan=0.5;
   var sound, env;
   sound = SinOsc.ar(freq).dup;
   env = EnvGen.ar(Env.perc(),
         timeScale:sustain, doneAction:2);
   OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
} ).add;
)

// 2.5 TR-808風のシンセドラム
(
SynthDef("test808",
  {
   arg out, speed=1, sustain=1, pan, voice=0, n;
   var env, sound, freq;
   n = ((n>0)*n) + ((n<1)*3);
   freq = (n*10).midicps;
   env = EnvGen.ar(Env.linen(0.01, 0, 1, 1, -3), timeScale:sustain, doneAction:2);
   sound = LPF.ar(SinOscFB.ar(XLine.ar (freq.expexp(10, 2000, 1000, 8000), freq, 0.025/speed), voice), 9000);
   OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add
)