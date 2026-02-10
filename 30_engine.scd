(
/////////////////////// STATE & GLOBALS
~slicePool = List.new;
~lastSlice = nil;
~sliceIdx = 0;
~recSynth  = nil;
~recStartTime = 0;

~recMix = 0;
~sampleFx = nil;

~gCtrls    = ~gCtrls ? Dictionary.new;

~fshiftFx  = nil;
~grainFx   = nil;

~rCtrls = Dictionary.new;
~ringFx = nil;

~harmFx = nil;
~harmPointer = nil;
~harmRec = nil;

~sCtrls = Dictionary.new;
~sliceRoutine = nil;

~dCtrls = Dictionary.new;
~delayFx = nil;

/////////////////////// INIT PIECE
~pieceInit = {
    if(~source.notNil) { ~source.free; };
    ~source = Synth(\mic, [\busIn, 0, \busOut, ~micBus, \amp, 1], ~micGrp);

    if(~slicePool.isEmpty) {
        ~lastSlice = Buffer.alloc(s, s.sampleRate * 1, 1);
    } {
        ~lastSlice = ~slicePool.last;
    };

    // --- INIZIALIZZAZIONE BUS GRANULATORE / HARMONIZER (~gBuses) ---
    ~grainCtrl.(\amp,  type: -1, val: 0.5);
    ~grainCtrl.(\gdur, type: -1, val: 0.15);
    ~grainCtrl.(\pos,  type: -1, val: 0.5);
    ~grainCtrl.(\trsp, type: -1, val: 0);
    ~grainCtrl.(\trig, type: 4,  freq: 15);

    // --- INIZIALIZZAZIONE BUS RING MODULATION (~rBuses) ---
    ~ringCtrl.(\fmod, type: -1, val: 440);
    ~ringCtrl.(\idx,  type: -1, val: 0.5);
    ~ringCtrl.(\amp,  type: -1, val: 0.0);

    // --- INIZIALIZZAZIONE BUS SLICING (~sBuses) ---
    ~sliceCtrl.(\pos,  type: -1, val: 0.1);
    ~sliceCtrl.(\dur,  type: -1, val: 0.4);
    ~sliceCtrl.(\wait, type: -1, val: 0.2);
    ~sliceCtrl.(\amp,  type: -1, val: 0.0);
    ~sliceCtrl.(\trsp, type: -1, val: 0);
    ~sliceCtrl.(\dir,  type: -1, val: 1);

	// --- INIZIALIZZAZIONE BUS DELAY (~dBuses) ---
    ~delayCtrl.(\del,    type: -1, val: 0.3);
    ~delayCtrl.(\mix,    type: -1, val: 0.0);
    ~delayCtrl.(\decayT, type: -1, val: 2.0);
    ~delayCtrl.(\fbk,    type: -1, val: 0.5);
    ~delayCtrl.(\rate,   type: -1, val: 1.0);
    ~delayCtrl.(\amp,    type: -1, val: 0.5);

	~recMix = 0;

    "PIECE MODE READY: Tutti i bus di controllo inizializzati.".postln;
};

/////////////////////// FX LOGICs

/////////////////////// SYNC FX: FSHIFT

~fshiftOn = { |fshift=30, mix=0.3, amp=0.9, pan=0|
    if(~fshiftFx.notNil) { ~fshiftFx.set(\gate, 0); };

    ~fshiftFx = Synth(\fshift, [
        \busIn, ~micBus,
        \busOut, 0,
        \fshift, fshift,
        \mix, mix,
        \amp, amp,
        \pan, pan,
        \gate, 1
    ], ~fxGrp);

    "FSHIFT ON".postln;
};

~fshiftOff = {
    if(~fshiftFx.notNil) {
        ~fshiftFx.set(\gate, 0);
        ~fshiftFx = nil;
        "FSHIFT OFF".postln;
    };
};


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

    if(~rCtrls[\fmod].isNil) { ~ringCtrl.(\fmod, type: -1, val: 440); };
    if(~rCtrls[\idx].isNil)  { ~ringCtrl.(\idx,  type: -1, val: 0.5); };
    if(~rCtrls[\amp].isNil)  { ~ringCtrl.(\amp,  type: -1, val: 0.5); };

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

~harmOn = {
    if(~harmFx.notNil) { ~harmOff.value; };

    ~harmPointer = Synth(\pos, [\buf, ~blive, \busOut, ~kpos], ~micGrp);

    ~harmRec = Synth(\syncrec, [\busIn, ~micBus, \busPos, ~kpos, \buf, ~blive], ~recGrp);

    ~harmFx = Synth(\gharm, [
        \buf, ~blive,
        \busOut, 0,
        \busPos, ~kpos, // Audio bus
        \trig, ~gBuses[\trig].asMap,
        \trsp, ~gBuses[\trsp].asMap,
        \gdur, ~gBuses[\gdur].asMap,
        \amp,  ~gBuses[\amp].asMap,
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

    if(~gCtrls[\trig].isNil) { ~grainCtrl.(\trig, type: 4, freq: 20); };

    if(~gCtrls[\amp].isNil)  { ~grainCtrl.(\amp,  type: -1, val: 0.7); };

    if(~gCtrls[\gdur].isNil) { ~grainCtrl.(\gdur, type: -1, val: 0.1); };

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

    if(~sCtrls[\pos].isNil)  { ~sliceCtrl.(\pos,  type: -1, val: 0.1); };
    if(~sCtrls[\dur].isNil)  { ~sliceCtrl.(\dur,  type: -1, val: 0.4); };
    if(~sCtrls[\wait].isNil) { ~sliceCtrl.(\wait, type: -1, val: 0.2); };
    if(~sCtrls[\amp].isNil)  { ~sliceCtrl.(\amp,  type: -1, val: 0.6); };
    if(~sCtrls[\trsp].isNil) { ~sliceCtrl.(\trsp, type: -1, val: 0); };
    if(~sCtrls[\dir].isNil)  { ~sliceCtrl.(\dir,  type: -1, val: 1); };

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
                \pan, rrand(-0.8, 0.8),
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


/////////////////////// LIVE VOLUME CONTROLS (Specifici)

~ringSetAmp = { |amp=0.5| ~ringCtrl.(\amp, type: -1, val: amp.clip(0, 2)) };

~harmSetAmp = { |amp=0.5| ~grainCtrl.(\amp, type: -1, val: amp.clip(0, 2)) };

~fshiftSetAmp = { |amp=0.5| if(~fshiftFx.notNil) { ~fshiftFx.set(\amp, amp.clip(0, 2)) } };

~grainSetAmp = { |amp=0.5| ~grainCtrl.(\amp, type: -1, val: amp.clip(0, 2)) };

~sliceSetAmp = { |amp=0.5| ~sliceCtrl.(\amp, type: -1, val: amp.clip(0, 2)) };

~delaySetAmp = { |amp=0.5| ~delayCtrl.(\amp, type: -1, val: amp.clip(0, 2)) };


/////////////////////// MASTER MIXER (Macro)

~syncMixer = { |amp=0.5|
    var volume = amp.clip(0, 2);
    ~fshiftSetAmp.(volume);
    ~ringSetAmp.(volume);
    ~harmSetAmp.(volume);
    ~delaySetAmp.(volume);
    ("Sync Layer Volume -> " + volume).postln;
};

~asyncMixer = { |amp=0.5|
    var volume = amp.clip(0, 2);
    ~grainSetAmp.(volume);
	~sliceSetAmp.(volume);
	~delaySetAmp.(volume);
    ("Async Layer Volume -> " + volume).postln;
};


//////// RECALL

~useSlice = { |index|
	if(~slicePool[index].notNil) {
		~lastSlice = ~slicePool[index];
		if(~grainFx.notNil) { ~grainFx.set(\buf, ~lastSlice.bufnum) };
		("Ora il granulatore legge: ~slicePool[" ++ index ++ "]").postln;
	} { "Indice non trovato nella pool!".warn };
};


/////////////////////// GUI CONTROL

if(~pieceWin.notNil) { ~pieceWin.close; };
~pieceWin = Window("PIECE MODE", Rect(200, 200, 560, 70)).front.alwaysOnTop_(true);
~pieceWin.view.keyDownAction_({ arg ... args;
    switch(args[1],

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

		// GRANULAR ASINCRONO
        $g, { ~grainOn.() },
        $b, { ~grainOff.() },

		$0, { ~useSlice.(0) },       // Richiama il primo buffer registrato
		$1, { ~useSlice.(1) },       // Richiama il secondo...
		$2, { ~useSlice.(2) },
		$3, { ~useSlice.(3) },
		$4, { ~useSlice.(4) },
		$5, { ~useSlice.(5) },
		$6, { ~useSlice.(6) },

		// SHIFTER SINCRONO
        $f, { ~fshiftOn.() },
        $v, { ~fshiftOff.() },

		// RING MODULATION SINCRONO
        $a, { ~ringOn.() },
        $z, { ~ringOff.() },

        // HARMONIZER SINCRONO
        $h, { ~harmOn.() },
        $n, { ~harmOff.() },

		// SLICER ASINCRONO
		$s, { ~sliceOn.() },
		$x, { ~sliceOff.() },

		// DELAY SICRONI
		$e, { ~delayOn.(\echo) },     // Echo semplice
		$d, { ~delayOn.(\fbk) },      // Feedback Delay
		$p, { ~delayOn.(\pingpong) }, // Ping Pong
		$l, { ~delayOn.(\vardel) },   // Variable Time
		$c, { ~delayOff.() },
    );
});

~pieceInit.();
)