//
//  QDChain.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import "QDChain.h"

@implementation QDChain {
    NSMutableArray *_squares;
}

- (void)addSquare:(QDSquare *)square {
    if (_squares == nil) {
        _squares = [NSMutableArray array];
    }
    [_squares addObject:square];
}

- (NSArray *)squares {
    return _squares;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld squares:%@", (long)self.chainType, self.squares];
}


@end
