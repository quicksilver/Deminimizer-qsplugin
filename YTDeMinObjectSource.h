//
//  YTDeMinObjectSource.h
//  YTDeMinPlugIn
//
//  Created by ytrewq1 on 2006/08/10.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

@interface YTDeMinObjectSource : QSObjectSource {

}

- (QSObject*)minWinObjectWithMinWin:(id)minWin;
- (id)resolveProxyObject:(id)proxy;

@end
