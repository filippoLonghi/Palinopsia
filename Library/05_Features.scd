



(

// Modello 1: Segnale Continuo (Amplitude Follower)
SynthDef(\efol1, { arg busIn=0, busOut=0, atk=0.001, dec=0.01;
    var sig = In.ar(busIn, 1);
    var amp = Amplitude.ar(sig, atk, dec); // Converte audio in controllo di ampiezza
    Out.ar(busOut, amp);
}).add;

// Modello 2: Trigger + Comunicazione Server-Interpreter
SynthDef(\efol2, { arg busIn=0, busOut=0, atk=0.001, dec=0.01, thresh=0.3, dur=0.1;
    var sig = In.ar(busIn, 1);
    var amp = Amplitude.ar(sig, atk, dec);
    var trig = Trig1.ar(amp > thresh, dur); // Genera un trigger se supera la soglia

    // Invia un messaggio al linguaggio SuperCollider (Interpreter)
    SendTrig.ar(trig, 100, amp);
    Out.ar(busOut, [amp, trig]); // Canale 0: ampiezza, Canale 1: trigger
}).add;

// Modello 3: Noise Gate (Compander) prima dell'analisi
SynthDef(\efol3, { arg busIn=0, busOut=0, atk=0.01, dec=0.01, thresh=0.3;
    var sig = In.ar(busIn, 1);
    // Taglia i suoni sotto la soglia per evitare che il rumore di fondo attivi i synth
    sig = Compander.ar(sig, sig, thresh, 10, 1, 0.01, 0.2);
    Out.ar(busOut, Amplitude.ar(sig, atk, dec));
}).add;




// --- Continuos mapping example (FIXED) ---
SynthDef(\noise, {arg busIn = 0, busOut = 0, pan = 0;
    var sig, env;
    sig = PinkNoise.ar;
    // Legge l'inviluppo dal bus di analisi
    env = In.ar(busIn, 1);
    sig = sig * env;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;



// --- Trigger mapping example ---
SynthDef(\sine, {arg busIn = 0, busOut = 0;
    var sig, gate, env;
    // Riceve 2 canali: gate[0] = ampiezza, gate[1] = trigger
    gate = In.ar(busIn, 2);
    env = EnvGen.kr(Env.perc, gate[1]); // Inviluppo a percussione attivato dal trigger

    // TRand genera una nuova frequenza ogni volta che riceve il trigger
    sig = SinOsc.ar(TRand.ar(500, 1000, gate[1]));
    sig = sig * env;

    // Panning dinamico controllato dall'ampiezza del segnale originale
    sig = Pan2.ar(sig, gate[0].linlin(0, 1, -1, 1));
    Out.ar(busOut, sig)
}).add;


// --- Noise gate + Envelope following ---

SynthDef(\saw, { arg busIn = 0, busOut = 0;
    var sig, env;
    env = In.ar(busIn, 1);
    sig = Saw.ar([560, 563]);
    sig = sig * env * 0.5;
    Out.ar(busOut, sig)
}).add;



//7.3.2 PITCH FOLLOWER


// --- Modello 1: Autocorrelazione continua ---
SynthDef(\pfol1, {arg busIn = 0, busOut = 0, high = 1000, low = 60, median = 1,
    atk = 0.01, dec = 0.01, filt = 1000;
    var sig, amp, freq, hasFreq;
    sig = In.ar(busIn, 1);
    amp = Amplitude.kr(sig, atk, 0.01);
    sig = LPF.ar(sig, filt); // Filtro passa-basso per pulire le armoniche

    // Pitch.kr restituisce un array: [frequenza, accuratezza]
    #freq, hasFreq = Pitch.kr(sig, high, low, high, median: median);

    // freq.poll; // Decommenta per monitorare i valori
    Out.kr(busOut, [freq, hasFreq, amp]); // Bus a 3 canali
}).add;

// --- Modello 2: FFT (Tartini) continua ---
SynthDef(\pfol2, {arg busIn = 0, busOut = 0, atk = 0.01, dec = 0.01, filt = 2000;
    var sig, amp, freq, hasFreq;
    sig = In.ar(busIn, 1);
    amp = Amplitude.kr(sig, atk, 0.01);
    sig = LPF.ar(sig, filt);

    #freq, hasFreq = Tartini.kr(sig); // Richiede estensione sc3-plugins
    Out.kr(busOut, [freq, hasFreq, amp]);
}).add;

// --- Modello 3: Trigger basato sul range di frequenza ---
SynthDef(\pfol3, {arg busIn = 0, busOut = 0, low = 200, high = 300, filt = 2000;
    var sig, freq, hasFreq, trig1, trig2, trig;
    sig = In.ar(busIn, 1);
    sig = LPF.ar(sig, filt);
    #freq, hasFreq = Tartini.kr(sig);

    trig1 = freq > low;
    trig2 = freq < high;
    // Genera un trigger solo se la frequenza è all'interno del range
    trig = Trig1.ar((trig1 + trig2 - 1), 0.5);

    Out.kr(busOut, [freq, hasFreq]);
    SendTrig.ar(trig, 113, freq); // Invia il trigger e la frequenza all'Interpreter
}).add;




// Sintetizzatore reattivo
SynthDef(\sine1, {arg busIn = 0, busOut = 0, thresh = 0.05, pan = 0;
    var sig, ksig, env;
    ksig = In.kr(busIn, 3); // Legge [freq, hasFreq, amp]
    sig = Mix(SinOsc.ar(ksig[0] * [0.5, 1, 3])); // Somma 3 ottave

    // Se amp > thresh, env = 1 (con lag per evitare click)
    env = (ksig[2] > thresh).lag(0.4) * 0.2;
    sig = sig * env * ksig[1]; // Moltiplica per l'accuratezza (hasFreq)
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig);
}).add;




// Synth attivato dal trigger
SynthDef(\sine2, {arg freq;
    var sig, env;
    sig = Mix(SinOsc.ar(freq * [0.5, 2, 3]));
    env = EnvGen.kr(Env.perc, doneAction: 2); // Inviluppo percussivo
    Out.ar(0, sig * env * 0.2 ! 2);
}).add;



// 7.3.3 ONSET DETECTION

SynthDef(\onsDec, {arg busIn = 0, busOut = 0,
    atk = 0.01, dec = 0.01, dur = 0.2, thresh = 12;
    var sig, amp, slope, trig;
    sig = In.ar(busIn, 1);
    amp = Amplitude.ar(sig, atk, dec); // Estrae l'inviluppo di ampiezza

    // Slope calcola la derivata del segnale (velocità di cambiamento)
    slope = Slope.ar(amp);

    // Genera un impulso (trigger) se la pendenza supera la soglia
    trig = Trig1.ar(slope > thresh, dur);

    Out.ar(busOut, trig); // Invia il trigger a un bus audio

    // Invia il trigger dal Server all'Interpreter (ID 153)
    SendTrig.ar(trig, 153, 1);
}).add;



// Synth reattivo con inviluppo ADSR
SynthDef(\saw, { arg busIn = 0, busOut = 0, pan = 0;
    var sig, gate, env;
    gate = In.ar(busIn, 1); // Riceve il trigger dal bus di analisi
    env = EnvGen.kr(Env.adsr, gate);
    sig = Saw.ar(LFNoise0.kr([10, 12]).range(300, 1000));
    sig = sig * env * 0.5;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig);
}).add;

// Synth percussivo creato via OSC
SynthDef(\noise, {arg busOut = 0, pan = 0;
    var sig, env;
    sig = PinkNoise.ar;
    // Inviluppo percussivo con durata casuale
    env = EnvGen.kr(Env.perc(0.01, TRand.kr(0.02, 0.1, 1)), 1, doneAction: 2);
    sig = sig * env;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig)
}).add;


// Analizzatore di Brillantezza (Centroid)
SynthDef(\scentr, {arg busIn = 0, busOut = 0;
    var sig, chain;
    sig = In.ar(busIn, 1);
    // LocalBuf alloca memoria temporanea per la FFT sul Server
    chain = FFT(LocalBuf(2048), sig);
    sig = SpecCentroid.kr(chain);
    sig.poll(10, "Centroid"); // Stampa i valori 10 volte al secondo
    Out.kr(busOut, sig); // Esce come segnale di controllo (.kr)
}).add;

// Analizzatore di Rumorosità (Flatness)
SynthDef(\sflat, {arg busIn = 0, busOut = 0;
    var sig, chain;
    sig = In.ar(busIn, 1);
    chain = FFT(LocalBuf(2048), sig);
    sig = SpecFlatness.kr(chain);
    sig.poll(10, "Flatness");
    Out.kr(busOut, sig);
}).add;

// Synth Reattivo: Un'onda a dente di sega filtrata
SynthDef(\fnoise, {arg busIn = 0, busOut = 0, freq = 440, pan = 0, gate = 0, bw = 0.2;
    var sig, amp, env;
    sig = Saw.ar(100); // Frequenza base fissa
    amp = In.ar(busIn, 1);
    amp = Amplitude.ar(amp); // Segue anche l'inviluppo di ampiezza

    // Resonz è un filtro risonante. La frequenza e la larghezza di banda
    // saranno controllate dall'analisi spettrale
    sig = Resonz.ar(sig, freq.lag(0.5), bw.lag(0.5));

    env = Linen.kr(gate, doneAction: 2);
    sig = sig * env * amp * 4;
    sig = Pan2.ar(sig, pan);
    Out.ar(busOut, sig);
}).add;

"Libreria Features SynthDef caricata.".postln;

)