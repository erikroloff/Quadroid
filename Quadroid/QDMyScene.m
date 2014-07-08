//
//  QDMyScene.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import "QDMyScene.h"
#import "QDSquare.h"
#import "QDLevel.h"
#import "QDSwap.h"


static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface QDMyScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *squaresLayer;
@property (strong, nonatomic) SKNode *tilesLayer;
@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;
@property (strong, nonatomic) SKSpriteNode *selectionSprite;
@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invalidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingSquareSound;
@property (strong, nonatomic) SKAction *addSquareSound;
@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@end

@implementation QDMyScene

- (id)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        
        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        self.squaresLayer = [SKNode node];
        self.squaresLayer.position = layerPosition;
        
        [self.cropLayer addChild:self.squaresLayer];
        
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        self.selectionSprite = [SKSpriteNode node];
        
        [self preloadResources];
    }
    return self;
}

- (void)addSpritesForSquares:(NSSet *)squares {
    for (QDSquare *square in squares) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[square spriteName]];
        sprite.position = [self pointForColumn:square.column row:square.row];
        [self.squaresLayer addChild:sprite];
        square.sprite = sprite;
        
        square.sprite.alpha = 0;
        square.sprite.xScale = square.sprite.yScale = 0.5;
        
        [square.sprite runAction:[SKAction sequence:@[
                                                      [SKAction waitForDuration:0.25 withRange:0.5],
                                                      [SKAction group:@[
                                                                        [SKAction fadeInWithDuration:0.25],
                                                                        [SKAction scaleTo:1.0 duration:0.25]
                                                                        ]]]]];
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Is this a valid location within the squares layer? If yes,
    // calculate the corresponding row and column numbers.
    if (point.x >= 0 && point.x < NumColumns*TileWidth &&
        point.y >= 0 && point.y < NumRows*TileHeight) {
        
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
        
    } else {
        *column = NSNotFound;  // invalid location
        *row = NSNotFound;
        return NO;
    }
}

- (void)addTiles {
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaskTile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    for (NSInteger row = 0; row <= NumRows; row++) {
        for (NSInteger column = 0; column <= NumColumns; column++) {
            
            BOOL topLeft     = (column > 0) && (row < NumRows)
            && [self.level tileAtColumn:column - 1 row:row];
            
            BOOL bottomLeft  = (column > 0) && (row > 0)
            && [self.level tileAtColumn:column - 1 row:row - 1];
            
            BOOL topRight    = (column < NumColumns) && (row < NumRows)
            && [self.level tileAtColumn:column row:row];
            
            BOOL bottomRight = (column < NumColumns) && (row > 0)
            && [self.level tileAtColumn:column row:row - 1];
            
            // The tiles are named from 0 to 15, according to the bitmask that is
            // made by combining these four values.
            NSUInteger value = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
            // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
            if (value != 0 && value != 6 && value != 9) {
                NSString *name = [NSString stringWithFormat:@"Tile_%lu", (long)value];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:name];
                CGPoint point = [self pointForColumn:column row:row];
                point.x -= TileWidth/2;
                point.y -= TileHeight/2;
                tileNode.position = point;
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // 1
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.squaresLayer];
    
    // 2
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // 3
        QDSquare *square = [self.level squareAtColumn:column row:row];
        if (square != nil) {
            
            // 4
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
            
            [self showSelectionIndicatorForSquare:square];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // 1
    if (self.swipeFromColumn == NSNotFound) return;
    
    // 2
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.squaresLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // 3
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {          // swipe left
            horzDelta = -1;
        } else if (column > self.swipeFromColumn) {   // swipe right
            horzDelta = 1;
        } else if (row < self.swipeFromRow) {         // swipe down
            vertDelta = -1;
        } else if (row > self.swipeFromRow) {         // swipe up
            vertDelta = 1;
        }
        
        // 4
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            
            [self hideSelectionIndicator];
            
            // 5
            self.swipeFromColumn = NSNotFound;
        }
    }
}

- (void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta {
    // 1
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    // 2
    if (toColumn < 0 || toColumn >= NumColumns) return;
    if (toRow < 0 || toRow >= NumRows) return;
    
    // 3
    QDSquare *toSquare = [self.level squareAtColumn:toColumn row:toRow];
    if (toSquare == nil) return;
    
    // 4
    QDSquare *fromSquare = [self.level squareAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    if (self.swipeHandler != nil) {
        QDSwap *swap = [[QDSwap alloc] init];
        swap.squareA = fromSquare;
        swap.squareB = toSquare;
        
        self.swipeHandler(swap);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectionIndicator];
    }
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)animateSwap:(QDSwap *)swap completion:(dispatch_block_t)completion {
    // Put the square you started with on top.
    swap.squareA.sprite.zPosition = 100;
    swap.squareB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.squareB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.squareA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.squareA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.squareB.sprite runAction:moveB];
    [self runAction:self.swapSound];
}

- (void)showSelectionIndicatorForSquare:(QDSquare *)square {
    // If the selection indicator is still visible, then first remove it.
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[square highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [square.sprite addChild:self.selectionSprite];
    self.selectionSprite.alpha = 1.0;
}

- (void)hideSelectionIndicator {
    [self.selectionSprite runAction:[SKAction sequence:@[
                                                         [SKAction fadeOutWithDuration:0.3],
                                                         [SKAction removeFromParent]]]];
}

- (void)animateInvalidSwap:(QDSwap *)swap completion:(dispatch_block_t)completion {
    swap.squareA.sprite.zPosition = 100;
    swap.squareB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.squareB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.squareA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.squareA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.squareB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
    
    [self runAction:self.invalidSwapSound];
}

- (void)preloadResources {
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingSquareSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addSquareSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

- (void)animateMatchedSquares:(NSSet *)chains completion:(dispatch_block_t)completion {
    
    for (QDChain *chain in chains) {
        
        [self animateScoreForChain:chain];
        
        for (QDSquare *square in chain.squares) {
            
            // 1
            if (square.sprite != nil) {
                
                // 2
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [square.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                // 3
                square.sprite = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    // 4
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateFallingSquares:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(QDSquare *square, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:square.column row:square.row];
            
            // 2
            NSTimeInterval delay = 0.05 + 0.15*idx;
            
            // 3
            NSTimeInterval duration = ((square.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            // 4
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 5
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [square.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[moveAction, self.fallingSquareSound]]]]];
        }];
    }
    
    // 6
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateNewSquares:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        
        // 2
        NSInteger startRow = ((QDSquare *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(QDSquare *square, NSUInteger idx, BOOL *stop) {
            
            // 3
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[square spriteName]];
            sprite.position = [self pointForColumn:square.column row:startRow];
            [self.squaresLayer addChild:sprite];
            square.sprite = sprite;
            
            // 4
            NSTimeInterval delay = 0.1 + 0.2*([array count] - idx - 1);
            
            // 5
            NSTimeInterval duration = (startRow - square.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 6
            CGPoint newPosition = [self pointForColumn:square.column row:square.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            square.sprite.alpha = 0;
            [square.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[
                                                                            [SKAction fadeInWithDuration:0.05], moveAction, self.addSquareSound]]]]];
        }];
    }
    
    // 7
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateScoreForChain:(QDChain *)chain {
    // Figure out what the midpoint of the chain is.
    QDSquare *firstSquare = [chain.squares firstObject];
    QDSquare *lastSquare = [chain.squares lastObject];
    CGPoint centerPosition = CGPointMake(
                                         (firstSquare.sprite.position.x + lastSquare.sprite.position.x)/2,
                                         (firstSquare.sprite.position.y + lastSquare.sprite.position.y)/2 - 8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.squaresLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                               moveAction,
                                               [SKAction removeFromParent]
                                               ]]];
}

- (void)animateGameOver {
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBeginGame {
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

- (void)removeAllSquareSprites {
    [self.squaresLayer removeAllChildren];
}

@end
