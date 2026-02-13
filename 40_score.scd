(
~hpVol.(1); // volume generale delle cuffie
~hpMix.(0.2, 7); // Elettronica, Cello
~hpMode.(1); // Modalità MONO
~asyncMixer.(1.7);
)
~startTimer.(5);
~stopTimer.();
// Test volumi
// Rec per test
~recStart.();
~recStop.();
// 1
(
~sliceTrspProgression.(bufIndex: 1, totalDur: 45, amp: 1, stepTime: 2);
~delayOn.(\fbk);
~delaySetAmp.(10);
~delayCtrl.(\del, type: -1, val: 1);
~delayCtrl.(\decayT, type: -1, val: 0);
~delayCtrl.(\mix, type: -1, val: 0);
)
// 2
(
~delayOff.();
~harmOn.();
~harmSetAmp.(3);
~harmCtrl.(\trig, type: 5, freq: 150);
~harmCtrl.(\trsp, type: 2, freq: 100, range: [-8, 8]);
~harmCtrl.(\gdur, type: -1, val: 8);
)
// 3
(
~harmOff.();
~ringOn.();
~ringSetAmp.(6);
~ringCtrl.(\fmod, type: -1, val: 20);
~ringCtrl.(\idx, type: -1, val: 1.5);
)
(
~sliceOff.();
~ringOff.();
)

// PRIMA SEZIONE
// Rec 1 (tre note ribattute cello)
~recStart.();
~recStop.();
// Un cambio ogni 22 secondi, l'ultimo guarda filo (grave)
(
~sliceChaosToPulses.(bufIndex: 1, totalDur: 90, amp: 3.5, stepTime: 22);
~harmOn.();
~harmSetAmp.(0.7);
~harmCtrl.(\trig, type: 5, freq: 50);
~harmCtrl.(\trsp, type: -1, val: 0);
~harmCtrl.(\gdur, type: -1, val: 0.5);
)
(
~harmSetAmp.(2.2);
~harmCtrl.(\trig, type: 5, freq: 80);
~harmCtrl.(\trsp, type: -1, val: -2);
~harmCtrl.(\gdur, type: -1, val: 1.3);
)
(
~harmSetAmp.(2.6);
~harmCtrl.(\trig, type: 5, freq: 150);
~harmCtrl.(\trsp, type: -1, val: -4);
~harmCtrl.(\gdur, type: -1, val: 2.5);
)
(
~harmSetAmp.(3);
~harmCtrl.(\trsp, type: -1, val: -6);
~harmCtrl.(\gdur, type: -1, val: 4);
)
// Deve emergere la pulsazione asincrona
~asyncMixer.(1.7);
(
~harmCtrl.(\trsp, type: 2, freq: 100, range: [-8, 8]);
~harmCtrl.(\gdur, type: -1, val: 8);
)
(
~sliceOff.();
~harmOff.();
~stopTimer.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1.5);
)

// SECONDA SEZIONE
// Prima parte
// Rec 2 (ostinato 6 crome)
~recStart.();
~recStop.();
~grainProgression.(bufIndex: 2, totalDur: 30, amp: 8, stepTime: nil);
// Dire a filo quando finisce progressione
// Rec 3 (tema secondo movimento)
~recStart.();
~recStop.();

// Seconda parte
// Un cambio ogni 2 secondi
(
~stopTimer.();
~grainOff.();
~sliceTrspProgression.(bufIndex: 3, totalDur: 45, amp: 1, stepTime: 2);
~delayOn.(\fbk);
~delaySetAmp.(10);
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
~asyncMixer.(1.5);
)
(
~delayOn.(\echo);
~delaySetAmp.(10);
~delayCtrl.(\del, type: -1, val: 0.3);
~delayCtrl.(\mix, type: -1, val: 0);
)
// Bordellone
~delayCtrl.(\del, type: -1, val: 0.5);
~delayCtrl.(\del, type: -1, val: 0.7);
~delayCtrl.(\del, type: -1, val: 0.9);
~delayCtrl.(\del, type: -1, val: 1);
// Guardare filo
~delayCtrl.(\del, type: 2, freq: 1, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 2, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 4, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 8, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 10, range: [-1, 1]);
~delayCtrl.(\del, type: 2, freq: 20, range: [-1, 1]);

~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1.5);
(
~sliceOff.();
~stopTimer.();
)
// ATTENZIONE: Cello suona tre note ribattute due volte
(
~delayOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1.5);
)

// TERZA SEZIONE
// Imposta buffer su rec1
(
~useSlice.(1);
~grainOn.();
~grainSetAmp.(1);
~grainCtrl.(\trsp, type: 2, freq: 70, range: [0, 48]);
~grainCtrl.(\gdur, type: -1, val: 3.5);
~grainCtrl.(\pos, type: -1, val: 0);
~grainCtrl.(\trig, type: 5, freq: 0.6);
~ringOn.();
~ringSetAmp.(6);
~ringCtrl.(\fmod, type: -1, val: 20);
~ringCtrl.(\idx, type: -1, val: 1.5);
)
// Guarda filo, un cambio ogni 5 secondi
(
~grainSection3Progression.(totalDur: 45, stepTime: 5);
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
~stopTimer.();
~grainOff.();
~ringOff.();
~masterMixer.(1);
~syncMixer.(1);
~asyncMixer.(1.5);
)
// CODA
// Rec 4 (arpeggi di armonici dal terzo)
~recStart.();
~recStop.();
// Glissando cello
(
~syncMixer.(1.5);
~codaProgression.(bufIndex: 4, totalDur: 30, ampS: 8, ampG: 1.5, stepTime: nil);
)
~sliceSetAmp.(8);
~grainSetAmp.(1.5);
// Guarda filo per
(
~stopTimer.();
~sliceOff.();
~grainOff.();
)
// Armonico/rumore cello