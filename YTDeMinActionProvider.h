//
//  YTDeMinActionProvider.h
//  YTDeMinPlugIn
//
//  Created by ytrewq1 on 2006/07/19.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

@interface YTDeMinActionProvider : QSActionProvider {

}

- (BOOL)restoreMinimizedWindowWithIndeces:(NSArray*)indeces;
- (QSObject*)restoreFirstMinWindowAction;
- (QSObject*)restoreLastMinWindowAction;
- (BOOL)restoreMinimizedWindows;
- (QSObject*)restoreAllMinWindowsAction;
- (QSObject*)restoreMinimizedWindowWithIndex:(QSObject*)dObject;
- (QSObject*)restoreMinWin:(QSObject*)dObject;
- (QSObject*)minimizeWindows;
- (QSObject*)minimizeWindowsForApp:(QSObject*)dObject;
- (QSObject*)restoreWindowsForApp:(QSObject*)dObject;

@end
