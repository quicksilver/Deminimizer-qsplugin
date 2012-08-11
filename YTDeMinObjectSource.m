//
//  YTDeMinObjectSource.m
//  YTDeMinPlugIn
//
//  Created by ytrewq1 on 2006/08/10.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "YTDeMinObjectSource.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

#import "YTDeMin.h"

@implementation YTDeMinObjectSource

- (QSObject*)minWinObjectWithMinWin:(id)minWin
{
    NSString *title = nil;
    // XXX: check for existence of title attribute?
    // XXX: fn name has 'Copy', must release?
    AXError ourError = AXUIElementCopyAttributeValue((AXUIElementRef)minWin, kAXTitleAttribute, (CFTypeRef *)&title);
    if (ourError) {
        NSLog(@"Error: failed to obtain title attribute value for window: %@", minWin);
        return nil;
    }
    NSString *objectTitle = [NSString stringWithString:title];
    CFRelease(title);
    QSObject *mObj = [QSObject objectWithName:objectTitle];
    if (!mObj) {
        NSLog(@"Error: failed to create QSObject from minWin: %@", minWin);
        return nil;
    }
    [mObj setPrimaryType:@"YTDeMinWinType"];
    [mObj setObject:minWin forType:@"YTDeMinWinType"];
    // XXX: this way of determining an icon is slower than doing it in resolveProxyObject:
    pid_t pid;
    ourError = AXUIElementGetPid((AXUIElementRef)minWin, &pid);
    if (ourError) {
        NSLog(@"Failed to determine app's pid for window: %@", minWin);
    }
    else {
        //NSLog(@"pid is: %d", pid);
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSArray *la = [ws launchedApplications];
        NSEnumerator *appEnumerator = [la objectEnumerator];
        NSDictionary *app = nil;
        NSNumber *aPid;
        NSString *appPath = nil;
        while (app = (NSDictionary*)[appEnumerator nextObject]) {
            aPid = [app objectForKey:@"NSApplicationProcessIdentifier"];
            //NSLog(@"a pid is: %@", aPid);
            // currently, pid_t -> int
            if ((int)pid == [aPid intValue]) {
                appPath = [app objectForKey:@"NSApplicationPath"];
                break;
            }
        }
        if (!appPath) {
            NSLog(@"Failed to determine path to app associated w/ window: %@", minWin);
        }
        else {
            NSImage *image = [ws iconForFile:appPath];
            if (!image) {
                NSLog(@"Failed to retrieve image for application at path: %@", appPath);
            }
            else {
                NSLog(@"setting image for %@ at %@", minWin, appPath);
                [mObj setIcon:image];
            }
        }
    }
    return mObj;
}

- (id)resolveProxyObject:(id)proxy
{
    /*   
    // XXX: icons for windows?
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *la = [ws launchedApplications];
    NSEnumerator *appEnumerator = [la objectEnumerator];
    NSDictionary *app = nil;
    while (app = (NSDictionary*)[appEnumerator nextObject]) {
        NSLog(@"%@", [app objectForKey:@"NSApplicationBundleIdentifier"]);
        NSLog(@"%@", [app objectForKey:@"NSApplicationProcessIdentifier"]);
    }
    */
    NSArray *minWins = YTDeMinMinimizedWindows();
    if (!minWins) {
        NSLog(@"Error: failed to obtain minimized windows");
        return nil;
    }
    //NSLog(@"minimized windows: %@", minWins);
    NSEnumerator *enumerator = [minWins objectEnumerator];
    NSMutableArray *minWinObjs = [NSMutableArray array];
    id aMinWin = nil;
    QSObject *aMinWinObj = nil;
    while (aMinWin = [enumerator nextObject]) {
        aMinWinObj = [self minWinObjectWithMinWin:aMinWin];
        if (!aMinWinObj) {
            NSLog(@"Error: failed to create QSObject from: %@", aMinWin);
            return nil;
        }
        [minWinObjs addObject:aMinWinObj];
    }
    QSObject *pObj = [QSObject objectByMergingObjects:minWinObjs];
    if (!pObj) {
        NSLog(@"Error: failed to create merged object from: %@", minWinObjs);
        return nil;
    }
    [pObj setChildren:minWinObjs];
    
    return pObj;
}

@end
