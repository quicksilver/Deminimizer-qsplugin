#import "YTDeMin.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

#import "GetPID.h"

// XXX: might turn out to be slow -- i suppose could eventually use some kind of observing to keep 
//      the list of minimized windows up-to-date...
NSArray* YTDeMinMinimizedWindows()
{
    if (!AXAPIEnabled()) {
        NSBeep();
        NSLog(@"Accessibilty is not enabled -- see Universal Access Pref Pane in System Preferences");
        return nil;
    }
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *la = [ws launchedApplications];
    NSEnumerator *appEnumerator = [la objectEnumerator];
    NSDictionary *app = nil;
    NSString *bundleId = nil;
    NSEnumerator *windowEnumerator = nil;
    NSArray *windows = nil;
    id window = nil;
    AXError ourError = 0;
    NSMutableArray *minWins = [NSMutableArray array];
    NSArray *names = nil;
    CFBooleanRef minimized;
    while (app = (NSDictionary*)[appEnumerator nextObject]) {
        bundleId = [app objectForKey:@"NSApplicationBundleIdentifier"];
        if (!bundleId) {
            NSLog(@"Failed to determine bundle id for: %@", app);
            continue;
        }
        windows = YTDeMinWindowsForAppWithBundleId(bundleId);
        if (!windows) {
            //NSLog(@"Info: no windows for app: %@", bundleId);
            continue;
        }
        windowEnumerator = [windows objectEnumerator];
        while (window = [windowEnumerator nextObject]) {
            // XXX: fn name has 'Copy', must release?
            ourError = AXUIElementCopyAttributeNames((AXUIElementRef)window, (CFArrayRef *)&names);
            if (ourError) {
                NSLog(@"Failed to determine attribute names for window: %@", window);
                continue;
            }
            if (![names containsObject:(NSString *)kAXMinimizedAttribute]) {
                //NSLog(@"No minimized attribute for window: %@", window);
                continue;
            }
            CFRelease(names);
            // XXX: fn name has 'Copy', must release?
            ourError = AXUIElementCopyAttributeValue((AXUIElementRef)window, kAXMinimizedAttribute, (CFTypeRef *)&minimized);
            if (!ourError && (minimized == kCFBooleanTrue)) {
                [minWins addObject:window];
            }
            CFRelease(minimized);
        }
    }
    
    return [NSArray arrayWithArray:minWins];
}

NSArray* YTDeMinWindowsForAppWithBundleId(NSString* bundleId)
{
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *la = [ws launchedApplications];
    NSEnumerator *appEnumerator = [la objectEnumerator];
    NSDictionary *app = nil;
    while (app = (NSDictionary*)[appEnumerator nextObject]) {
        if ([bundleId isEqual:[app objectForKey:@"NSApplicationBundleIdentifier"]]) {
            break;
        }
        app = nil;
    }
    if (!app) {
        NSLog(@"Error: not running: %@", bundleId);
        return nil;
    }
    int pid = [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
    // XXX: fn name has 'Create', must release
    AXUIElementRef appElementRef = AXUIElementCreateApplication((pid_t)pid);
    if (!appElementRef) {
        NSLog(@"Error: failed to obtain UIElement for app: %@", bundleId);
        return nil;
    }
    AXError ourError = 0;
    NSArray *windowList = nil;
    // XXX: fn name has 'Copy', must release?
    ourError = AXUIElementCopyAttributeValue(appElementRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
    CFRelease(appElementRef);
    if (ourError) {
        NSLog(@"Error: failed to obtain children attribute value for app: %@", bundleId);
        return nil;
    }
    //NSLog(@"%@'s window list: %@", bundleId, windowList);

    return [NSArray arrayWithArray:windowList];
}

BOOL YTDeMinRestoreMinimizedWindow(id minWin)
{
    AXError ourError = AXUIElementPerformAction((AXUIElementRef)minWin, (CFStringRef)@"AXRaise");
    if (ourError) {
        return NO;
    }
    return YES;
}

BOOL YTDeMinMinimizeWindowsForAppWithBundleId(NSString* bundleId)
{
    if (!AXAPIEnabled()) {
        NSBeep();
        NSLog(@"Accessibilty is not enabled -- see Universal Access Pref Pane in System Preferences");
        return NO;
    }
    NSArray *windows = YTDeMinWindowsForAppWithBundleId(bundleId);
    if (!windows) {
        NSLog(@"Error: no windows for app: %@", bundleId);
        return NO;
    }
    id window = nil;
    AXError ourError = 0;
    AXUIElementRef minButton = nil;
    NSEnumerator *windowEnumerator = [windows objectEnumerator];
    while (window = [windowEnumerator nextObject]) {
        // XXX: check for existence of attribute?
        ourError = AXUIElementCopyAttributeValue((AXUIElementRef)window, kAXMinimizeButtonAttribute, (CFTypeRef *)&minButton);
        // XXX: following CFRelease is wrong?
        //CFRelease(window);
        if (ourError) {
            //NSLog(@"Warning: no minimize button for: %@", window);
            continue;
        }
        // XXX: perhaps should check whether minimized first...
        AXUIElementPerformAction(minButton, (CFStringRef)@"AXPress");
        CFRelease(minButton);
    }
    
    return YES;    
}

BOOL YTDeMinRestoreWindowsForAppWithBundleId(NSString* bundleId)
{
    if (!AXAPIEnabled()) {
        NSBeep();
        NSLog(@"Accessibilty is not enabled -- see Universal Access Pref Pane in System Preferences");
        return NO;
    }
    NSArray *windows = YTDeMinWindowsForAppWithBundleId(bundleId);
    if (!windows) {
        NSLog(@"Error: no windows for app: %@", bundleId);
        return NO;
    }
    id window = nil;
    AXError ourError = 0;
    NSArray *names = nil;
    CFBooleanRef minimized;
    NSEnumerator *windowEnumerator = [windows objectEnumerator];
    while (window = [windowEnumerator nextObject]) {
        // XXX: fn name has 'Copy', must release?
        ourError = AXUIElementCopyAttributeNames((AXUIElementRef)window, (CFArrayRef *)&names);
        if (ourError) {
            NSLog(@"Failed to determine attribute names for window: %@", window);
            continue;
        }
        if (![names containsObject:(NSString *)kAXMinimizedAttribute]) {
            //NSLog(@"No minimized attribute for window: %@", window);
            continue;
        }
        CFRelease(names);
        // XXX: fn name has 'Copy', must release?
        ourError = AXUIElementCopyAttributeValue((AXUIElementRef)window, kAXMinimizedAttribute, (CFTypeRef *)&minimized);
        if (ourError) {
            NSLog(@"Failed to determine minimized state for window: %@", window);
            continue;
        }
        if (minimized == kCFBooleanTrue) {
            AXUIElementPerformAction((AXUIElementRef)window, (CFStringRef)@"AXRaise");            
        }
        CFRelease(minimized);
        // XXX: don't think the following is necessary -- if it is, will need another 
        //      CFRelease above the 'continue' above
        //CFRelease(window);
    }
    
    return YES;    
}

BOOL YTDeMinMinimizeWindows()
{
    if (!AXAPIEnabled()) {
        NSBeep();
        NSLog(@"Accessibilty is not enabled -- see Universal Access Pref Pane in System Preferences");
        return NO;
    }
    // XXX: icons for windows?
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *la = [ws launchedApplications];
    NSEnumerator *appEnumerator = [la objectEnumerator];
    NSDictionary *app = nil;
    NSString *bundleId;
    while (app = (NSDictionary*)[appEnumerator nextObject]) {
        bundleId = [app objectForKey:@"NSApplicationBundleIdentifier"];
        if (!YTDeMinMinimizeWindowsForAppWithBundleId(bundleId)) {
            NSLog(@"Error: failed to minimize windows for: %@", bundleId);
            continue;
        }
    }
    
    return YES;
}
