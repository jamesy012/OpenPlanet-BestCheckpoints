#if false
class STMRecord {
    string trackName;
    array<int> trackTimes;

    STMRecord(string name, array<int> times){
        trackName = name;
        trackTimes = times;
    }
}

//STMRecord[] STMRecords = [STMRecord("../SuperTrackmasters/001_C_Discovery_euronics.riolu!(00'32''256)", times)];
STMRecord@[] STMRecords = {STMRecord("../SuperTrackmasters/001_C_Discovery_euronics.riolu!(00'32''256)", {11545,9857,6559,4295})};
#endif