(
// --- DEFINIZIONE DEL GRANULATORE ---
SynthDef(\grain_1, { arg busOut = 0, buf = 0, pos = 0, trig = 0,
    gdur = 0.1, amp = 0, trsp = 0, pan = 0, gate = 0, done = 2;
    var sig, env;

    // Converte la posizione in secondi in base alla durata del buffer
    pos = pos * BufDur.kr(buf);

    sig = TGrains.ar(2, // Uscita Stereo
        trig,
        buf,
        trsp.midiratio,
        pos,
        gdur,
        pan,
        amp,
        4 // Interpolazione cubica (alta qualità)
    );

    env = Linen.kr(gate, doneAction: done);
    Out.ar(busOut, sig * env);
}).add;

// --- IL GENERATORE DI POSIZIONE (DIRETTORE) ---
SynthDef(\pos, { arg busOut = 0, buf = 0, rate = 1;
    var sig = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, BufFrames.kr(buf));
    Out.ar(busOut, sig); // Invia l'indice del campione corrente
}).add;

// --- REGISTRATORE SINCRONIZZATO ---
SynthDef(\syncrec, { arg busIn = 0, busPos = 0, buf = 0;
    var ptr = In.ar(busPos, 1); // Riceve la posizione dal Phasor
    var sig = In.ar(busIn, 1);
    BufWr.ar(sig, buf, ptr); // Scrive esattamente in quel punto
}).add;

// --- GRANULATORE SINCRONO (HARMONIZER) ---
SynthDef(\gharm, { arg busOut = 0, busPos = 0, buf = 0, trig = 0,
    gdur = 0.1, amp = 0, trsp = 0, pan = 0, gate = 0, done = 2;
    var pos, sig, env;
    // Legge la posizione e la converte in secondi per TGrains
    pos = In.ar(busPos, 1) / SampleRate.ir(buf);
    sig = TGrains.ar(2, trig, buf, trsp.midiratio, pos, gdur, pan, amp, 4);
    env = Linen.kr(gate, doneAction: done);
    Out.ar(busOut, sig * env);
}).add;

SynthDef(\harm, { arg busIn = 0, busOut = 0, trsp = 0,
    gdur = 0.1, prand = 0, trand = 0, amp = 0, pan = 0, gate = 0, done = 2;
    var sig, env;
    sig = In.ar(busIn);
    // UGen specializzato per l'harmonizer live
    sig = PitchShift.ar(sig,
        gdur,              // Durata grana
        trsp.midiratio,    // Rapporto di trasposizione
        prand,             // Randomizzazione pitch (chorus)
        trand              // Randomizzazione tempo
    );
    env = Linen.kr(gate, doneAction: done);
    Out.ar(busOut, Pan2.ar(sig * env * amp, pan));
}).add;

"Libreria Granulators SynthDef caricata.".postln;
)