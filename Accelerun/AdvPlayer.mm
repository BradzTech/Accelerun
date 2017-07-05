//
//  AdvPlayer.cpp
//  Accelerun
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

#import "AdvPlayer.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAdvancedAudioPlayer.h"
#include "SuperpoweredIOSAudioIO.h"
#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <CoreData/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Accelerun-Swift.h"

@implementation AdvPlayer {
    SuperpoweredAdvancedAudioPlayer *player;
    SuperpoweredIOSAudioIO *output;
    float *stereoBuffer;
    float volume;
    float origBPM;
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

void playerEventCallback(void *clientData, SuperpoweredAdvancedAudioPlayerEvent event, void *value) {
    switch (event) {
        case SuperpoweredAdvancedAudioPlayerEvent_EOF:
            ViewController.inst.eof;
            break;
        default:
            break;
    }
}

- (void)play:(NSURL *)fileURL
{
    if (posix_memalign((void **)&stereoBuffer, 16, 4096 + 128) != 0) abort();
    if (!player) {
        player = new SuperpoweredAdvancedAudioPlayer(NULL, playerEventCallback, 44100, 0);
        player->fixDoubleOrHalfBPM = true;
    }
    player->open([[fileURL absoluteString] UTF8String]);
    player->setTempo(1.0f, true);
    player->play(false);
    
    if (!output) {
        output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredMinimumSamplerate:44100 audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
        [output start];
    }
}

- (void)resume {
    if (player) {
        player->play(false);
    }
}

- (void)pause {
    if (player) {
        player->pause();
    }
}

- (void)mapChannels:(multiOutputChannelMap *)outputMap inputMap:(multiInputChannelMap *)inputMap externalAudioDeviceName:(NSString *)externalAudioDeviceName outputsAndInputs:(NSString *)outputsAndInputs {
    outputMap->deviceChannels[0] = 0;
    outputMap->deviceChannels[1] = 1;
}

- (void)setTargetBpm:(float)targetBpm
{
    if (player && origBPM > 1 && targetBpm > 1) {
        float ratio = targetBpm / origBPM;
        float factor = 1;
        if (ratio > 1.66666f) {
            factor = 2;
        } else if (ratio < 0.83333f) {
            factor = 0.5;
        }
        player->setBpm(origBPM * factor);
        player->setTempo(ratio / factor, true);
    }
}

- (float)getCurrentFactor {
    if (player) {
        return player->tempo;
    } else {
        return 1.0f;
    }
}

- (float)getPosition {
    if (player) {
        return (float)(player->positionMs / 1000);
    } else {
        return 0.0f;
    }
}

- (void)setPosition:(double)newSeconds
{
    if (player) {
        player->setPosition(newSeconds * 1000, false, false);
    }
}

- (void)setVolume:(float)newVolume
{
    volume = newVolume;
}

- (void)setOrigBpm:(float)newBpm beatStartMs:(float)newBeatStartMs;
{
    origBPM = newBpm;
    if (player) {
        player->setBpm(newBpm);
        player->setFirstBeatMs(newBeatStartMs);
    }
}

- (double)getMsToNextBeat
{
    if (player && player->playing) {
        //return player->msElapsedSinceLastBeat;
        return (player->closestBeatMs(player->positionMs, NULL) - player->positionMs) / player->tempo;
    } else {
        return -1;
    }
}
- (void)interruptionStarted {}
- (void)interruptionEnded {
    player->onMediaserverInterrupt();
}

@end
