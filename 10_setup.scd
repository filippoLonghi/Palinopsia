ServerOptions.devices;

(
Server.default = s = Server.local;

// --- SCEGLI QUI ---
//s.options.device = "Windows WASAPI : Altoparlanti (Realtek(R) Audio)"; // PC
//s.options.device = "Windows WASAPI : Headphones (Pixel Buds Pro di Filippo)"; // CUFFIE

s.options.device = "ASIO : Universal Audio Volt"; // Scheda Audio Giacomo

s.options.numInputBusChannels = 1;
s.options.numOutputBusChannels = 1;

s.options.sampleRate = 48000;
s.options.blockSize  = 256;
s.options.hardwareBufferSize = 256;
s.options.memSize = 2.pow(18); // 524288 KB = 512 MB

TempoClock.default.tempo = 1;

s.waitForBoot {

    // --- RESET TOTALE ---
    s.newBusAllocators;
    Buffer.freeAll;
    s.sync;

    // --- 1. BUFFER ---
	~slicePool = List.new;
    ~lastSlice = Buffer.alloc(s, s.sampleRate * 1, 1);
    ~blive = Buffer.alloc(s, s.sampleRate * 10, 1);

    s.sync;

    // --- 2. BUS ---
    ~micBus = Bus.audio(s, 1);
    ~kpos = Bus.audio(s, 1); // Bus audio per puntatore sincrono

	// Dizionario per i bus di controllo del FREQUENCY SHIFTER
    ~fBuses = Dictionary.new;
    [\fshift, \mix, \amp].do({ |key| ~fBuses[key] = Bus.control(s, 1); });

	// Dizionario per i bus di controllo della RING MODULATION
    ~rBuses = Dictionary.new;
    [\fmod, \idx, \amp].do({ |key| ~rBuses[key] = Bus.control(s, 1); });

	// Dizionario per i bus di controllo dell'HARMONIZER (Sincrono)
	~hBuses = Dictionary.new;
	[\pos, \trig, \gdur, \trsp, \amp].do({ |key| ~hBuses[key] = Bus.control(s, 1); });

    // Dizionario per i bus di controllo del GRANULATOR
    ~gBuses = Dictionary.new;
    [\pos, \trig, \gdur, \trsp, \amp].do({ |key| ~gBuses[key] = Bus.control(s, 1); });

	// Dizionario per i bus di controllo dello SLICING
    ~sBuses = Dictionary.new;
    [\pos, \dur, \trsp, \amp, \wait, \dir].do({ |key| ~sBuses[key] = Bus.control(s, 1); });

	// Dizionario per i bus di controllo dei DELAY
    ~dBuses = Dictionary.new;
    [\del, \mix, \decayT, \fbk, \rate, \amp].do({ |key| ~dBuses[key] = Bus.control(s, 1); });

    s.sync;

    // --- 3. GRUPPI ---
    ~micGrp  = Group.new;
    ~featGrp = Group.after(~micGrp);
    ~recGrp  = Group.after(~featGrp);
    ~fxGrp   = Group.after(~recGrp);

    s.sync;

    // --- 4. FUNZIONI UTILI ---
	~cleanAll = {
        ~fxGrp.freeAll;   // Ferma tutti i synth degli effetti
        ~recGrp.freeAll;  // Ferma i registratori e i ksig
        ~featGrp.freeAll; // Ferma le analisi spettrali

        // OPZIONALE: Libera la memoria dei buffer registrati per resettare la cronologia
        // ~slicePool.do(_.free); ~slicePool = List.new;

        "Sistema resettato. Gruppi liberati. Cronologia buffer mantenuta.".postln; [cite: 161]
    };

    s.meter; s.plotTree;
    "SISTEMA PRONTO: Bus e Gruppi configurati.".postln;
};
)