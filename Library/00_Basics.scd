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

// --- SYNTHDEF: HEADPHONE MONITOR ---
// Gestisce il routing verso le uscite 3 e 4 (Cuffie)
SynthDef(\monitor, { arg busMain=0, busMic=0, outHp=2,
	ampMain=1, ampMic=1, masterVol=1, mix=0;

	var srcMain, srcMic, left, right;

	// 1. Legge il Main Mix (ciò che sente il pubblico)
	// In.ar(0) legge quello che gli altri synth hanno scritto sul Bus 0
	srcMain = In.ar(busMain, 1) * ampMain;

	// 2. Legge il Microfono Diretto (latenza quasi zero)
	srcMic  = SoundIn.ar(busMic) * ampMic;

	// 3. Logica di Mixing (SPLIT vs MIX)
	// Se mix = 0 (SPLIT): Sinistra = Main, Destra = Mic
	// Se mix = 1 (MONO):  Sinistra = Main+Mic, Destra = Main+Mic
	// I valori intermedi fondono i segnali

	left  = srcMain + (srcMic * mix);
	right = srcMic  + (srcMain * mix);

	// 4. Output su Bus 2 e 3 (Hardware Output 3 e 4)
	Out.ar(outHp, [left, right] * masterVol);
}).add;

"Libreria Basics SynthDef caricata.".postln;
)