//
//  QDMyScene.h
//  Quadroid
//

//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@import SpriteKit;

@class QDLevel;
@class QDSwap;

@interface QDMyScene : SKScene

@property (strong, nonatomic) QDLevel *level;
@property (copy, nonatomic) void (^swipeHandler)(QDSwap *swap);

- (void)addSpritesForSquares:(NSSet *)squares;
- (void)addTiles;
- (void)animateSwap:(QDSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateInvalidSwap:(QDSwap *)swap completion:(dispatch_block_t)completion;
- (void)animateMatchedSquares:(NSSet *)chains completion:(dispatch_block_t)completion;
- (void)animateFallingSquares:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateNewSquares:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateGameOver;
- (void)animateBeginGame;
- (void)removeAllSquareSprites;

@end
