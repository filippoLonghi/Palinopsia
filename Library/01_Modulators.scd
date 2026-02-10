(
// --- SYNTHDEF: RING MODULATION ---
SynthDef(\ring, {arg busIn = 0, busOut = 0, fmod = 400, idx = 0, amp = 0, gate = 0, pan = 0;
    var car, mod, env, sig;
    car = In.ar(busIn, 1); // Segnale portante (Mic)
    mod = SinOsc.ar(fmod) * idx; // Segnale modulante (Sinusoide)
    env = Linen.kr(gate, doneAction: 2);
    // Moltiplicazione bipolare: genera frequenze somma e differenza
    sig = car * mod * amp * env;
    //sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\ring1, {arg busIn = 0, busOut = 0, amp = 0, gate = 0, pan = 0;
    var car, mod, chain, fmod, idx, env, sig;
    car = In.ar(busIn, 1);

    // Mappatura automatica
    idx = Amplitude.ar(car).lag(0.5); // Più forte parli, più è modulato
    chain = FFT(LocalBuf(2048), car);
    fmod = SpecCentroid.kr(chain).lag(0.5); // La frequenza segue il timbro

    // Chorus: due sinusoidi leggermente scordate per un suono più ricco
    mod = Mix(SinOsc.ar([fmod, fmod + 0.5])) * idx;

    env = Linen.kr(gate, doneAction: 2);
    sig = car * mod * amp * env;
    //sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\fshift, {arg busIn = 0, busOut = 0, fshift = 0, amp = 0, pan = 0, mix = 0, gate = 0;
    var sIn, sig, env;
    sIn = In.ar(busIn, 1);
    // UGen dedicato allo spostamento di frequenza
    sig = FreqShift.ar(sIn, fshift);
    // XFade2 miscela segnale originale (Dry) e spostato (Wet)
    sig = XFade2.ar(sIn, sig, mix.linlin(0, 1, -1, 1));
    env = Linen.kr(gate, doneAction: 2);
    sig = sig * env * amp;
    //sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

"Libreria Madulators SynthDef caricata.".postln;
)