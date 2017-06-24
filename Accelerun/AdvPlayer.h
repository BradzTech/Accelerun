//
//  AdvPlayer.hpp
//  Accelerun
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdvPlayer : NSObject
- (void)play:(NSURL *)fileURL;
- (void)setTempo:(float)tempo;
- (void)setVolume:(float)newVolume;
- (void)setBpm:(float)newBpm beatStartMs:(float)newBeatStartMs;
- (double)getMsToNextBeat;
- (void)resume;
- (void)pause;
@end
