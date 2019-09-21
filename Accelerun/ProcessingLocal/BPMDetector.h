//
//  BPMDetector.h
//  BPMDetect
//
//  Created by Yuki Konda on 1/29/16.
//  Modified by Bradley Klemick.
//

#import <Foundation/Foundation.h>

@interface BPMDetector : NSObject
- (void)calc:(NSURL *)fileURL;
- (float)getDurationSeconds;
- (float)getBpm;
- (float)getBeatStartMs;
- (float)getPeakDb;
@end
