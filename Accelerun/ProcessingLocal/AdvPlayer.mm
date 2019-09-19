//
//  AdvPlayer.cpp
//  Accelerun
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

#import "AdvPlayer.h"
#include "Superpowered.h"
#include "SuperpoweredSimple.h"
#include "SuperpoweredAdvancedAudioPlayer.h"
#include "SuperpoweredIOSAudioIO.h"
#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import <CoreData/CoreData.h>
#import <MediaPlayer/MediaPlayer.h>
#import <WebKit/WebKit.h>
#import "Accelerun-Swift.h"

@implementation AdvPlayer {
    Superpowered::AdvancedAudioPlayer *player;
    SuperpoweredIOSAudioIO *output;
    float *stereoBuffer;
    float volume;
    float origBPM;
    unsigned int lastSamplerate;
}

static bool audioProcessing(void *clientData, float **inputBuffers, unsigned int inputChannels, float **outputBuffers, unsigned int outputChannels, unsigned int numberOfSamples, unsigned int samplerate, unsigned long long hostTime) {
    __unsafe_unretained AdvPlayer *self = (__bridge AdvPlayer *)clientData;
    if (samplerate != self->lastSamplerate) {
        self->lastSamplerate = samplerate;
        self->player->outputSamplerate = samplerate;
    };
    //uint64_t startTime = mach_absolute_time();
    if (self->volume == 0.0f)
        self->volume = 1.0f;
    bool silence = !self->player->processStereo(self->stereoBuffer, false, numberOfSamples, self->volume);
    
    //self->playing = self->player->playing;
    if (!silence) Superpowered::DeInterleave(self->stereoBuffer, inputBuffers[0], inputBuffers[1], numberOfSamples); // The stereoBuffer is ready now, let's put the finished audio into the requested buffers.
    return !silence;
}

- (void)play:(NSURL *)fileURL
{
    if (posix_memalign((void **)&stereoBuffer, 16, 4096 + 128) != 0) abort();
    if (!player) {
        player = new Superpowered::AdvancedAudioPlayer(44100, 0);
        player->fixDoubleOrHalfBPM = true;
    }
    player->open([[fileURL absoluteString] UTF8String]);
    player->playbackRate = 1.0f;
    player->play();
    
    if (!output) {
        output = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredSamplerate:44100 audioSessionCategory:AVAudioSessionCategoryPlayback channels:2 audioProcessingCallback:audioProcessing clientdata:(__bridge void *)self];
        [output start];
    }
}

- (void)resume {
    if (player) {
        player->play();
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

- (void)setRatio:(float)ratio
{
    if (player && origBPM > 1 && ratio > 0) {
        player->originalBPM = origBPM;
        player->playbackRate = ratio;
    }
}

- (float)getCurrentFactor {
    if (player) {
        return player->playbackRate;
    } else {
        return 1.0f;
    }
}

- (float)getPosition {
    if (player) {
        return (float)(player->getPositionMs() / 1000);
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
        player->originalBPM = newBpm;
        player->firstBeatMs = newBeatStartMs;
    }
}

- (double)getMsToNextBeat
{
    if (player && player->isPlaying()) {
        //return player->msElapsedSinceLastBeat;
        return (player->closestBeatMs(player->getPositionMs(), NULL) - player->getPositionMs()) / player->playbackRate;
    } else {
        return -1;
    }
}
- (void)interruptionStarted {}
- (void)interruptionEnded {
    player->onMediaserverInterrupt();
}

@end
