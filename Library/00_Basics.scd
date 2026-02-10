(
/* --- BASICS (Infrastruttura) --- */

// --- SYNTHDEF: INGRESSO ---
    SynthDef(\mic, { arg busIn = 0, busOut = 0, amp = 0;
        var sig = SoundIn.ar(busIn) * amp.lag;
        sig = LeakDC.ar(sig);
        Out.ar(busOut, sig)
    }).add;

// --- SYNTHDEF: GENERATORE DI CONTROLLO ---
// Usa Select.kr per scambiare la sorgente di controllo dinamicamente
SynthDef(\ksig, { arg type = 0, range = #[0, 1], freq = 1, busOut = 0;
	var sig = Select.kr(type, [
		MouseX.kr(range[0], range[1]),   // 0: Mouse X
		MouseY.kr(range[0], range[1]),   // 1: Mouse Y
		LFNoise1.kr(freq).range(range[0], range[1]), // 2: Rumore
		LFSaw.kr(freq).range(range[0], range[1]),    // 3: Dente di sega
		Impulse.kr(freq), // 4: Metronomo
		Dust.kr(freq),    // 5: Casuale impulsivo
	]);
	Out.kr(busOut, sig)
}).add;

// --- SYNTHDEF: REGISTRATORE ---
SynthDef(\rec, { arg buf = 0, busIn = 0, loop = 0, mix = 0, done = 2;
	var in = In.ar(busIn, 1);
	RecordBuf.ar(in, buf,
		preLevel: mix, // 0 = sovrascrivi, 1 = aggiungi (overdub)
		loop: loop,
		doneAction: done);
}).add;


"Libreria Basics SynthDef caricata.".postln;
)