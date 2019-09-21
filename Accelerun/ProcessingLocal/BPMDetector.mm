//
//  BPMDetector.m
//  BPMDetect
//
//  Sourced from SuperpoweredOfflineProcessingExample.
//  Modified by Bradley Klemick.
//

#import "BPMDetector.h"
#include "SuperpoweredDecoder.h"
#include "SuperpoweredAudioBuffers.h"
#include "SuperpoweredAnalyzer.h"
#include "Superpowered.h"
#include "SuperpoweredSimple.h"

@implementation BPMDetector {
    float durationSeconds;
    float detectedBpm;
    float beatStartMs;
    float peakDb;
    float progress;
}

- (void)initSuperpowered:(const char *)apiKey
{
    Superpowered::Initialize(apiKey, true, true, true, true, true, false, false);
}

- (void)calc:(NSURL *)fileURL
{
    Superpowered::Decoder *decoder = [self getSongDecoderForFileURL:fileURL]; // where url is the audio song which is either in bundle or in your app document directory
    
    if (!decoder) {
        NSLog(@"Handle Error that decoder is not created");
        return;
    }
    [self processSongForDecoder:decoder];
    delete decoder;
    
    return;
}

/**
 Open a song at a URL into a folder.
 From SuperpoweredOfflineProcessingExample openSourceFile method.
 */
-(Superpowered::Decoder *)getSongDecoderForFileURL:(NSURL *)fileURL {
    Superpowered::Decoder *decoder = new Superpowered::Decoder();
    
    while (true) {
        int openReturn = decoder->open([[fileURL absoluteString] UTF8String]);
    
        switch (openReturn) {
            case Superpowered::Decoder::OpenSuccess: return decoder;
            case Superpowered::Decoder::BufferingTryAgainLater: usleep(100000); break; // May happen for progressive downloads. Wait 100 ms for the network to load more data.
            default:
                delete decoder;
                NSLog(@"Open error %i: %s", openReturn, Superpowered::Decoder::statusCodeToString(openReturn));
                return NULL;
        }
    }
}

/**
 Decode the song, and then analyze it for BPM, beat start offset, and peak level information.
 Inspired by SuperpoweredOfflineProcessingExample offlineAnalyze method.
 */
-(void)processSongForDecoder:(Superpowered::Decoder *)decoder {
    // Create the analyzer.
    durationSeconds = decoder->getDurationSeconds();
    Superpowered::Analyzer *analyzer = new Superpowered::Analyzer(decoder->getSamplerate(), durationSeconds);

    // Create a buffer for the 16-bit integer audio output of the decoder.
    short int *intBuffer = (short int *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(short int) + 16384);
    // Create a buffer for the 32-bit floating point audio required by the effect.
    float *floatBuffer = (float *)malloc(decoder->getFramesPerChunk() * 2 * sizeof(float) + 16384);

    // Processing.
    while (true) {
        int framesDecoded = decoder->decodeAudio(intBuffer, decoder->getFramesPerChunk());
        if (framesDecoded == Superpowered::Decoder::BufferingTryAgainLater) { // May happen for progressive downloads.
            usleep(100000); // Wait 100 ms for the network to load more data.
            continue;
        } else if (framesDecoded < 1) break;

        // Submit the decoded audio to the analyzer.
        Superpowered::ShortIntToFloat(intBuffer, floatBuffer, framesDecoded);
        analyzer->process(floatBuffer, framesDecoded);

        progress = (double)decoder->getPositionFrames() / (double)decoder->getDurationFrames();
    };
    
    analyzer->makeResults(60, 200, 0, 0, true, false, false, false, false);
    
    detectedBpm = analyzer->bpm;
    beatStartMs = analyzer->beatgridStartMs;
    peakDb = analyzer->peakDb;
    
    delete analyzer;
    free(intBuffer);
    free(floatBuffer);
}

- (float)getDurationSeconds
{
    return durationSeconds;
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
