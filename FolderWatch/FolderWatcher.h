//
//  FolderWatcher.h
//  FileSync
//
//  Created by Stephen Lynn on 10/4/11.
//  Copyright 2011 Stephen Lynn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

@interface FolderWatcher : NSObject {
    FSEventStreamRef stream;
    BOOL _watching;
}

@property BOOL watching;
@property (strong) NSString *buttonTitle;
@property (strong) NSString *watchPath;
@property (strong) NSString *watchScript;
@property (strong) NSString *logMessage;

void fileChangedCB(ConstFSEventStreamRef streamRef, void* pClientCallBackInfo, size_t numEvents, void* pEventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);
- (void) addLogMessage:(NSString *)newLogMessage;
- (void) startWatching;
- (void) stopWatching;

@end
