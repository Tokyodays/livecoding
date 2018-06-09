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
);

~oscBus = Bus.control(s,1);

(
SynthDef(\bussynth, {|val|
	Out.kr(~oscBus,val);
}).add
);

(
    OSCdef.new(\median, { arg msg, time, addr, recvPort;
    	if (msg[1] == 0, {
    		if (a.isNil) {
    			a = Synth(\bussynth,[\val , msg[2]]);
    		} {
    		a.set(\val, msg[2])
    		}
    	});
    }, '/bowdir', NetAddr("127.0.0.1"), 7563
    )
);

(
    SynthDef(\violin, { |out, sustain = 1, speed = 1, begin = 0, end = 1, pan, accelerate, offset, string = 0|
    	var env, sound, rate, phase, bowdir;
    	phase = Line.ar(begin, end, sustain);
    	rate = (begin + 1) * (speed + Sweep.kr(1, accelerate));
    	string = string + 20;
    	bowdir = In.kr(~oscBus,1);
    	bowdir.poll;
    	sound = SoundIn.ar([string]);
    	OffsetOut.ar(out,
    		DirtPan.ar(sound, ~dirt.numChannels, pan)
    	)
    }).add
);

// tuning fork
// from my own experimentation and from "On the acoustics of tuning forks", Rossing Russell and Brown
(
SynthDef(\superfork, {|out, sustain=1, pan, freq, accelerate=0|
	var sound, env;
	freq = freq * Line.kr(1, 1+accelerate, sustain);
	env = EnvGen.ar(Env.linen(0.001, 0.998, 0.001), timeScale:sustain, doneAction:2);
	sound = 0.2 * SinOsc.ar([1.0, 6.1, 16.7, 20.1] * freq) * XLine.ar([0.3, 1, 1.3, 2], [1e-4, 1e-7, 1e-6, 1e-7], sustain*[4,4,0.5,0.333]);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// hammond B3 sim
// freq adjustments courtesy Tom Wiltshire (electricdruid.net)
// drawbar settings selectable with "voice" and from many public domain sources,
// Google "Hammond drawbar settings" and add your own in the big SelectX block
// "perc" "percf" and "decay" are an attempt at the percussion, no idea if it sounds at all reasonable
// vintage Hammonds had percf as 2 or 3 (switchable), two perc levels (maybe roughly 0.7 and 1.2?),
// and two decay options (roughly 0 and maybe 1ish?)/
// "vibrato", "vrate", "perc", "percf" are all new params you'll need to define in Tidal if you want to change them
(
SynthDef(\superhammond, {|out, sustain=1, decay=0, pan, freq, vibrato=0.5, vrate=7,
	voice=0, perc=0, percf=2 |
	var freqs, amps, sound, click, env, ampscale, attrel;
	attrel = (sustain/2).clip(0,0.005);
	env = EnvGen.ar(Env.linen(attrel, sustain-(2*attrel), attrel), doneAction:2);
	freqs = [0.5, 1.4988, 1, 2, 2.9976, 4, 5.0409, 5.9953, 8] * freq;
	freqs = 2**(freqs < 63) * freqs; // fold up bottom register
	freqs = freqs / (2**(freqs > 6000)); // fold down high harmonics
	freqs = freqs / (2**(freqs > 6000)); // do it again for the really high notes
	amps = SelectX.kr(voice, #[
		[1, 4, 5, 4, 3, 1, 0, 0, 0], // 0: bass violin 16'
		[0, 0, 8, 0, 4, 0, 0, 0, 0], // 1: tibia 8'
		[0, 7, 8, 1, 2, 0, 0, 0, 0], // 2: bassoon 8'
		[0, 0, 7, 8, 8, 8, 8, 7, 2], // 3: french trumpet 8'
		[4, 0, 5, 5, 4, 5, 3, 3, 6], // 4: string ensemble
		[8, 8, 5, 3, 2, 4, 5, 8, 8], // 5: Blues
		[8, 8, 8, 0 ,0, 0, 0, 0, 3], // 6: Jazz 1
		[8, 8, 8, 8, 8, 8, 8, 8, 8], // 7: Full Shout
		[8, 0, 0, 0, 0, 0, 8, 8, 8], // 8: Bro' Jack
		[0, 0, 8, 8, 0, 0, 0, 0, 0]  // 9: Jazz 2
	]);
	amps = amps - [0, 0, 0, 0, 0, 0, 0.5, 1, 1.5]; // damp brilliance a bit
	amps = 2**(amps-8);
	click = WhiteNoise.ar(1) * XLine.ar(1,1e-6, 0.1);
	sound = 0.5 * Mix.ar( SinOsc.ar(freqs*(2*click+1), (2pi ! 9).rand, amps/amps.sum) );
	sound = perc * 0.5 * SinOsc.ar(freq*percf, 2pi.rand) * XLine.ar(1,1e-6,2*decay+1) + sound;
	sound = sound + BAllPass.ar(sound, 1000*LFTri.kr(vrate,0,vibrato/2,1));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// vibraphone simulation, adapted with some help from Kevin Larke's thesis Real Time Vibraphone Pitch and Timbre Classification
// "decay" - use larger values to damp higher harmonics (default 0)
// "velocity" - higher velocity will brighten the sound a bit (default 1)
// "accelerate" - for a linear pitch bend
// "modamp" - amplitude of the tremolo (0-2 is OK, default 1)
// "modfreq" - frequency of the tremolo (default 7)
// "detune" - adjusts a high harmonic to give the sound a different character
(
SynthDef(\supervibe, {|out, sustain=1, decay=0, pan, freq, accelerate=0, velocity=1,
	modamp=1, modfreq=7.0, detune=0 |
	// most envelope shaping is done with XLines later, this envelope is just to clean up overall
	var env = EnvGen.ar(Env.linen(0.001, 0.998, 0.001), timeScale:sustain, doneAction:2);
	var sound, mod, freqs, hifreqs, decays;
	freqs = freq * Line.kr(1, 1+accelerate, sustain) * [1, 4, 10, 13.75+detune];
	hifreqs = freq * Line.kr(1, 1+accelerate, sustain) * [19.2, 20, 21.2];
	mod = SinOsc.kr(modfreq, Rand(0,2pi)).range(1-([0.5,0.3,0.3,0.5]*modamp),1);
	sound = 0.3 * [1, 1.1*velocity, 0.6*velocity*velocity, 0.5*velocity] * SinOsc.ar(freqs);
	decays = [1, 0.7*exp(-1.0*decay), 0.5*exp(-1.0*decay), 0.4*exp(-1.0*decay)];
	sound = XLine.ar(1e-6, 1, 1/freqs) * XLine.ar(1, 1e-6, decays*4*sustain) * sound * mod; // main attacks and decays
	sound = (XLine.ar(0.3*(velocity+1e-6),1e-6,0.02) * SinOsc.ar(hifreqs)).sum + sound.sum; // hi frequency onset
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add
);


// Hoover, adapted from Wouter Snoei's
// http://superdupercollider.blogspot.com/2009/06/more-dominator-deconstruction.html
// "slide" is used for the amount of initial pitch glide, positive slides up in pitch, negative slides down
// also responds to "decay" for a different envelope shape and "accelerate" for constant pitch glide
// uncomment the two lines with "rrand" for a different every time you evaulate it
(
SynthDef(\superhoover, {|out, sustain=1, decay=0, pan, freq, accelerate=0, slide=0|
	var env = EnvGen.ar(Env.pairs([[0,0],[0.03,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -1), timeScale:sustain, doneAction:2);
	var pwm, mix, fglide;
	fglide = EnvGen.ar(Env.perc(0.05, 0.3, 1, \lin), timeScale:sustain) * (-1*slide/4) + 1;
	freq = freq * fglide * Line.kr(1, 1+accelerate, sustain);
	freq = SinOsc.kr( [2.94, 3.0, 3.07], [3.0, 5.5, 1.2] ).exprange(0.995, 1.005) * freq;
	// freq = SinOsc.kr( {2.9 rrand: 3.1}!3, {2pi.rand}!3 ).exprange(0.995, 1.005) * freq;
	pwm = SinOsc.kr( [1.3, 2.9, 4.4] ).range(1/8, 7/8);
	// pwm = SinOsc.kr( {1.0 rrand: 5.0}!3 ).range(1/8, 7/8);
	mix = ([1,0.9,1.1]*LFSaw.ar(freq*[0.25, 0.5, 1], [1, 1.01, 1.02]).range(0,1) * (1 - LFPulse.ar(freq*[0.5,1,2], [0,0,0], pwm))).sum * 0.15;
	mix = mix + LFPar.ar(freq * 0.25, 0, 0.1).sum;
	mix = BPeakEQ.ar(mix, 6000, 1, 3);
	mix = BPeakEQ.ar(mix, 3500, 1, 6);
	mix = mix.dup + CombC.ar(mix.dup, 1/200, SinOsc.kr(3, [0.5pi, 1.5pi]).range(1/300, 1/200), 0);
	OffsetOut.ar(out, DirtPan.ar(1.4*mix, ~dirt.numChannels, pan, env));
}).add
);


// phased saws
// "decay" and "accelerate" used as in some synths above, for envelope shaping and pitch bend, respectively
// "slide" here is how fast it moves through the phase (default 1)
// "detune" is for oscillator detuning and defaults to 1
(
SynthDef(\superzow, {|out, sustain=1, pan, accelerate, freq, decay=0, slide=1, detune=1 |
	var env = EnvGen.ar(Env.pairs([[0,0],[0.07,1],[0.2,1-decay],[0.95,1-decay],[1,0]], -1), timeScale:sustain, doneAction:2);
	var basefreq = freq * Line.kr(1, 1+accelerate, sustain);
	var sound = VarSaw.ar(basefreq, 0, Line.ar(0,0.5,sustain*20/slide));
	var sound2 = VarSaw.ar(basefreq*(detune/100+1), 0, Line.ar(0,0.5,sustain*20/slide));
	var sound3 = VarSaw.ar(basefreq*(-1*detune/100+1), 0, Line.ar(0,0.5,sustain*20/slide));
	sound = sound - DelayN.ar(sound2,0.2, Line.ar(0,1,5*sustain/slide)/basefreq)
	  + DelayN.ar(sound3,0.2, Line.ar(0,1,20*sustain/slide)/basefreq);
	OffsetOut.ar(out, DirtPan.ar(sound/2, ~dirt.numChannels, pan, env));
}).add
);


// impulse noise with a fadein/out
(
SynthDef(\superstatic, {|out, sustain=1, pan, freq |
	var env = EnvGen.ar(Env.sine(1, 0.5), timeScale:sustain, doneAction:2);
	var sound = Dust.ar(freq*40) > 0.5;
	sound = Pulse.ar(freq*sound*4,0.5,0.5);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add
);
