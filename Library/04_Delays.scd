(
SynthDef(\echo, {arg busIn = 0, busOut = 0, maxdel = 10, del = 0.5, mix = 0,
    amp = 0, gate = 0, pan = 0, done = 2;
    var sig, dly, env;
    sig = In.ar(busIn);

    // DelayL: Delay con interpolazione lineare
    dly = DelayL.ar(sig, maxdel, del);
    dly = LeakDC.ar(dly); // Rimuove eventuali offset DC

    env = Linen.kr(gate, doneAction: done);

    // XFade2: Mix tra segnale processato (dly) e diretto (sig)
    // -1 = solo delay, 0 = mix 50/50, 1 = solo suono diretto
    sig = XFade2.ar(dly, sig, mix);

    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\del_1, {arg busIn = 0, busOut = 0, maxdel = 10, del = 0.5, fbk = 0.0, mix = 0,
    amp = 0, gate = 0, pan = 0, done = 2;
    var in, local, sig, dly, env;
    in = In.ar(busIn);

    // Legge dal bus di feedback interno
    local = LocalIn.ar(1);
    sig = in + local;

    dly = DelayL.ar(sig, maxdel, del);
    dly = LeakDC.ar(dly);

    // Invia il segnale ritardato moltiplicato per il feedback all'ingresso
    LocalOut.ar(dly * fbk);

    env = Linen.kr(gate, doneAction: done);
    sig = XFade2.ar(dly, sig, mix) * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\del_2, {arg busIn = 0, busOut = 0, maxdel = 10, del = 0.5, decayT = 1, mix = 0,
    amp = 0, gate = 0, pan = 0, done = 2;
    var in, sig, dly, env;
    in = In.ar(busIn);

    // CombL: il feedback è gestito tramite il tempo di decadimento (decayT)
    dly = CombL.ar(in, maxdel, del, decayT);

    env = Linen.kr(gate, doneAction: done);
    sig = LeakDC.ar(dly);
    sig = XFade2.ar(dly, in, mix);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\pingpong, {arg busIn = 0, busOut = 0, maxdel = 2, del = 0.5, fbk = 0.0,
    amp = 0, gate = 0, done = 2;
    var in, local, sig, dly, env;
    in = In.ar(busIn);

    // Inizializza feedback stereo e somma l'ingresso mono al canale L
    local = LocalIn.ar(2) + [in, 0];

    dly = DelayL.ar(local, maxdel, del, 1);
    dly = LeakDC.ar(dly);
    env = Linen.kr(gate, doneAction: done);

    // .reverse è il passaggio chiave: scambia L con R per il prossimo ciclo
    LocalOut.ar(dly.reverse * fbk);

    Out.ar(busOut, local * env * amp)
}).add;

SynthDef(\multitap, {arg busIn = 0, busOut = 0, buf = 0,
    times = #[0.1, 0.5, 1.2, 0.8], // Tempi dei tap (array)
    amps = #[1, 0.5, 0.8, 0.3],    // Ampiezze dei tap (array)
    mix = 0, amp = 0, pan = 0, gate = 0, done = 2;
    var in, env, del, sig;
    in = In.ar(busIn);
    env = Linen.kr(gate, doneAction: done);

    // MultiTap legge l'input e genera le ripetizioni basandosi sul buffer
    del = MultiTap.ar(times, amps, in, bufnum: buf);

    sig = XFade2.ar(del, in, mix);
    sig = sig * amp * env;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\vardel, {arg busIn = 0, busOut = 0,
    maxdel = 10, rate = 3, decayT = 1,
    mix = 0, delMin = 0.1, delMax = 0.4,
    amp = 0, gate = 0, pan = 0, done = 2;
    var in, sig, ksig, dly, env;
    in = In.ar(busIn);

    // ksig: Segnale di controllo per il tempo di delay.
    // L'uso di .exprange (esponenziale) è più naturale per i tempi di delay
    ksig = LFNoise2.kr(rate).exprange(delMin, delMax);

    dly = CombL.ar(in, maxdel, ksig, decayT);
    env = Linen.kr(gate, doneAction: done);
    sig = LeakDC.ar(dly); // Fondamentale per feedback lunghi e instabili
    sig = XFade2.ar(dly, in, mix) * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\delfilt, {arg busIn = 0, busOut = 0,
    maxdel = 10, del = 0.5, fbk = 0.0,
    mix = 0, coef = 0,
    amp = 0, gate = 0, pan = 0, done = 2;
    var in, local, sig, dly, env;
    in = In.ar(busIn);
    local = LocalIn.ar(1);
    sig = in + local;

    dly = DelayL.ar(sig, maxdel, del);

    // OnePole: un filtro molto semplice ed efficace per il feedback.
    // coef > 0 = Passa-basso; coef < 0 = Passa-alto
    dly = OnePole.ar(dly, coef);

    dly = LeakDC.ar(dly);
    LocalOut.ar(dly * fbk);

    env = Linen.kr(gate, doneAction: done);
    sig = XFade2.ar(dly, sig, mix);
    sig = sig * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

SynthDef(\resondel, {arg busIn = 0, busOut = 0, decayT = 0.2, reson = 0.01,
    amp = 0, gate = 0, pan = 0, done = 2;
    var in, dly, env, sig;
    in = In.ar(busIn);

    // reson controlla la frequenza della risonanza.
    // Frequenza = 1 / reson. Ad esempio, 0.01 secondi = 100 Hz
    reson = MouseY.kr(0.0001, 0.01);
    reson.reciprocal.poll(10, "Freq risonanza"); // Mostra la frequenza in Hz

    dly = CombL.ar(in, 0.01, reson, decayT);
    env = Linen.kr(gate, doneAction: done);
    sig = dly * env * amp;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;

"Libreria Delays SynthDef caricata.".postln;
)