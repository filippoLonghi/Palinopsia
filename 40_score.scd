// PRIMA SEZIONE

// Rec 1 (tre note ribattute cello)

(
~sliceChaosToPulses = { |bufIndex=0, totalDur=30, chaosFrac=0.7|
	var chaosDur, posFixDur, trspFixDur, durFixDur;
	var chaosSteps = 7, posFixSteps = 3, trspFixSteps = 3, durFixSteps = 3;
	var step;

	var waitChaos  = [0.01, 0.02, 0.05, 0.10, 0.20, 0.50, 0.80];
	var waitPosFix = [1.00, 1.20, 1.35];
	var waitTrspFix= [1.50, 1.65, 1.80];
	var waitDurFix = [1.90, 1.95, 2.00];

	var posF  = [20, 12, 8, 5, 3, 1, 0.4];
	var durF  = [12,  8, 5, 3, 2, 0.7, 0.3];
	var trspF = [150, 90,60,40,25,10, 4];

	var posFixVals  = [0.55, 0.63, 0.70];
	var trspFixVals = [ 1.0, 0.5, 0.0];
	var durFixVals  = [0.22, 0.27, 0.30];

	chaosDur  = totalDur * chaosFrac;
	posFixDur = totalDur * (1 - chaosFrac) * 0.70;
	trspFixDur= totalDur * (1 - chaosFrac) * 0.20;
	durFixDur = totalDur * (1 - chaosFrac) * 0.10;

	Routine({
		~useSlice.(bufIndex);
		~sliceOn.();
		~sliceCtrl.(\amp, type: -1, val: 0.6);
		~sliceCtrl.(\dir, type: -1, val: 1);

		step = chaosDur / chaosSteps;
		chaosSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitChaos[i]);
			~sliceCtrl.(\pos,  type: 2, range: [0, 1],      freq: posF[i]);
			~sliceCtrl.(\dur,  type: 2, range: [0.05, 0.7],  freq: durF[i]);
			~sliceCtrl.(\trsp, type: 2, range: [-12, 12],  freq: trspF[i]);
			step.wait;
		};

		step = posFixDur / posFixSteps;
		posFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitPosFix[i]);
			~sliceCtrl.(\pos,  type: -1, val: posFixVals[i]);

			// mantieni modulazione ma più lenta
			~sliceCtrl.(\dur,  type: 2, range: [0.2, 0.5],  freq: 0.25);
			~sliceCtrl.(\trsp, type: 2, range: [-6, 6],  freq: 3);
			~sliceCtrl.(\amp, type: -1, val: 1.5);
			step.wait;
		};

		step = trspFixDur / trspFixSteps;
		trspFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitTrspFix[i]);
			~sliceCtrl.(\trsp, type: -1, val: trspFixVals[i]);

			~sliceCtrl.(\dur,  type: 2, range: [0.3, 0.4],  freq: 0.18);
			~sliceCtrl.(\amp, type: -1, val: 2.2);
			step.wait;
		};

		step = durFixDur / durFixSteps;
		durFixSteps.do { |i|
			~sliceCtrl.(\wait, type: -1, val: waitDurFix[i]);
			~sliceCtrl.(\dur,  type: -1, val: durFixVals[i]);
			~sliceCtrl.(\amp, type: -1, val: 3);
			step.wait;
		};

		~sliceCtrl.(\wait, type: -1, val: 2.0);
		~sliceCtrl.(\pos,  type: -1, val: 0.7);
		~sliceCtrl.(\trsp, type: -1, val: 0);
		~sliceCtrl.(\dur,  type: -1, val: 0.3);
		~sliceCtrl.(\amp, type: -1, val: 3.5);
	}).play;
};

~sliceChaosToPulses.(bufIndex: 0, totalDur: 90, chaosFrac: 0.95); // caos ancora più lungo
)

~syncMixer.(0.2);
~asyncMixer.(2.0);

~sliceSetAmp.(5.0);

(
~grainCtrl.(\trig, type: 5, freq: 50);
~grainCtrl.(\amp,  type: -1, val: 0.4);
~grainCtrl.(\trsp, type: -1, val: 0);
~grainCtrl.(\gdur, type: -1, val: 0.5);
)
(
~grainCtrl.(\trig, type: 5, freq: 80);
~grainCtrl.(\amp,  type: -1, val: 0.6);
~grainCtrl.(\trsp, type: -1, val: -2);
~grainCtrl.(\gdur, type: -1, val: 1.3);
)
(
~grainCtrl.(\trig, type: 5, freq: 150);
~grainCtrl.(\amp,  type: -1, val: 0.9);
~grainCtrl.(\trsp, type: -1, val: -5);
~grainCtrl.(\gdur, type: -1, val: 2.5);
)
(
~grainCtrl.(\amp,  type: -1, val: 0.8);
~grainCtrl.(\trsp, type: -1, val: -4);
~grainCtrl.(\gdur, type: -1, val: 4);
)
(
~grainCtrl.(\amp,  type: -1, val: 0.7);
~grainCtrl.(\trsp, type: -1, val: -3);
~grainCtrl.(\gdur, type: -1, val: 6.8);
)
(
~grainCtrl.(\amp,  type: -1, val: 1);
~grainCtrl.(\trsp, type: 2, freq: 100, range: [-6, 6]);
~grainCtrl.(\gdur, type: -1, val: 8);
)
(
~grainCtrl.(\amp,  type: -1, val: 0.4);
~grainCtrl.(\trsp, type: -1, val: 0);
)
(
~grainCtrl.(\amp,  type: -1, val: 0.5);
~grainCtrl.(\trsp, type: -1, val: -1);
)
(
~grainCtrl.(\amp,  type: -1, val: 1.1);
~grainCtrl.(\trsp, type: -1, val: -7);
)
(
~grainCtrl.(\amp,  type: -1, val: 1.2);
~grainCtrl.(\trsp, type: -1, val: -8);
)
(
~grainCtrl.(\amp,  type: -1, val: 0.8);
~grainCtrl.(\trsp, type: -1, val: -4);
)

~harmSetAmp.(0.8);
~sliceOff.();


// SECONDA SEZIONE

// Prima parte

// Rec 2 (ostinato 6 crome)
(
~grainOn.();
~grainCtrl.(\trig, type: 2, freq: 2, range: [-1, 1]);
~grainCtrl.(\amp,  type: -1, val: 2.5);
~grainCtrl.(\trsp, type: -1, val: 0);
~grainCtrl.(\gdur, type: -1, val: 3);
~grainCtrl.(\pos, type: -1 , val: 0);
)

~grainCtrl.(\trig, type: 2, freq: 3, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 4, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 5, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 6, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 7, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 8, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 9, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 10, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 11, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 12, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 13, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 14, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 15, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 16, range: [-1, 1]);
~grainCtrl.(\trig, type: 2, freq: 17, range: [-1, 1]);

~grainCtrl.(\trsp, type: 2, freq: 70, range: [-1, 1]);
~grainCtrl.(\trsp, type: 2, freq: 70, range: [-2, 2]);
~grainCtrl.(\trsp, type: 2, freq: 70, range: [-3, 3]);
~grainCtrl.(\trsp, type: 3, freq: 70, range: [-4, 4]);
~grainCtrl.(\trsp, type: 3, freq: 70, range: [-5, 5]);
~grainCtrl.(\trsp, type: 3, freq: 70, range: [-6, 6]);
~grainCtrl.(\trsp, type: 3, freq: 70, range: [-7, 7]);
~grainCtrl.(\trsp, type: 3, freq: 70, range: [-8, 8]);

~grainOff.();

// Rec 3 (tema secondo movimento)

// Seconda parte
(
~sliceCtrl.(\pos, type: 2, freq: 1, range: [2, 8]);
~sliceCtrl.(\dir, type: 2, freq: 1, range: [-1, 1]);
~sliceCtrl.(\wait, type: -1, val: 1);
)

(
~delayOn.(\fbk);
~delayCtrl.(\amp, type: -1, val: 2);
~delayCtrl.(\del, type: -1, val: 1);
~delayCtrl.(\decayT, type: -1, val: 0);
~delayCtrl.(\mix, type: -1, val: 0);
~sliceCtrl.(\trsp, type: -1, val: -2);
)

~delayCtrl.(\decayT, type: -1, val: 1);

~delayCtrl.(\decayT, type: -1, val: 2);

(
~delayCtrl.(\del, type: -1, val: 0.9);
~delayCtrl.(\decayT, type: -1, val: 3);
~sliceCtrl.(\trsp, type: -1, val: -4);
)
(
~delayCtrl.(\del, type: -1, val: 0.7);
~delayCtrl.(\decayT, type: -1, val: 4);
)
(
~delayCtrl.(\del, type: -1, val: 0.5);
~delayCtrl.(\decayT, type: -1, val: 5);
~sliceCtrl.(\trsp, type: -1, val: -6);
)
(
~delayCtrl.(\del, type: -1, val: 0.3);
~delayCtrl.(\decayT, type: -1, val: 7);
)

~delayOff.();
(
~delayOn.(\echo);
~delayCtrl.(\amp, type: -1, val: 2);
~delayCtrl.(\del, type: -1, val: 0.5);
~delayCtrl.(\mix, type: -1, val: 0);
~sliceCtrl.(\trsp, type: -1, val: -8);
)

~delayCtrl.(\del, type: -1, val: 0.7);
~delayCtrl.(\del, type: -1, val: 0.9);

~delayCtrl.(\del, type: 2, freq: 1, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 2, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 4, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 8, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 10, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 20, range: [-1, 1]);
~sliceCtrl.(\trsp, type: -1, val: -12);

~sliceOff.();

// cello suona tre note ribattute

~delayOff.();

// TERZA SEZIONE
// Imposta buffer su rec1
(
~grainOn.();
~ringOn.();
~ringCtrl.(\amp, type: -1, val: 2);
~ringCtrl.(\fmod, type: -1, val: 20);
~ringCtrl.(\idx, type: -1, val: 1.5);

~grainCtrl.(\trig, type: 5, freq: 0.5);
~grainCtrl.(\amp,  type: -1, val: 0.8);
~grainCtrl.(\trsp, type: 2, freq: 70, range: [0, 48]);
~grainCtrl.(\gdur, type: -1, val: 3.5);
~grainCtrl.(\pos, type: -1 , val: 0);
)
(
~grainCtrl.(\trig, type: 5, freq: 1);
~ringCtrl.(\fmod, type: -1, val: 30);
)
(
~grainCtrl.(\trig, type: 5, freq: 3);
~ringCtrl.(\fmod, type: -1, val: 40);
)
(
~grainCtrl.(\trig, type: 5, freq: 5);
~grainCtrl.(\amp,  type: -1, val: 0.5);
~ringCtrl.(\fmod, type: -1, val: 50);
~ringCtrl.(\idx, type: -1, val: 1.8);
)
(
~grainCtrl.(\trig, type: 5, freq: 10);
~ringCtrl.(\fmod, type: -1, val: 60);
~grainCtrl.(\amp,  type: -1, val: 0.3);
)
(
~grainCtrl.(\trig, type: 5, freq: 20);
~ringCtrl.(\fmod, type: -1, val: 70);
~grainCtrl.(\amp,  type: -1, val: 0.2);
)
(
~grainCtrl.(\trig, type: 5, freq: 35);
~ringCtrl.(\fmod, type: -1, val: 80);
~ringCtrl.(\idx, type: -1, val: 2);
)
(
~grainCtrl.(\trig, type: 5, freq: 50);
~ringCtrl.(\fmod, type: -1, val: 90);
)
(
~grainCtrl.(\trig, type: 5, freq: 70);
~ringCtrl.(\fmod, type: -1, val: 100);
~ringCtrl.(\idx, type: -1, val: 2.5);
)
(
~grainOff.();
~ringOff.();
)

// Progressione discendente di ottave

//CODA

// Rec 4 (arpeggi di armonici)

// Glissando cello
(
~sliceOn.();
~sliceCtrl.(\amp,  type: -1, val: 10);
~sliceCtrl.(\pos, type: 5, freq: 500);
~sliceCtrl.(\dur,  type: 2, freq: 350, range: [0.1, 0.2]);
~sliceCtrl.(\trsp, type: -1, val: 0);
~sliceCtrl.(\dir, type: -1, val: 1);
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.4, 0.6]);
~grainOn.();
~grainCtrl.(\trig, type: 2, freq: 10, range:[-1, 1]);
~grainCtrl.(\amp,  type: -1, val: 0.4);
~grainCtrl.(\trsp, type: -1, val: 0);
~grainCtrl.(\gdur, type: -1, val: 3.5);
~grainCtrl.(\pos, type: -1 , val: 0);
)
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.3, 0.5]);
~grainCtrl.(\amp,  type: -1, val: 0.6);
)
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.25, 0.4]);
~grainCtrl.(\amp,  type: -1, val: 0.9);
)
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.2, 0.3]);
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.1, 0.15]);
~grainCtrl.(\amp,  type: -1, val: 1.1);
)
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.2, 0.3]);
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.25, 0.4]);
~grainCtrl.(\amp,  type: -1, val: 0.6);
)
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.3, 0.4]);
(
~sliceCtrl.(\wait, type: 2, freq: 300, range: [0.4, 0.6]);
~grainCtrl.(\amp,  type: -1, val: 0.2);
)
~sliceCtrl.(\dur,  type: 2, freq: 350, range: [0.02, 0.05]);
~sliceCtrl.(\dur,  type: -1, val: 0);
(
~sliceOff.();
~grainOff.();
)

// Armonico/rumore cello