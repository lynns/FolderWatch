//
//  FolderWatcher.m
//  FileSync
//
//  Created by Stephen Lynn on 10/4/11.
//  Copyright 2011 Stephen Lynn. All rights reserved.
//

#import "FolderWatcher.h"

#define FOLDER_SCAN_INTERVAL 2.0

@implementation FolderWatcher

@synthesize watchPath, watchScript, logMessage, buttonTitle;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.watching = NO;
    }
    
    return self;
}

- (void)setWatching:(BOOL)isW {
    _watching = isW;
}

- (BOOL)watching {
    return _watching;
}

void fileChangedCB(ConstFSEventStreamRef streamRef, void* userData, size_t numEvents, void* pEventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
    FolderWatcher *watcher = (__bridge FolderWatcher *)userData;
    for (int i = 0; i < numEvents; i++) {         
        NSTask *task = [NSTask new];
        [task setLaunchPath:watcher.watchScript];
        //[task setArguments:[NSArray arrayWithObjects:@"-l", @"-a", @"-t", nil]];
        
        NSPipe *pipe = [NSPipe pipe];
        [task setCurrentDirectoryPath:[watcher.watchScript stringByDeletingLastPathComponent]];
        [task setStandardOutput:pipe];
        [task setStandardInput:[NSPipe pipe]];
        
        [task launch];
        
        NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
        
        [task waitUntilExit];
        
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [watcher addLogMessage:string];
    }
}

- (void) setupStream {
    if(stream != nil) {
        NSLog(@"Dropping watch on old path");
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        stream = nil;
    }
    if(stream == nil) {
        CFStringRef thePath = (__bridge CFStringRef)watchPath;
        CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&thePath, 1, NULL);
        
        CFAbsoluteTime latency = FOLDER_SCAN_INTERVAL; /* Latency in seconds */
        
        void *appPointer = (__bridge void *)self;
        FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
        
        /* Create the stream, passing in a callback */
        stream = FSEventStreamCreate(NULL,
                                     &fileChangedCB,
                                     &context,
                                     pathsToWatch,
                                     kFSEventStreamEventIdSinceNow, /* Or a previous event ID */
                                     latency,
                                     kFSEventStreamCreateFlagNone /* Flags explained in reference */
                                     );

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void) addLogMessage:(NSString *)newLogMessage {
    self.logMessage = newLogMessage;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logMessage" object:self];
}

- (void) startWatching {
    NSLog(@"StartWatching: %@", watchPath);
    [self addLogMessage:[NSString stringWithFormat:@"StartWatching: %@", watchPath]];
    [self setupStream];
    if(stream != nil) {
        FSEventStreamStart(stream);
        self.watching = YES;
        [self addLogMessage:@"Folder watch started"];
    }
}

- (void) stopWatching {
    if(stream != nil) {
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        stream = nil;
    }
    [self addLogMessage:@"Folder watch stopped"];
    self.watching = NO;
}
@end
