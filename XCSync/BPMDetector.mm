//
//  BPMDetector.m
//  BPMDetect
//
//  Created by Yuki Konda on 1/29/16.
//  Copyright © 2016 Yuki Konda. All rights reserved.
//

#import "BPMDetector.h"
#include "SuperpoweredDecoder.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAudioBuffers.h"
#include "SuperpoweredAnalyzer.h"

@implementation BPMDetector {
    float detectedBpm;
    float beatStartMs;
    float peakDb;
}

- (void)calc:(NSURL *)fileURL
{
    SuperpoweredDecoder *decoder = [self getSongDecoderForFileURL:fileURL]; // where url is the audio song which is either in bundle or in your app document directory
    
    if (!decoder) {
        NSLog(@"Handle Error that decoder is not created");
        return;
    }
    [self processSongForDecoder:decoder];
    delete decoder;
    
    return;
}

-(SuperpoweredDecoder *)getSongDecoderForFileURL:(NSURL *)fileURL {
    SuperpoweredDecoder *decoder = new SuperpoweredDecoder();
    const char *openError = decoder->open([[fileURL absoluteString] UTF8String]);
    if (openError) {
        NSLog(@"%s", openError);
        delete decoder;
        return nil;
    }
    return decoder;
}

-(void)processSongForDecoder:(SuperpoweredDecoder *)decoder {
    int sampleRate = decoder->samplerate;
    double durationSeconds = decoder->durationSeconds;
    
    SuperpoweredAudiopointerList *bufferPool = new SuperpoweredAudiopointerList(4, 1024 * 1024);             // Allow 1 MB max. memory for the buffer pool.
    
    SuperpoweredOfflineAnalyzer *analyzer = new SuperpoweredOfflineAnalyzer(sampleRate, 0, durationSeconds);
    
    short int *intBuffer = (short int *)malloc(decoder->samplesPerFrame * 2 * sizeof(short int) + 16384);
    float *floatBuffer = (float *)malloc(decoder->samplesPerFrame * 2 * sizeof(float) + 32768);
    
    int samplesMultiplier = 4; ////-->> Performance Tradeoff
    while (true) {
        // Decode one frame. samplesDecoded will be overwritten with the actual decoded number of samples.
        unsigned int samplesDecoded = decoder->samplesPerFrame * samplesMultiplier;
        if (decoder->decode(intBuffer, &samplesDecoded) != SUPERPOWEREDDECODER_OK) break;
        if (samplesDecoded < 1) break;
        
        SuperpoweredShortIntToFloat(intBuffer, floatBuffer, samplesDecoded);
        analyzer->process(floatBuffer, samplesDecoded);
    }
    
    delete bufferPool;
    free(intBuffer);
    
    unsigned char **averageWaveForm = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **peakWaveForm = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **lowWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **midWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **highWaveform = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    unsigned char **notes = (unsigned char **)malloc(150 * sizeof(unsigned char *));
    char **overViewWaveForm = (char **)malloc(durationSeconds * sizeof(char *));
    
    int *keyIndex = (int *)malloc(sizeof(int));
    int *waveFormSize = (int *)malloc(sizeof(int));
    int *overViewSize = (int *)malloc(sizeof(int));
    
    float *averageDecibel = (float *)malloc(sizeof(float));
    float *loudPartsAverageDecibel = (float *)malloc(sizeof(float));
    float *peakDecibel = (float *)malloc(sizeof(float));
    float *bpm = (float *)malloc(sizeof(float));
    float *beatGridStart = (float *)malloc(sizeof(float));
    
    analyzer->getresults(averageWaveForm, peakWaveForm, lowWaveform, midWaveform, highWaveform, notes, waveFormSize, overViewWaveForm, overViewSize, averageDecibel, loudPartsAverageDecibel, peakDecibel, bpm, beatGridStart, keyIndex);
    
    detectedBpm = bpm[0];
    beatStartMs = beatGridStart[0];
    peakDb = peakDecibel[0];
    
    free(averageWaveForm);
    free(peakWaveForm);
    free(lowWaveform);
    free(midWaveform);
    free(highWaveform);
    free(notes);
    free(overViewWaveForm);
    free(keyIndex);
    free(waveFormSize);
    free(averageDecibel);
    free(loudPartsAverageDecibel);
    free(peakDecibel);
    free(bpm);
    free(beatGridStart);
}

- (float)getBpm
{
    return detectedBpm;
}

- (float)getBeatStartMs
{
    return beatStartMs;
}

- (float)getPeakDb
{
    return peakDb;
}

@end
