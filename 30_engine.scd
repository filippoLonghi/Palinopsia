(
/////////////////////// STATE & GLOBALS
~slicePool = List.new;
~lastSlice = nil;
~sliceIdx = 0;
~recSynth  = nil;
~recStartTime = 0;

~recMix = 0;
~sampleFx = nil;

~fCtrls = Dictionary.new;
~rCtrls = Dictionary.new;
~hCtrls = Dictionary.new;
~gCtrls = Dictionary.new;
~sCtrls = Dictionary.new;
~dCtrls = Dictionary.new;

~fshiftFx  = nil;
~ringFx    = nil;
~harmFx    = nil;
~harmPointer = nil;
~harmRec   = nil;
~grainFx   = nil;
~sliceRoutine = nil;
~delayFx   = nil;

~ampBase = Dictionary.newFrom([
	\fshift, 0.5, \ring, 0.5, \harm, 0.5, \delay, 0.5, \grain, 0.5, \slice, 0.5
]);

~syncMult = 1.0;
~asyncMult = 1.0;
~masterMult = 1.0;

~syncList  = [\fshift, \ring, \harm, \delay];
~asyncList = [\grain, \slice];

/////////////////////// INIT PIECE
~pieceInit = {
	//[~fCtrls, ~gCtrls, ~rCtrls, ~sCtrls, ~dCtrls].do({ |dict|
    //    dict.do(_.free);
    //    dict.clear;
    //});

    if(~source.notNil) { ~source.free; };
    ~source = Synth(\mic, [\busIn, 0, \busOut, ~micBus, \amp, 1], ~micGrp);

    if(~slicePool.isEmpty) {
        ~lastSlice = Buffer.alloc(s, s.sampleRate * 1, 1);
    } {
        ~lastSlice = ~slicePool.last;
    };

	// --- INIZIALIZZAZIONE BUS FREQUENCY SHIFTER (~fBuses) ---
	~fBuses[\fshift].set(30);
	~fBuses[\mix].set(0.3);
	~fBuses[\amp].set(0);

	// --- INIZIALIZZAZIONE BUS RING MODULATION (~rBuses) ---
	~rBuses[\fmod].set(440);
	~rBuses[\idx].set(0.5);
	~rBuses[\amp].set(0.5);

	// --- INIZIALIZZAZIONE BUS HARMONIZER (~hBuses) ---
    ~hBuses[\amp].set(0.5);
    ~hBuses[\trig].set(0); // --- PROMEMORIA: Attiva i trigger live per generare il suono ---
    ~hBuses[\trsp].set(0);
    ~hBuses[\gdur].set(0.15);

	// --- INIZIALIZZAZIONE BUS RING MODULATION (~rBuses) ---
	~gBuses[\amp].set(0.5);
	~gBuses[\gdur].set(0.15);
	~gBuses[\pos].set(0.1);
    ~gBuses[\trsp].set(0);
	~gBuses[\trig].set(0); // --- PROMEMORIA: Attiva i trigger live per generare il suono (Impulse) ---

	// --- INIZIALIZZAZIONE BUS SLICING (~sBuses) ---
    ~sBuses[\pos].set(0.1);
	~sBuses[\dur].set(0.4);
	~sBuses[\wait].set(0.2);
    ~sBuses[\amp].set(0.5);
	~sBuses[\trsp].set(0);
	~sBuses[\dir].set(1);

	// --- INIZIALIZZAZIONE BUS DELAY (~dBuses) ---
    ~dBuses[\del].set(0.3);
	~dBuses[\mix].set(0.0);
	~dBuses[\decayT].set(2.0);
    ~dBuses[\fbk].set(0.5);
	~dBuses[\rate].set(1.0);
	~dBuses[\amp].set(0.5);

	~recMix = 0;

	~syncMixer.(1.0);
    ~asyncMixer.(1.0);
    ~masterMixer.(1.0);

    "PIECE MODE READY: Tutti i bus di controllo inizializzati.".postln;
};

/////////////////////// FX LOGICs

/////////////////////// SYNC FX: FSHIFT

~fshiftCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~fBuses[param];
    if(~fCtrls[param].notNil) { ~fCtrls[param].free; ~fCtrls[param] = nil; };

    if(type == -1) {
        bus.set(val);
        (param ++ " -> STATIC: " ++ val).postln;
    } {
        ~fCtrls[param] = Synth(\ksig, [
            \type, type, \range, range, \freq, freq, \busOut, bus
        ], ~recGrp);
        (param ++ " -> MODULATED (Type " ++ type ++ ")").postln;
    };
};

~fshiftOn = {
    if(~fshiftFx.notNil) { ~fshiftFx.set(\gate, 0); };

    ~fshiftFx = Synth(\fshift, [
        \busIn, ~micBus,
        \busOut, 0,
        \fshift, ~fBuses[\fshift].asMap,
        \mix,    ~fBuses[\mix].asMap,
        \amp,    ~fBuses[\amp].asMap,
        \gate, 1
    ], ~fxGrp);

    "FSHIFT ON (Consistent with Ring/Grain)".postln;
};

~fshiftOff = { if(~fshiftFx.notNil) { ~fshiftFx.set(\gate, 0); ~fshiftFx = nil; "FSHIFT OFF".postln; } };

/////////////////////// SYNC FX: RING MODULATION

~ringCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~rBuses[param];
    if(~rCtrls[param].notNil) { ~rCtrls[param].free; ~rCtrls[param] = nil; };

    if(type == -1) {
        bus.set(val);
        (param ++ " -> STATIC: " ++ val).postln;
    } {
        ~rCtrls[param] = Synth(\ksig, [
            \type, type, \range, range, \freq, freq, \busOut, bus
        ], ~recGrp);
        (param ++ " -> MODULATED (Type " ++ type ++ ")").postln;
    };
};

~ringOn = {
    if(~ringFx.notNil) { ~ringFx.set(\gate, 0); };

    //if(~rCtrls[\fmod].isNil) { ~ringCtrl.(\fmod, type: -1, val: 440); };
    //if(~rCtrls[\idx].isNil)  { ~ringCtrl.(\idx,  type: -1, val: 0.5); };
    //if(~rCtrls[\amp].isNil)  { ~ringCtrl.(\amp,  type: -1, val: 0.5); };

    ~ringFx = Synth(\ring, [
        \busIn, ~micBus,
        \busOut, 0,
        \fmod, ~rBuses[\fmod].asMap,
        \idx,  ~rBuses[\idx].asMap,
        \amp,  ~rBuses[\amp].asMap,
        \gate, 1
    ], ~fxGrp);
    "RING MODULATION ON".postln;
};

~ringOff = { if(~ringFx.notNil) { ~ringFx.set(\gate, 0); ~ringFx = nil; "RING OFF".postln; } };


/////////////////////// SYNC FX: HARMONIZER (GRANULAR)

~harmCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~hBuses[param];
    if(~hCtrls[param].notNil) { ~hCtrls[param].free; ~hCtrls[param] = nil; };
    if(type == -1) {
        bus.set(val);
    } {
        ~hCtrls[param] = Synth(\ksig, [\type, type, \range, range, \freq, freq, \busOut, bus], ~recGrp);
    };
};

~harmOn = {
    if(~harmFx.notNil) { ~harmOff.value; };
    ~harmPointer = Synth(\pos, [\buf, ~blive, \busOut, ~kpos], ~micGrp);
    ~harmRec = Synth(\syncrec, [\busIn, ~micBus, \busPos, ~kpos, \buf, ~blive], ~recGrp);
    ~harmFx = Synth(\gharm, [
        \buf, ~blive,
        \busOut, 0,
        \busPos, ~kpos,
        \trig, ~hBuses[\trig].asMap, // Usa ~hBuses
        \trsp, ~hBuses[\trsp].asMap, // Usa ~hBuses
        \gdur, ~hBuses[\gdur].asMap, // Usa ~hBuses
        \amp,  ~hBuses[\amp].asMap,  // Usa ~hBuses
        \gate, 1
    ], ~fxGrp);
    "HARMONIZER (SYNC) ON".postln;
};

~harmOff = {
    if(~harmFx.notNil) { ~harmFx.set(\gate, 0); ~harmFx = nil; };
    if(~harmPointer.notNil) { ~harmPointer.free; ~harmPointer = nil; };
    if(~harmRec.notNil) { ~harmRec.free; ~harmRec = nil; };
    "HARMONIZER OFF".postln;
};


/////////////////////// LOGICA DI REGISTRAZIONE

~recStart = { |mode=nil|
	var mix = mode ? ~recMix;
	if(~recSynth.notNil) { "Registrazione già attiva.".warn; ^nil };

	if(mix == 1 && ~lastSlice.notNil) {
		// MODALITÀ SUM: registra sopra l'ultimo buffer esistente
		~recSynth = Synth(\rec, [
			\buf, ~lastSlice, \busIn, ~micBus, \mix, 1, \loop, 1, \done, 0
		], ~recGrp);
		"OVERDUBBING (Summing) in corso...".postln;
	} {
		// MODALITÀ REPLACE: crea un nuovo buffer temporaneo
		Buffer.alloc(s, s.sampleRate * 60, 1, { |buf|
			~tempBuf = buf;
			~recStartTime = Main.elapsedTime;
			~recSynth = Synth(\rec, [
				\buf, ~tempBuf, \busIn, ~micBus, \mix, 0, \loop, 0, \done, 0
			], ~recGrp);
			"NUOVA REGISTRAZIONE (Replace) in corso...".postln;
		});
	};
};

~recStop = {
	var recNode = ~recSynth, temp = ~tempBuf, start = ~recStartTime;
	if(~recSynth.isNil) { "Nessuna registrazione attiva.".warn; ^nil };

	~recSynth = nil; ~tempBuf = nil;

	{
		recNode.free;
		s.sync;

		if(temp.notNil) {

			var dur = (Main.elapsedTime - start).max(0.1);
			var frames = (dur * s.sampleRate).asInteger;
			var finalBuf = Buffer.alloc(s, frames, 1);
			s.sync;
			temp.copyData(finalBuf, 0, 0, frames);
			s.sync;
			temp.free;
			~lastSlice = finalBuf;
			~slicePool.add(finalBuf);
			if(~grainFx.notNil) { ~grainFx.set(\buf, finalBuf.bufnum) };
			("SALVATO Pool[" ++ (~slicePool.size-1) ++ "] - " ++ dur.round(0.1) ++ "s").postln;
		} {

			"OVERDUB COMPLETATO sull'ultima slice.".postln;
		};
	}.fork(SystemClock);
};

~recordTimed = { |dur=2.5|
	~recStart.value;
	SystemClock.sched(dur, {
		~recStop.value;
		nil
	});
};


/////////////////////// LOGICA LETTURA BUFFER

SynthDef(\dryPlayer, { arg buf=0, amp=1, gate=1, loop=0, out=0;
	var sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), gate, 0, loop, doneAction: 2);
	var env = Linen.kr(gate, 0.01, 1, 0.1, doneAction: 2);
	Out.ar(out, sig ! 2 * env * amp);
}).add;

~sampleOn = { |index, loop=0, amp=0.8|
	if(~slicePool[index].notNil) {

		if(~sampleFx.notNil) {
			s.sendMsg("/n_set", ~sampleFx.nodeID, \gate, 0);
			~sampleFx = nil;
		};

		~sampleFx = Synth(\dryPlayer, [
			\buf, ~slicePool[index], \amp, amp, \loop, loop, \out, 0
		], ~fxGrp);


		~sampleFx.onFree({ ~sampleFx = nil });

		("PLAYING Dry Sample Pool[" ++ index ++ "] Loop:" ++ loop).postln;
	} { "Indice non trovato!".warn };
};

~sampleOff = {
	if(~sampleFx.notNil) {
		~sampleFx.set(\gate, 0);
		~sampleFx = nil;
		"Sample Player Stop".postln;
	};
};

~setRecMode = { |mode|
	~recMix = mode;
	("Recording Mode set to: " ++ if(mode > 0, "SUM", "REPLACE")).postln;
};


/////////////////////// ASYNC FX: GRAIN CLOUD

~grainCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~gBuses[param];

    if(~gCtrls[param].notNil) { ~gCtrls[param].free; ~gCtrls[param] = nil; };

    if(type == -1) {
        bus.set(val);
    } {
        ~gCtrls[param] = Synth(\ksig, [
            \type, type,
            \range, range,
            \freq, freq,
            \busOut, bus
        ], ~recGrp);
    };
};

~grainOn = {
    if(~lastSlice.isNil) { "Nessuna slice registrata.".warn; ^nil };
    if(~grainFx.notNil)  { ~grainFx.set(\gate, 0); };

    ~grainFx = Synth(\grain_1, [
        \buf, ~lastSlice.bufnum,
        \busOut, 0,
        \pos,  ~gBuses[\pos].asMap,
        \trig, ~gBuses[\trig].asMap,
        \gdur, ~gBuses[\gdur].asMap,
        \trsp, ~gBuses[\trsp].asMap,
        \amp,  ~gBuses[\amp].asMap,
        \gate, 1,
        \done, 2
    ], ~fxGrp);

    "SCALABLE GRANULATOR ON".postln;
};

~grainOff = {
    if(~grainFx.notNil) {
        ~grainFx.set(\gate, 0);
        ~grainFx = nil;
        "Sorgente sonora spenta. Modulatori attivi sui bus.".postln;
    };
};


/////////////////////// ASYNC FX: SLICING

~sliceCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~sBuses[param];
    if(~sCtrls[param].notNil) { ~sCtrls[param].free; ~sCtrls[param] = nil; };

    if(type == -1) {
        bus.set(val);
    } {
        ~sCtrls[param] = Synth(\ksig, [
            \type, type, \range, range, \freq, freq, \busOut, bus
        ], ~recGrp);
    };
};

~sliceOn = {
    if(~lastSlice.isNil) { "Nessuna slice registrata.".warn; ^nil };
    if(~sliceRoutine.notNil) { ~sliceRoutine.stop; };

    ~sliceRoutine = Routine({
        inf.do({
            Synth(\plbk, [
                \buf, ~lastSlice.bufnum,
                \busOut, 0,
                \pos, ~sBuses[\pos].getSynchronous * ~lastSlice.duration,
                \dur, ~sBuses[\dur].getSynchronous,
                \amp, ~sBuses[\amp].getSynchronous,
                \trsp, ~sBuses[\trsp].getSynchronous,
                \dir, if(~sBuses[\dir].getSynchronous > 0, 1, -1),
                //\pan, rrand(-0.8, 0.8),
                \t_gate, 1
            ], ~fxGrp);

            ~sBuses[\wait].getSynchronous.max(0.02).wait;
        });
    }).play;

    "ASYNCHRONOUS SLICING STARTED".postln;
};

~sliceOff = {
    if(~sliceRoutine.notNil) { ~sliceRoutine.stop; ~sliceRoutine = nil; };
    "ASYNCHRONOUS SLICING STOPPED".postln;
};


/////////////////////// DELAYs

~delayCtrl = { |param, type= -1, val=0.5, range= #[0, 1], freq=1|
    var bus = ~dBuses[param];
    if(~dCtrls[param].notNil) { ~dCtrls[param].free; ~dCtrls[param] = nil; };

    if(type == -1) {
        bus.set(val);
    } {
        ~dCtrls[param] = Synth(\ksig, [
            \type, type, \range, range, \freq, freq, \busOut, bus
        ], ~recGrp);
    };
};

~delayOn = { |type = \echo|
    if(~delayFx.notNil) { ~delayFx.set(\gate, 0); };

    ~delayFx = switch(type,
        \echo, {
            Synth(\echo, [
                \busIn, ~micBus, \busOut, 0,
                \del, ~dBuses[\del].asMap, \mix, ~dBuses[\mix].asMap,
                \amp, ~dBuses[\amp].asMap, \gate, 1
            ], ~fxGrp)
        },
        \fbk, {
            Synth(\del_2, [
                \busIn, ~micBus, \busOut, 0,
                \del, ~dBuses[\del].asMap, \decayT, ~dBuses[\decayT].asMap,
                \amp, ~dBuses[\amp].asMap, \gate, 1
            ], ~fxGrp)
        },
        \pingpong, {
            Synth(\pingpong, [
                \busIn, ~micBus, \busOut, 0,
                \del, ~dBuses[\del].asMap, \fbk, ~dBuses[\fbk].asMap,
                \amp, ~dBuses[\amp].asMap, \gate, 1
            ], ~fxGrp)
        },
        \vardel, {
            Synth(\vardel, [
                \busIn, ~micBus, \busOut, 0,
                \rate, ~dBuses[\rate].asMap, \decayT, ~dBuses[\decayT].asMap,
                \amp, ~dBuses[\amp].asMap, \gate, 1
            ], ~fxGrp)
        }
    );
    ("DELAY ON: " ++ type).postln;
};

~delayOff = { if(~delayFx.notNil) { ~delayFx.set(\gate, 0); ~delayFx = nil; "DELAY OFF".postln; } };


/////////////////////// LIVE VOLUME CONTROLS

~refreshAmp = { |key|
	var base = ~ampBase[key] ? 0.5;
	var layerMult = if(~syncList.includes(key), {~syncMult}, {~asyncMult});

	var finalVal = (base * layerMult * ~masterMult).clip(0, 10);

	switch(key,
		\fshift, { ~fshiftCtrl.(\amp, type: -1, val: finalVal) },
		\ring,   { ~ringCtrl.(\amp,   type: -1, val: finalVal) },
		\harm,   { ~harmCtrl.(\amp,   type: -1, val: finalVal) },
		\delay,  { ~delayCtrl.(\amp,  type: -1, val: finalVal) },
		\grain,  { ~grainCtrl.(\amp,  type: -1, val: finalVal) },
		\slice,  { ~sliceCtrl.(\amp,  type: -1, val: finalVal) }
	);
};

/////////////////////// LIVE VOLUME CONTROLS (Base Values)

~fshiftSetAmp = { |amp=0.5| ~ampBase[\fshift] = amp; ~refreshAmp.(\fshift); };
~ringSetAmp   = { |amp=0.5| ~ampBase[\ring]   = amp; ~refreshAmp.(\ring);   };
~harmSetAmp   = { |amp=0.5| ~ampBase[\harm]   = amp; ~refreshAmp.(\harm);   };
~grainSetAmp  = { |amp=0.5| ~ampBase[\grain]  = amp; ~refreshAmp.(\grain);  };
~sliceSetAmp  = { |amp=0.5| ~ampBase[\slice]  = amp; ~refreshAmp.(\slice);  };
~delaySetAmp  = { |amp=0.5| ~ampBase[\delay]  = amp; ~refreshAmp.(\delay);  };

/////////////////////// MASTER MIXER (Multipliers)

~syncMixer = { |factor=1.0|
	~syncMult = factor;
	~syncList.do({ |key| ~refreshAmp.(key) });
	("Sync Layer Multiplier -> " + factor).postln;
};

~asyncMixer = { |factor=1.0|
	~asyncMult = factor;
	~asyncList.do({ |key| ~refreshAmp.(key) });
	("Async Layer Multiplier -> " + factor).postln;
};

~masterMixer = { |factor=1.0|
	~masterMult = factor;
	(~syncList ++ ~asyncList).do({ |key| ~refreshAmp.(key) });
	("MASTER Volume Multiplier -> " + factor).postln;
};

//////// RECALL

~useSlice = { |index|
    if(~slicePool[index].notNil) {
        ~lastSlice = ~slicePool[index];
        if(~grainFx.notNil) { ~grainFx.set(\buf, ~lastSlice.bufnum) };

        if(~sliceRoutine.notNil) {
            ~sliceOff.();
            ~sliceOn.();
        };

        ("Now reading: ~slicePool[" ++ index ++ "]").postln;
    } { "Index not found!".warn };
};


/////////////////////// GUI CONTROL

if(~pieceWin.notNil) { ~pieceWin.close; };
~pieceWin = Window("PIECE MODE", Rect(200, 200, 560, 70)).front.alwaysOnTop_(true);
~pieceWin.view.keyDownAction_({ arg ... args;
    switch(args[1],

		// SHIFTER
        $f, { ~fshiftOn.() },
        $v, { ~fshiftOff.() },

		// RING MODULATION
        $a, { ~ringOn.() },
        $z, { ~ringOff.() },

        // HARMONIZER
        $h, { ~harmOn.() },
        $n, { ~harmOff.() },

		$r, { ~recordTimed.(5) },  // Registrazione fissa
		$i, { ~recStart.() },        // Registrazione manuale START
		$k, { ~recStop.() },         // Registrazione manuale STOP

		$u, { ~sampleOn.(~slicePool.size - 1, loop: 1) }, // Riproduce l'ultimo campione in loop
		$j, { ~sampleOff.value },                        // Ferma la riproduzione dry

		// Cambia modalità registrazione
		$q, { ~setRecMode.(0) }, // Replace
		$w, { ~setRecMode.(1) }, // Sum/Overdub

		// Recall rapidi per riproduzione dry buffer (Tasti Shift + Numero)
		$=, { ~sampleOn.(0) }, // Shift+0
		$!, { ~sampleOn.(1) },
		$", { ~sampleOn.(2) },
		$£, { ~sampleOn.(3) },
		$$, { ~sampleOn.(4) },
		$%, { ~sampleOn.(5) },

		$0, { ~useSlice.(0) },       // Richiama il primo buffer registrato
		$1, { ~useSlice.(1) },       // Richiama il secondo...
		$2, { ~useSlice.(2) },
		$3, { ~useSlice.(3) },
		$4, { ~useSlice.(4) },
		$5, { ~useSlice.(5) },
		$6, { ~useSlice.(6) },

		// GRANULATOR
        $g, { ~grainOn.() },
        $b, { ~grainOff.() },

		// SLICER
		$s, { ~sliceOn.() },
		$x, { ~sliceOff.() },

		// DELAY
		$e, { ~delayOn.(\echo) },     // Echo semplice
		$d, { ~delayOn.(\fbk) },      // Feedback Delay
		$p, { ~delayOn.(\pingpong) }, // Ping Pong
		$l, { ~delayOn.(\vardel) },   // Variable Time
		$c, { ~delayOff.() },
    );
});

~pieceInit.();
)