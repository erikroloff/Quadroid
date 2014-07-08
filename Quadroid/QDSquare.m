//
//  QDSquare.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import "QDSquare.h"

@implementation QDSquare

- (NSString *)spriteName {
    static NSString * const spriteNames[] = {
        @"redSquare",
        @"blueSquare",
        @"yellowSquare",
        @"greenSquare",
        @"purpleSquare",
    };
    
    return spriteNames[self.squareType - 1];
}

- (NSString *)highlightedSpriteName {
    static NSString * const highlightedSpriteNames[] = {
        @"redSquare-highlighted",
        @"blueSquare-highlighted",
        @"yellowSquare-highlighted",
        @"greenSquare-highlighted",
        @"purpleSquare-highlighted",
    };
    
    return highlightedSpriteNames[self.squareType - 1];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld square:(%ld,%ld)", (long)self.squareType,
            (long)self.column, (long)self.row];
}

@end
