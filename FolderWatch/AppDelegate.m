//
//  AppDelegate.m
//  FolderWatch
//
//  Created by Stephen Lynn on 11/1/11.
//  Copyright (c) 2011 Stephen Lynn. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window, folderWatcherArray, splitView;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSLog(@"Starting the watcher");
    
    splitView.delegate = self;
    [splitView setPosition:665 ofDividerAtIndex:0];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithObjects:nil];
    [self setFolderWatcherArray:tempArray];
    
    //Restore settings from disk
    NSError *error = nil;
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription 
                                   entityForName:@"Watcher" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        FolderWatcher *w = [self addNewWatch];
        w.watchPath = [info valueForKey:@"watchPath"];
        w.watchScript = [info valueForKey:@"watchScript"];
        NSLog(@"Restored path: %@", w.watchPath);
    }   
    
    if(folderWatcherArray.count == 0) {//add an empty watch if none restored from disk
        [self addNewWatch];
    }
}

- (void)addLogMessage:(NSNotification *)notification {
    FolderWatcher *watcher = [notification object];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%H:%M:%S" allowNaturalLanguage:NO];
    NSDate *date = [NSDate date];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    
    [logTextView insertText:[NSString stringWithFormat:@"%@ : %@\n", formattedDateString, watcher.logMessage]];
}

- (void)watchButtonPressed:(id)aWatcher {
    FolderWatcher *watcher = (FolderWatcher *)aWatcher;
    watcher.watching ? [watcher stopWatching] : [watcher startWatching];
    watcher.buttonTitle = watcher.watching ? @"Stop Watching" : @"Start Watching";
    [self saveAction:nil];
}

- (void)deleteButtonPressed:(id)aWatcher {
    if(folderWatcherArray.count > 1) {
        FolderWatcher *watcher = (FolderWatcher *)aWatcher;
        if (watcher.watching) {
            [watcher stopWatching];
        }
        
        [self removeObjectFromFolderWatcherArrayAtIndex:[folderWatcherArray indexOfObject:watcher]];
        [self saveAction:nil];
    }
}

- (FolderWatcher *) addNewWatch {
    FolderWatcher *f = [[FolderWatcher alloc] init];
    f.watchPath = @"";
    f.watchScript = @"";
    f.buttonTitle = @"Start Watching";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addLogMessage:) name:@"logMessage" object:f];
    
    [self insertObject:f inFolderWatcherArrayAtIndex:[folderWatcherArray count]];
    
    return f;
}

- (IBAction)addWatchButtonPressed:(id)sender {
    [self addNewWatch];
}

/**
 Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    //Delete any existing records on disk
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription 
                                   entityForName:@"Watcher" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }   
    
    for (int i=0; i<folderWatcherArray.count; ++i) {
        FolderWatcher *w = [folderWatcherArray objectAtIndex:i];
        NSManagedObject *watcher = [NSEntityDescription
                                    insertNewObjectForEntityForName:@"Watcher" 
                                    inManagedObjectContext:context];
        [watcher setValue:w.watchPath forKey:@"watchPath"];
        [watcher setValue:w.watchScript forKey:@"watchScript"];
    }
    
    NSLog(@"Called saveAction");
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

-(void)insertObject:(FolderWatcher *)fw inFolderWatcherArrayAtIndex:(NSUInteger)index {
    [folderWatcherArray insertObject:fw atIndex:index];
}

-(void)removeObjectFromFolderWatcherArrayAtIndex:(NSUInteger)index {
    [folderWatcherArray removeObjectAtIndex:index];
}

-(CGFloat)splitView:splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    return 665;
}

-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize
{
    CGFloat dividerThickness = [sender dividerThickness];
    NSRect leftRect = [[[sender subviews] objectAtIndex:0] frame];
    NSRect rightRect = [[[sender subviews] objectAtIndex:1] frame];
    NSRect newFrame = [sender frame];
    
	leftRect.size.height = newFrame.size.height;
	leftRect.origin = NSMakePoint(0, 0);
	rightRect.size.width = newFrame.size.width - leftRect.size.width
	- dividerThickness;
	rightRect.size.height = newFrame.size.height;
	rightRect.origin.x = leftRect.size.width + dividerThickness;
    
    
	[[[sender subviews] objectAtIndex:0] setFrame:leftRect];
	[[[sender subviews] objectAtIndex:1] setFrame:rightRect];
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "FolderWatch" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"FolderWatch"];
}

/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FolderWatch" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"FolderWatch.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;

    return __persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
