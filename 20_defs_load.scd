(
PathName(thisProcess.nowExecutingPath.dirname +/+ "Library").filesDo { |file|
    if(file.extension == "scd") {
        file.fullPath.load;
        ("Caricato: " + file.fileName).postln;
    }
};
)