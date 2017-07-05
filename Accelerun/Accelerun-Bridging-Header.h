// Bridging header!!

#import <Foundation/Foundation.h>

@interface BPMDetector : NSObject

- (void)calc:(NSURL *)fileURL;
- (float)getBpm;
- (float)getBeatStartMs;
- (float)getPeakDb;

@end

@interface AdvPlayer : NSObject

- (void)play:(NSURL *)fileURL;
- (void)setTargetBpm:(float)targetBPM;
- (float)getCurrentFactor;
- (float)getPosition;
- (void)setPosition:(double)newSeconds;
- (void)setVolume:(float)newVolume;
- (void)setOrigBpm:(float)newBpm beatStartMs:(float)newBeatStartMs;
- (double)getMsToNextBeat;
- (void)resume;
- (void)pause;

@end
