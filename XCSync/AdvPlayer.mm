//
//  AdvPlayer.cpp
//  XCSync
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

#import "AdvPlayer.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAdvancedAudioPlayer.h"
#include "SuperpoweredIOSAudioIO.h"

@implementation AdvPlayer {
    SuperpoweredAdvancedAudioPlayer *player;
    SuperpoweredIOSAudioIO *output;
    float *stereoBuffer;
    float volume;
    unsigned int lastSamplerate;
}

static bool audioProcessing(void *clientdata, float **buffers, unsigned int inputChannels, unsigned int outputChannels, unsigned int numberOfSamples, unsigned int samplerate, uint64_t hostTime) {
    __unsafe_unretained AdvPlayer *self = (__bridge AdvPlayer *)clientdata;
    if (samplerate != self->lastSamplerate) {
        self->lastSamplerate = samplerate;
        self->player->setSamplerate(samplerate);
    };
    //uint64_t startTime = mach_absolute_time();
    if (self->volume == 0.0f)
        self->volume = 1.0f;
    bool silence = !self->player->process(self->stereoBuffer, false, numberOfSamples, self->volume, 0.0f, -1.0);
    
    //self->playing = self->player->playing;
    if (!silence) SuperpoweredDeInterleave(self->stereoBuffer, buffers[0], buffers[1], numberOfSamples); // The stereoBuffer is ready now, let's put the finished audio into the requested buffers.
    return !silence;
}

- (void)play:(NSURL *)fileURL
{
    if (posix_memalign((void **)&stereoBuffer, 16, 4096 + 128) != 0) abort();
    player = new SuperpoweredAdvancedAudioPlayer(NULL, NULL, 44100, 0);
    player->open([[fileURL absoluteString] UTF8String]);
    player->play(false);
    
    if (!output) {
        output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredMinimumSamplerate:44100 audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
        [output start];
    }
}

- (void)mapChannels:(multiOutputChannelMap *)outputMap inputMap:(multiInputChannelMap *)inputMap externalAudioDeviceName:(NSString *)externalAudioDeviceName outputsAndInputs:(NSString *)outputsAndInputs {
    outputMap->deviceChannels[0] = 0;
    outputMap->deviceChannels[1] = 1;
}

- (void)setTempo:(float)tempo
{
    player->setTempo(tempo, true);
}

- (void)setVolume:(float)newVolume
{
    volume = newVolume;
}

- (void)setBpm:(float)newBpm beatStartMs:(float)newBeatStartMs;
{
    player->setBpm(newBpm);
    player->setFirstBeatMs(newBeatStartMs);
}

- (double)getMsSinceLastBeat
{
    if (player && player->playing) {
        return player->msElapsedSinceLastBeat;
    } else {
        return -1;
    }
}

@end
