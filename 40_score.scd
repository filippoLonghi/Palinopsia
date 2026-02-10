(
~sliceChaosToPulses = { |bufIndex = 0, totalDur = 30, amp = 1|
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
		~sliceSetAmp.(5);

		"--- FINISH Slicer Progression ---".postln;
	}).play;
};

~grainProgression = { |bufIndex = 0, totalDur = 60, amp = 1|
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

		~useSlice.(bufIndex);
        ~grainOn.();
        ~grainCtrl.(\amp,  type: -1, val: amp);
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

~sliceTrspProgression = { |bufIndex = 0, totalDur = 60, amp = 1|
    Routine({
        var steps = [-2, -4, -6, -8, -12];
        // Coefficienti per compensare la perdita di volume al calare del pitch
        var ampRatios = [1.2, 1.4, 1.5, 1.65, 1.8];
        var waitTime = totalDur / (steps.size + 1);

        "--- INIZIO PROGRESSIONE SLICER (Durata: %s) ---".format(totalDur).postln;

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

~grainSection3Progression = { |bufIndex = 0, totalDur = 30|
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

		// ESECUZIONE SEQUENZIALE
		~useSlice.(bufIndex);
		steps.do { |action, i|
			"Trig Step % di % (freq crescente)".format(i + 1, steps.size).postln;
			action.value;
			waitTime.wait;
		};

		"--- FINISH Progresione TRIG ---".postln;
	}).play;
};

~codaProgression = { |bufIndex = 0, totalDur = 60, ampS = 1, ampG = 1|
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

~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1);
)

// PRIMA SEZIONE
// Rec 1 (tre note ribattute cello)
~recStart.();
~recStop.();
// Un cambio ogni 22 secondi, l'ultimo guarda filo (grave)
(
~sliceChaosToPulses.(bufIndex: 0, totalDur: 90, amp: 3.5);
~harmOn.();
~harmCtrl.(\trig, type: 5, freq: 50);
~harmCtrl.(\amp,  type: -1, val: 1-0.3);
~harmCtrl.(\trsp, type: -1, val: 0);
~harmCtrl.(\gdur, type: -1, val: 0.5);
)
(
~harmCtrl.(\trig, type: 5, freq: 80);
~harmCtrl.(\amp,  type: -1, val: 1.8+0.4);
~harmCtrl.(\trsp, type: -1, val: -2);
~harmCtrl.(\gdur, type: -1, val: 1.3);
)
(
~harmCtrl.(\trig, type: 5, freq: 150);
~harmCtrl.(\amp,  type: -1, val: 2+0.6);
~harmCtrl.(\trsp, type: -1, val: -4);
~harmCtrl.(\gdur, type: -1, val: 2.5);
)
(
~harmCtrl.(\amp,  type: -1, val: 2.2+0.8);
~harmCtrl.(\trsp, type: -1, val: -6);
~harmCtrl.(\gdur, type: -1, val: 4);
)
// Deve emergere la pulsazione asincrona
~asyncMixer.(1);
(
~harmCtrl.(\trsp, type: 2, freq: 100, range: [-8, 8]);
~harmCtrl.(\gdur, type: -1, val: 8);
)
(
~sliceOff.();
~harmOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1);
)

// SECONDA SEZIONE
// Prima parte
// Rec 2 (ostinato 6 crome)
~recStart.();
~recStop.();
~grainProgression.(bufIndex: 1, totalDur: 30, amp: 8); // Amp = 1

// Rec 3 (tema secondo movimento)
~recStart.();
~recStop.();

// Seconda parte
// Un cambio ogni 2 secondi
(
~grainOff.();
~sliceTrspProgression.(bufIndex: 2, totalDur: 45, amp: 1); // Amp = 0.5
~delayOn.(\fbk);
~delayCtrl.(\amp, type: -1, val: 10);
~delayCtrl.(\del, type: -1, val: 1);
~delayCtrl.(\decayT, type: -1, val: 0);
~delayCtrl.(\mix, type: -1, val: 0);
)
~delayCtrl.(\decayT, type: -1, val: 1);
~delayCtrl.(\decayT, type: -1, val: 2);
(
~delayCtrl.(\del, type: -1, val: 0.9);
~delayCtrl.(\decayT, type: -1, val: 3);
)
(
~delayCtrl.(\del, type: -1, val: 0.7);
~delayCtrl.(\decayT, type: -1, val: 4);
)
(
~delayCtrl.(\del, type: -1, val: 0.5);
~delayCtrl.(\decayT, type: -1, val: 5);
)
(
~delayCtrl.(\del, type: -1, val: 0.3);
~delayCtrl.(\decayT, type: -1, val: 7);
)
(
~delayOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1);
)
(
~delayOn.(\echo);
~delayCtrl.(\amp, type: -1, val: 10);
~delayCtrl.(\del, type: -1, val: 0.3);
~delayCtrl.(\mix, type: -1, val: 0);
)
~delayCtrl.(\del, type: -1, val: 0.5);
~delayCtrl.(\del, type: -1, val: 0.7);
~delayCtrl.(\del, type: -1, val: 0.9);
~delayCtrl.(\del, type: -1, val: 1);

~delayCtrl.(\del, type: 2, freq: 1, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 2, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 4, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 8, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 10, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 20, range: [-1, 1]);

~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1.5);

~sliceOff.();
// ATTENZIONE: Cello suona tre note ribattute due volte
(
~delayOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1);
)

// TERZA SEZIONE
// Imposta buffer su rec1
(
~useSlice.(0);
~grainOn.();
~grainSetAmp.(1);
~grainCtrl.(\trsp, type: 2, freq: 70, range: [0, 48]);
~grainCtrl.(\gdur, type: -1, val: 3.5);
~grainCtrl.(\pos, type: -1, val: 0);
~grainCtrl.(\trig, type: 5, freq: 0.6);
~ringOn.();
~ringCtrl.(\amp, type: -1, val: 6);
~ringCtrl.(\fmod, type: -1, val: 20);
~ringCtrl.(\idx, type: -1, val: 1.5);
)
// Guarda filo, un cambio ogni 5 secondi
(
~grainSection3Progression.(bufIndex: 0, totalDur: 45); // Amp = 1
~ringCtrl.(\fmod, type: -1, val: 30);
)
~ringCtrl.(\fmod, type: -1, val: 40);
(
~ringCtrl.(\fmod, type: -1, val: 50);
~ringCtrl.(\idx, type: -1, val: 1.8);
)
~ringCtrl.(\fmod, type: -1, val: 60);
~ringCtrl.(\fmod, type: -1, val: 70);
(
~ringCtrl.(\fmod, type: -1, val: 80);
~ringCtrl.(\idx, type: -1, val: 2);
)
~ringCtrl.(\fmod, type: -1, val: 90);
(
~ringCtrl.(\fmod, type: -1, val: 100);
~ringCtrl.(\idx, type: -1, val: 2.5);
)
// Progressione discendente di ottave
(
~grainOff.();
~ringOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1);
)
// CODA
// Rec 4 (arpeggi di armonici)
~recStart.();
~recStop.();
// Glissando cello
~codaProgression.(bufIndex: 3, totalDur: 30, ampS: 8, ampG: 1.5); // Amp = slice 5, grain 0.4
~grainSetAmp.(1.5);
~sliceSetAmp.(5);
(
~sliceOff.();
~grainOff.();
)
// Armonico/rumore cello