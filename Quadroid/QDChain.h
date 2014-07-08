//
//  QDChain.h
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QDSquare;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
};

@interface QDChain : NSObject

@property (strong, nonatomic, readonly) NSArray *squares;
@property (assign, nonatomic) ChainType chainType;
@property (assign, nonatomic) NSUInteger score;

- (void)addSquare:(QDSquare *)square;

@end