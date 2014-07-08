//
//  QDSwap.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import "QDSwap.h"
#import "QDSquare.h"

@implementation QDSwap

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.squareA, self.squareB];
}

- (BOOL)isEqual:(id)object {
    // You can only compare this object against other QDSwap objects.
    if (![object isKindOfClass:[QDSwap class]]) return NO;
    
    // Two swaps are equal if they contain the same square, but it doesn't
    // matter whether they're called A in one and B in the other.
    QDSwap *other = (QDSwap *)object;
    return (other.squareA == self.squareA && other.squareB == self.squareB) ||
    (other.squareB == self.squareA && other.squareA == self.squareB);
}

- (NSUInteger)hash {
    return [self.squareA hash] ^ [self.squareB hash];
}

@end
