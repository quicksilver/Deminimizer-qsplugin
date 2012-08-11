//
//  YTDeMinActionProvider.m
//  YTDeMinPlugIn
//
//  Created by ytrewq1 on 2006/07/19.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "YTDeMinActionProvider.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

#import "GetPID.h"

#import "YTDeMin.h"

@implementation YTDeMinActionProvider

- (BOOL)restoreMinimizedWindowWithIndeces:(NSArray*)indeces {
    BOOL result = YES;
    NSArray *minWins = YTDeMinMinimizedWindows();
    if (!minWins) {
        NSLog(@"Failed to obtain minimized windows");
        NSBeep();
        return NO;
    }
    int nMinWins = [minWins count];
    if (nMinWins == 0) {
        NSLog(@"No minimized windows detected");
        NSBeep();
        return NO;        
    }
    NSEnumerator *enumerator = [indeces objectEnumerator];
    NSString *indexStr;
    int index;
    while (indexStr = (NSString*)[enumerator nextObject]) {
        // XXX: figure out a better way to handle str->int conversion
        //      see doc of intValue for details (returns 0 for 'failure'...)
        index = [indexStr intValue];
        if (index >= 0) {
            if (index > (nMinWins - 1)) {
                NSLog(@"Error: index out of range: %d > %d", index, (nMinWins - 1));
                NSBeep();
                result = NO;
                continue;
            }
        } else {
            index = nMinWins + index;
            if (!((index >= 0) && (index < nMinWins))) {
                NSLog(@"Error: invalid index: %d", (index - nMinWins));
                NSBeep();
                result = NO;
                continue;
            }
        }
        if (!YTDeMinRestoreMinimizedWindow([minWins objectAtIndex:index])) {
            NSLog(@"Error: failed to restore minimized window at index: %d", index);
            NSBeep();
            result = NO;
            continue;                
        }
    }
    
    return result;
}

- (QSObject*)restoreFirstMinWindowAction {
    [self restoreMinimizedWindowWithIndeces:[NSArray arrayWithObject:(id)@"0"]];
    return nil;
}

- (QSObject*)restoreLastMinWindowAction {    
    [self restoreMinimizedWindowWithIndeces:[NSArray arrayWithObject:(id)@"-1"]];
    return nil;
}

- (BOOL)restoreMinimizedWindows {
    BOOL result = YES;
    NSArray *minWins = YTDeMinMinimizedWindows();
    if (!minWins) {
        NSLog(@"Failed to obtain minimized windows");
        NSBeep();
        return NO;
    }
    int nMinWins = [minWins count];
    if (nMinWins == 0) {
        NSLog(@"No minimized windows detected");
        NSBeep();
        return NO;        
    }
    id aMinWin;
    NSEnumerator *enumerator = [minWins objectEnumerator];
    while (aMinWin = [enumerator nextObject]) {
        if (!YTDeMinRestoreMinimizedWindow(aMinWin)) {
            NSLog(@"Error: failed to restore minimized window: %@", aMinWin);
            NSBeep();
            result = NO;
            continue;
        }
    }    
    return result;
}

- (QSObject*)restoreAllMinWindowsAction {
    [self restoreMinimizedWindows];
    return nil;
}

- (QSObject*)restoreMinimizedWindowWithIndex:(QSObject*)dObject {
    NSArray *indeces = [dObject arrayForType:QSTextType];
    if (!indeces) {
        NSLog(@"No index specified for: %@", dObject);
        NSBeep();
        return nil;
    }
    [self restoreMinimizedWindowWithIndeces:indeces];
    
    return nil;
}

- (QSObject*) restoreMinWin:(QSObject*)dObject
{
    NSArray *objs = [dObject arrayForType:@"YTDeMinWinType"];
    if (!objs) {
        NSLog(@"No minWins found for: %@", dObject);
        return nil;
    }    
    NSEnumerator *enumerator = [objs objectEnumerator];
    id aMinWin = nil;
    while (aMinWin = [enumerator nextObject]) {
        if (!YTDeMinRestoreMinimizedWindow(aMinWin)) {
            NSLog(@"Error: failed to restore: %@", aMinWin);
            continue;
        }
    }

    return nil;
}

- (QSObject*)minimizeWindows
{
    YTDeMinMinimizeWindows();
    return nil;
}

- (QSObject*)minimizeWindowsForApp:(QSObject*)dObject
{
    NSArray *aObjs = [dObject arrayForType:QSProcessType];
    if (!aObjs) {
        NSLog(@"No apps found for: %@", dObject);
        return nil;
    }
    NSEnumerator *enumerator = [aObjs objectEnumerator];
    NSDictionary *app = nil;
    NSString *bundleId = nil;
    while (app = (NSDictionary*)[enumerator nextObject]) {
        bundleId = [app objectForKey:@"NSApplicationBundleIdentifier"];
        if (!YTDeMinMinimizeWindowsForAppWithBundleId(bundleId)) {
            NSLog(@"Error: failed to minimize windows for: %@", bundleId);
            continue;
        }
    }

    return nil;
}

- (QSObject*)restoreWindowsForApp:(QSObject*)dObject
{
    NSArray *aObjs = [dObject arrayForType:QSProcessType];
    if (!aObjs) {
        NSLog(@"No apps found for: %@", dObject);
        return nil;
    }
    NSEnumerator *enumerator = [aObjs objectEnumerator];
    NSDictionary *app = nil;
    NSString *bundleId = nil;
    while (app = (NSDictionary*)[enumerator nextObject]) {
        bundleId = [app objectForKey:@"NSApplicationBundleIdentifier"];
        if (!YTDeMinRestoreWindowsForAppWithBundleId(bundleId)) {
            NSLog(@"Error: failed to restore windows for: %@", bundleId);
            continue;
        }
    }
    
    return nil;
}

@end
