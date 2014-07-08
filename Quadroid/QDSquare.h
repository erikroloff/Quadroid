//
//  QDSquare.h
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import <Foundation/Foundation.h>

@import SpriteKit;

static const NSUInteger NumsquareTypes = 5;

@interface QDSquare : NSObject

@property (assign, nonatomic) NSInteger column;
@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSUInteger squareType;
@property (strong, nonatomic) SKSpriteNode *sprite;

- (NSString *)spriteName;
- (NSString *)highlightedSpriteName;


@end
