(
Server.default = s = Server.local;

// --- SCEGLI QUI ---
//s.options.device = "Windows WASAPI : Altoparlanti (Realtek(R) Audio)"; // PC
//s.options.device = "Windows WASAPI : Headphones (Pixel Buds Pro di Filippo)"; // CUFFIE

s.options.device = "ASIO : Universal Audio Volt"; // Scheda Audio Giacomo

s.options.numInputBusChannels = 1;
s.options.numOutputBusChannels = 4;

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
	~monGrp  = Group.after(~fxGrp);

    s.sync;

    // --- 4. FUNZIONI UTILI ---
	~cleanAll = {
		~monGrp.freeAll;
        ~fxGrp.freeAll;
        ~recGrp.freeAll;
        ~featGrp.freeAll;

        // OPZIONALE: Reset pool
        // ~slicePool.do(_.free); ~slicePool = List.new;

        "Sistema resettato. Gruppi liberati. Cronologia buffer mantenuta.".postln;
    };

    // --- 5. DASHBOARD "MONOLITICA" (Layout Affiancato) ---
    ~startDashboard = {
        // --- 1. PARAMETRI DI POSIZIONAMENTO (MODIFICA QUI) ---
        var screenW = Window.screenBounds.width;  // larghezza totale del monitor.
        var screenH = Window.screenBounds.height; // altezza totale del monitor

        // DIMENSIONI
        var meterW = 120;
        var treeW  = 400;
		var timerW = 200;
		var marginW = 5;
        var toolsH = 500;
		var nameBarH = 50;
		var meterH = toolsH - meterW - nameBarH;

        // CALCOLO COORDINATE
		var timerX = screenW - timerW - marginW;
		var treeX = timerX - treeW - marginW;
		var meterX = treeX - meterW - marginW;
		var startY = screenH - toolsH - nameBarH;
		var mStartY = startY + toolsH - meterH;

		// POSIZIONAMENTO
        var timerRect = Rect(
			timerX,    // X start
			startY,    // Y start (sopra gli strumenti)
            timerW,    // Larghezza totale
            toolsH     // Altezza
        );

        var treeRect = Rect(
            treeX,    // X start (più a destra)
            startY,    // Y start (basso)
            treeW,     // Larghezza
            toolsH     // Altezza
        );

        var meterRect = Rect(
            meterX,     // X start (più a sinistra)
            mStartY,    // Y start (basso)
            meterW,    // Larghezza
            meterH     // Altezza
        );

        // --- 2. PULIZIA E AVVIO ---
        Window.closeAll;

		// A. LANCIO TOOL ESTERNI
        s.meter;
        s.plotTree;

        // B. TIMER
        ~dashboard = Window("Timer", timerRect, border: true)
            .front
            .alwaysOnTop_(true)
            .background_(Color.new255(220, 220, 220))
            .userCanClose_(false);

        ~timerText = StaticText(~dashboard, Rect(0, 0, timerW, toolsH))
            .string_("0")
            .font_(Font("Monaco", 60, true))
            .align_(\center)
            .stringColor_(Color.black);

        // C. IL GUARDIANO (Ora controlla 3 finestre)
        ~windowKeeper = Routine({
            inf.do {
                // Cerca le finestre per nome
				var meterWin = Window.allWindows.detect({ |w| w.name.contains("localhost levels (dBFS)") });
                var treeWin  = Window.allWindows.detect({ |w| w.name == "localhost Node Tree" });

                // 1. CONTROLLO METER
                if(meterWin.notNil) {
                    if(meterWin.bounds != meterRect) {
                        meterWin.bounds = meterRect;
                        meterWin.alwaysOnTop_(true);
                    };
                };

                // 2. CONTROLLO TREE
                if(treeWin.notNil) {
                    if(treeWin.bounds != treeRect) {
                        treeWin.bounds = treeRect;
                        treeWin.alwaysOnTop_(true);
                    };
                };

                // 3. CONTROLLO TIMER (Lo forziamo pure lui per sicurezza)
                if(~dashboard.bounds != timerRect) {
                   ~dashboard.bounds = timerRect;
                   ~dashboard.alwaysOnTop_(true);
                };

                1.wait; // Controlla ogni secondo
            };
        }).play(AppClock);

        ~dashboard.onClose_({ ~windowKeeper.stop; });
        "DASHBOARD LAYOUT: Meter e Tree affiancati.".postln;
    };

    // --- FUNZIONI TIMER ---
    ~startTimer = { |alertEvery = nil|
        if(~timerRoutine.notNil) { ~timerRoutine.stop };
        ~timerRoutine = Routine({
            var seconds = 0;
			{ ~timerText.stringColor_(Color.black); }.defer;
            inf.do {
                { ~timerText.string_(seconds.asString) }.defer;
                {
                    if(alertEvery.notNil and: { seconds > 0 } and: { seconds % alertEvery == 0 }) {
						~dashboard.background_(Color.new255(255, 255, 0));
                    } {
						~dashboard.background_(Color.new255(220, 220, 220));
                    };
                }.defer;
                1.wait;
                seconds = seconds + 1;
            };
        }).play(TempoClock.default);
    };

    ~stopTimer = {
        if(~timerRoutine.notNil) { ~timerRoutine.stop; ~timerRoutine = nil; };
        { ~timerText.stringColor_(Color.red) }.defer;
    };

    AppClock.sched(1.0, { ~startDashboard.(); nil });
	"SISTEMA PRONTO: Bus e Gruppi configurati.".postln;
};
)