//
//  QDLevel.h
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "QDSquare.h"
#import "QDTile.h"
#import "QDSwap.h"
#import "QDChain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface QDLevel : NSObject

@property (assign, nonatomic) NSUInteger targetScore;
@property (assign, nonatomic) NSUInteger maximumMoves;

- (NSSet *)shuffle;

- (QDSquare *)squareAtColumn:(NSInteger)column row:(NSInteger)row;

- (instancetype)initWithFile:(NSString *)filename;

- (QDTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row;

- (void)performSwap:(QDSwap *)swap;

- (BOOL)isPossibleSwap:(QDSwap *)swap;

- (NSSet *)removeMatches;

- (NSArray *)fillHoles;

- (NSArray *)topUpSquares;

- (void)detectPossibleSwaps;

- (void)resetComboMultiplier;

@end
