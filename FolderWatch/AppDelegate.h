//
//  AppDelegate.h
//  FolderWatch
//
//  Created by Stephen Lynn on 11/1/11.
//  Copyright (c) 2011 Stephen Lynn. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FolderWatcher.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate> {
    IBOutlet NSTextView *logTextView;
    NSMutableArray *folderWatcherArray;
}

@property (weak) IBOutlet NSSplitView *splitView;
@property (strong) NSMutableArray *folderWatcherArray;
@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)addWatchButtonPressed:(id)sender;
- (FolderWatcher *)addNewWatch;
- (void)addLogMessage:(NSNotification *)notification;
- (void)watchButtonPressed:(id)aWatcher;
- (void)deleteButtonPressed:(id)aWatcher;
- (void)insertObject:(FolderWatcher *)fw inFolderWatcherArrayAtIndex:(NSUInteger)index;
- (void)removeObjectFromFolderWatcherArrayAtIndex:(NSUInteger)index;
- (IBAction)saveAction:(id)sender;

@end
