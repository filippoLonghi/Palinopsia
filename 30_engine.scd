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
    // 1. Pulizia sorgente precedente
    if(~source.notNil) { ~source.free; };

    // 2. Avvio Microfono (Input 1 -> Bus Audio Interno)
    ~source = Synth(\mic, [\busIn, 0, \busOut, ~micBus, \amp, 1], ~micGrp);

    // 3. AVVIO MONITOR CUFFIE (Routing speciale per Volt 4)
    if(~monitorFx.notNil) { ~monitorFx.free };
    ~monitorFx = Synth(\monitor, [
        \busMain, 0,  // Legge ciò che va alla Cassa (Main Mix)
        \busMic,  0,  // Legge direttamente l'Input 1 (Mic fisico)
        \outHp,   2,  // Esce sulle uscite hardware 3 e 4 (in SC sono bus 2 e 3)
        \ampMain, 1,  // Volume Cassa in cuffia
        \ampMic,  1,  // Volume Cello diretto in cuffia
        \mix,     0,  // 0 = SPLIT (SX=Cassa, DX=Cello), 1 = MIX (Tutto al centro)
        \masterVol, 1 // Volume generale cuffia
    ], ~monGrp); // Fondamentale: deve stare nell'ultimo gruppo (~monGrp)

    // 4. Gestione Buffer (Se vuoto ne crea uno, se pieno usa l'ultimo)
    if(~slicePool.isEmpty) {
        ~lastSlice = Buffer.alloc(s, s.sampleRate * 1, 1);
    } {
        ~lastSlice = ~slicePool.last;
    };

    // 5. Reset Dizionari controlli (Opzionale, ma pulito)
    // [~fCtrls, ~gCtrls, ~rCtrls, ~sCtrls, ~dCtrls].do({ |dict| dict.do(_.free); dict.clear; });

    // --- INIZIALIZZAZIONE BUS FREQUENCY SHIFTER ---
    ~fBuses[\fshift].set(30);
    ~fBuses[\mix].set(0.3);
    ~fBuses[\amp].set(0);

    // --- INIZIALIZZAZIONE BUS RING MODULATION ---
    ~rBuses[\fmod].set(440);
    ~rBuses[\idx].set(0.5);
    ~rBuses[\amp].set(0.5);

    // --- INIZIALIZZAZIONE BUS HARMONIZER ---
    ~hBuses[\amp].set(0.5);
    ~hBuses[\trig].set(0);
    ~hBuses[\trsp].set(0);
    ~hBuses[\gdur].set(0.15);

    // --- INIZIALIZZAZIONE BUS GRANULATOR ---
    ~gBuses[\amp].set(0.5);
    ~gBuses[\gdur].set(0.15);
    ~gBuses[\pos].set(0.1);
    ~gBuses[\trsp].set(0);
    ~gBuses[\trig].set(0);

    // --- INIZIALIZZAZIONE BUS SLICING ---
    ~sBuses[\pos].set(0.1);
    ~sBuses[\dur].set(0.4);
    ~sBuses[\wait].set(0.2);
    ~sBuses[\amp].set(0.5);
    ~sBuses[\trsp].set(0);
    ~sBuses[\dir].set(1);

    // --- INIZIALIZZAZIONE BUS DELAY ---
    ~dBuses[\del].set(0.3);
    ~dBuses[\mix].set(0.0);
    ~dBuses[\decayT].set(2.0);
    ~dBuses[\fbk].set(0.5);
    ~dBuses[\rate].set(1.0);
    ~dBuses[\amp].set(0.5);

    // 6. Reset Mixer Volumi
    ~recMix = 0;
    ~syncMixer.(1.0);
    ~asyncMixer.(1.0);
    ~masterMixer.(1.0);

    "PIECE MODE READY: Tutti i bus di controllo inizializzati. Monitoring cuffie attivo su Out 3/4.".postln;
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

/////////////////////// HEADPHONE CONTROLS

~hpVol = { |vol=1|
	~monitorFx.set(\masterVol, vol);
	"HP Master Vol: %".format(vol).postln;
};

~hpMix = { |main=1, mic=1|
	~monitorFx.set(\ampMain, main, \ampMic, mic);
	"HP Levels -> Main: %, Mic: %".format(main, mic).postln;
};

~hpMode = { |mode=0|
	// 0 = Split (Main a SX, Mic a DX)
	// 1 = Mono (Tutto su entrambe le orecchie)
	~monitorFx.set(\mix, mode);
	"HP Mode: %".format(if(mode==0, "SPLIT (L=Main, R=Mic)", "MONO MIX")).postln;
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

// Prende le dimensioni dello schermo
~screenW = Window.screenBounds.width;
~screenH = Window.screenBounds.height;

// Calcola la posizione
~meterX = ~screenW - 735;
~meterY = ~screenH - 550;

if(~pieceWin.notNil) { ~pieceWin.close };

// CREAZIONE FINESTRA
~pieceWin = Window("PIECE MODE", Rect(~meterX, ~meterY, 120, 120))
	.front
	.alwaysOnTop_(true)
	.background_(Color.new255(220, 220, 220));

StaticText(~pieceWin, Rect(5, 5, 110, 110))
	.string_("  KeyBoard Shortcuts
FSh:   f/v       Ring: a/z
Harm:  h/n     Grain: g/b
Slice: s/x  Dly: e/d/p/l/c
Rec:   r/i/k    Mode: q/w
Play:  u/j        Buf: 0-6
   Shift+1..5: Dry Play   ")
	.font_(Font("Helvetica", 10)) // Font compatto
	.align_(\center)
	.stringColor_(Color.black);

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

// Routine Automatiche
~sliceChaosToPulses = { |bufIndex = 0, totalDur = 30, amp = 1, stepTime = nil|
	var chaosDur, posFixDur, trspFixDur, durFixDur;
	var chaosSteps = 7, posFixSteps = 3, trspFixSteps = 3, durFixSteps = 3;
	var chaosFrac = 0.95;
	var step;

	var waitChaos  = [0.01, 0.02, 0.05, 0.10, 0.20, 0.50, 0.80];
	var waitPosFix = [1.00, 1.20, 1.35];
	var waitTrspFix= [1.50, 1.65, 1.80];
	var waitDurFix = [1.90, 1.95, 2.00];

	var posF  = [20, 12, 8, 5, 3, 1, 0.4];
	var durF  = [12,  8, 5, 3, 2, 0.7, 0.3];
	var trspF = [150, 90, 60, 40, 25, 10, 4];

	var posFixVals  = [0.55, 0.63, 0.70];
	var trspFixVals = [ 1.0, 0.5, 0.0];
	var durFixVals  = [0.22, 0.27, 0.30];

	chaosDur  = totalDur * chaosFrac;
	posFixDur = totalDur * (1 - chaosFrac) * 0.70;
	trspFixDur= totalDur * (1 - chaosFrac) * 0.20;
	durFixDur = totalDur * (1 - chaosFrac) * 0.10;

	Routine({
		"--- START Slicer Progression (Dur: %s) ---".format(totalDur).postln;

		~startTimer.(stepTime);
		~useSlice.(bufIndex);
		~sliceOn.();
		~sliceSetAmp.(amp);
		~sliceCtrl.(\dir, type: -1, val: 1);

		// FASE 1: CAOS
		step = chaosDur / chaosSteps;
		chaosSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitChaos[i]);
			~sliceCtrl.(\pos,  type: 2, range: [0, 1],      freq: posF[i]);
			~sliceCtrl.(\dur,  type: 2, range: [0.05, 0.7],  freq: durF[i]);
			~sliceCtrl.(\trsp, type: 2, range: [-12, 12],  freq: trspF[i]);
			step.wait;
		};

		// FASE 2: POS FIX
		step = posFixDur / posFixSteps;
		posFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitPosFix[i]);
			~sliceCtrl.(\pos,  type: -1, val: posFixVals[i]);
			~sliceCtrl.(\dur,  type: 2, range: [0.2, 0.5],  freq: 0.25);
			~sliceCtrl.(\trsp, type: 2, range: [-6, 6],  freq: 3);
			step.wait;
		};

		// FASE 3: TRSP FIX
		step = trspFixDur / trspFixSteps;
		trspFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitTrspFix[i]);
			~sliceCtrl.(\trsp, type: -1, val: trspFixVals[i]);
			~sliceCtrl.(\dur,  type: 2, range: [0.3, 0.4],  freq: 0.18);
			step.wait;
		};

		// FASE 4: DUR FIX
		step = durFixDur / durFixSteps;
		durFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitDurFix[i]);
			~sliceCtrl.(\dur,  type: -1, val: durFixVals[i]);
			step.wait;
		};

		// FINALE: Stabilizzazione
		~sliceCtrl.(\wait, type: -1, val: 2.0);
		~sliceCtrl.(\pos,  type: -1, val: 0.7);
		~sliceCtrl.(\trsp, type: -1, val: 0);
		~sliceCtrl.(\dur,  type: -1, val: 0.3);

		"--- FINISH Slicer Progression ---".postln;
	}).play;
};

~grainProgression = { |bufIndex = 0, totalDur = 60, amp = 1, stepTime = nil|
    Routine({
        var trigFreqs = (3..17).as(List);
        var trspRanges = (1..8).as(List);
        var actions = List.new;
        var waitTime;

        while { trigFreqs.notEmpty or: trspRanges.notEmpty } {
            if(trigFreqs.notEmpty) {
                var f = trigFreqs.removeAt(0);
                actions.add({ ~grainCtrl.(\trig, type: 2, freq: f, range: [-1, 1]) });
            };

            if(trspRanges.notEmpty) {
                var r = trspRanges.removeAt(0);
                var t = if(r <= 3, 2, 3);
                actions.add({ ~grainCtrl.(\trsp, type: t, freq: 70, range: [r.neg, r]) });
            };
        };

        waitTime = totalDur / actions.size;

        "--- INIZIO PROGRESSIONE: " ++ totalDur ++ "s ---".postln;

		~startTimer.(stepTime);
		~useSlice.(bufIndex);
        ~grainOn.();
		~grainSetAmp.(amp);
        ~grainCtrl.(\trsp, type: -1, val: 0);
        ~grainCtrl.(\gdur, type: -1, val: ~lastSlice.duration - 0.1);
        ~grainCtrl.(\pos,  type: -1, val: 0);
        ~grainCtrl.(\trig, type: 2, freq: 2, range: [-1, 1]);

        waitTime.wait;

        actions.do { |action|
            action.value;
            waitTime.wait;
        };

        "--- PROGRESSIONE COMPLETATA ---".postln;
    }).play;
};

~sliceTrspProgression = { |bufIndex = 0, totalDur = 60, amp = 1, stepTime = nil|
    Routine({
        var steps = [-2, -4, -6, -8, -12];
        // Coefficienti per compensare la perdita di volume al calare del pitch
        var ampRatios = [1.2, 1.4, 1.5, 1.65, 1.8];
        var waitTime = totalDur / (steps.size + 1);

        "--- INIZIO PROGRESSIONE SLICER (Durata: %s) ---".format(totalDur).postln;

		~startTimer.(stepTime);
        // 1. SETUP INIZIALE (Effetto Orchestra)
        ~useSlice.(bufIndex);
        ~sliceOn.();

        // Imposta l'ampiezza base iniziale
        ~sliceSetAmp.(amp);

        ~sliceCtrl.(\pos,  type: 2, freq: 0.1, range: [0, 1]);
        ~sliceCtrl.(\dir,  type: 2, freq: 0.5, range: [-1, 1]);
        ~sliceCtrl.(\wait, type: -1, val: 1);
        ~sliceCtrl.(\dur,  type: -1, val: ~lastSlice.duration);

        // Iniziamo con la scordatura leggera (chorus)
        ~sliceCtrl.(\trsp, type: 2, freq: 0.1, range: [-0.2, 0.2]);

        waitTime.wait;

        // 2. PROGRESSIONE SEQUENZIALE TRSP E AMP
        steps.do { |val, i|
            var currentAmpRatio = amp * ampRatios[i];

            "Step %: Trsp -> %, Amp Ratio -> %".format(i + 1, val, currentAmpRatio.round(0.1)).postln;

            // Modifica simultanea di trasposizione e ampiezza base
            ~sliceCtrl.(\trsp, type: -1, val: val);
            ~sliceSetAmp.(currentAmpRatio);

            // Manteniamo gli altri parametri costanti per preservare il tappeto
            ~sliceCtrl.(\pos,  type: 2, freq: 0.1, range: [0, 1]);
            ~sliceCtrl.(\dir,  type: 2, freq: 0.8, range: [-1, 1]);

            waitTime.wait;
        };

        "--- PROGRESSIONE SLICER COMPLETATA ---".postln;
    }).play;
};

~grainSection3Progression = { |totalDur = 30, stepTime = nil|
	Routine({
		// Definiamo solo i passaggi di modifica del trigger e ampiezza
		var steps = [
			{ ~grainCtrl.(\trig, type: 5, freq: 1) },
			{ ~grainCtrl.(\trig, type: 5, freq: 3) },
			{ ~grainCtrl.(\trig, type: 5, freq: 5) },
			{ ~grainCtrl.(\trig, type: 5, freq: 10) },
			{ ~grainCtrl.(\trig, type: 5, freq: 20) },
			{ ~grainCtrl.(\trig, type: 5, freq: 35) },
			{ ~grainCtrl.(\trig, type: 5, freq: 50) },
			{ ~grainCtrl.(\trig, type: 5, freq: 70) }
		];

		// Il tempo totale viene diviso per il numero di cambi
		var waitTime = totalDur / steps.size;

		"--- START Sola progressione TRIG (Durata: %s) ---".format(totalDur).postln;

		~startTimer.(stepTime);
		// ESECUZIONE SEQUENZIALE
		steps.do { |action, i|
			"Trig Step % di % (freq crescente)".format(i + 1, steps.size).postln;
			action.value;
			waitTime.wait;
		};

		"--- FINISH Progresione TRIG ---".postln;
	}).play;
};

~codaProgression = { |bufIndex = 0, totalDur = 60, ampS = 1, ampG = 1, stepTime = nil|
	Routine({
		// Definiamo i 10 passaggi della progressione
		var steps = [
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.3, 0.5]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.25, 0.4]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.2, 0.3]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.1, 0.15]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.2, 0.3]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.25, 0.4]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.3, 0.4]) },
			{ ~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.4, 0.6]) },
			{ ~sliceCtrl.(\dur,  type: 2, freq: 350, range: [0.02, 0.05]) },
			{ ~sliceCtrl.(\dur,  type: -1, val: 0) }
		];

		// Calcolo del tempo di attesa tra ogni step
		var waitTime = totalDur / steps.size;

		"--- START CODA PROGRESSION (Durata: %s) ---".format(totalDur).postln;

		~startTimer.(stepTime);
		~useSlice.(bufIndex);
		// 1. SETUP INIZIALE (Blocco 1)
		~sliceOn.();
		~sliceSetAmp.(ampS);
		~sliceCtrl.(\pos,  type: 5, freq: 500);
		~sliceCtrl.(\dur,  type: 2, freq: 350, range: [0.1, 0.2]);
		~sliceCtrl.(\trsp, type: -1, val: 0);
		~sliceCtrl.(\dir,  type: -1, val: 1);
		~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.4, 0.6]);

		~grainOn.();
		~grainCtrl.(\trig, type: 2, freq: 10, range: [-1, 1]);
		~grainSetAmp.(ampG);
		~grainCtrl.(\trsp, type: -1, val: 0);
		~grainCtrl.(\gdur, type: -1, val: 3.5);
		~grainCtrl.(\pos,  type: -1, val: 0);

		waitTime.wait;

		// 2. ESECUZIONE SEQUENZIALE DEGLI STEP
		steps.do { |action, i|
			"Coda Step % di %".format(i + 1, steps.size).postln;
			action.value;
			waitTime.wait;
		};

		"--- FINISH CODA PROGRESSION ---".postln;
	}).play;
};

~pieceInit.();
)