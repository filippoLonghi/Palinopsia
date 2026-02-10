(
/* --- PLAYBACK ENGINES (7.4.2) --- */

// Synth per il playback con controllo di trasposizione e direzione
SynthDef(\plbk, {arg buf = 0, busOut = 0, pos = 0, dur = 0.2, amp = 0,
    trsp = 0, dir = 1, pan = 0, t_gate = 0, done = 2;
    var sig, env;
    sig = PlayBuf.ar(1, buf,
        BufRateScale.kr(buf) * trsp.midiratio * dir,
        t_gate,
        BufSampleRate.kr(buf) * pos
    );
    // Inviluppo linen per evitare click durante lo slicing
    env = Env.linen(0.01, dur - 0.02, 0.01);
    env = EnvGen.kr(env, t_gate, doneAction: done);
    sig = sig * env * amp;
    //sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

// Scratching machine: utilizza Lag per ammorbidire i movimenti del puntatore
SynthDef(\sch, { arg buf = 0, busOut = 0, smooth = 0.02, amp = 0, pos = 0, pan = 0;
    var pnt, sig;
    // Mappa il valore 0-1 del mouse alla durata dei frames del buffer
    pnt = Lag.kr(pos.linlin(0, 1, 0, BufFrames.kr(buf)), smooth);
    sig = BufRd.ar(1, buf, K2A.ar(pnt)); // K2A converte il controllo in audio rate
    //sig = Pan2.ar(sig * amp, pan);
    Out.ar(busOut, sig)
}).add;

// Metronomo: scrive il trigger e la durata del beat sui bus
SynthDef(\metro, {arg bpm = 60, busTrig = 99, busDur = 100;
    var bps, sec, sig;
    bps = bpm / 60 * 100; // Calcola 100 parti per beat per gestire le suddivisioni
    sig = Impulse.ar(bps);
    sec = 60 / bpm; // Durata del beat in secondi
    Out.ar(busTrig, sig);
    Out.kr(busDur, sec);
}).add;

// Looper sincronizzato: utilizza PulseDivider per le suddivisioni ritmiche
SynthDef(\loop, {arg buf = 0, busTrig = 99, busDur = 100, busOut = 0,
    pos = 0, sudd = 1, legato = 0, amp = 0,
    dir = 1, gate = 0, pan = 0, done = 2;
    var dur, trig, sig, env, fade;
    dur = In.kr(busDur) * (1/sudd);
    // PulseDivider permette di triggerare solo su certi battiti della griglia
    trig = PulseDivider.ar(In.ar(busTrig), 100/sudd);
    sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * dir, trig, BufFrames.kr(buf) * pos);
    env = Env.linen(0.01, (dur * legato) - 0.02, 0.01);
    env = EnvGen.ar(env, trig);
    fade = Linen.kr(gate, doneAction: done);
    sig = sig * fade * env * amp;
    //sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

"Libreria Playback SynthDef caricata.".postln;
)