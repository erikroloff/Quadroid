//
//  QDLevel.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

#import "QDLevel.h"

@interface QDLevel ()

@property (strong, nonatomic) NSSet *possibleSwaps;
@property (assign, nonatomic) NSUInteger comboMultiplier;

@end

@implementation QDLevel {
    QDSquare *_squares[NumColumns][NumRows];
    QDTile *_tiles[NumColumns][NumRows];
}

- (QDSquare *)squareAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _squares[column][row];
}

- (NSSet *)shuffle {
    NSSet *set;
    do {
        set = [self createInitialsquares];
        
        [self detectPossibleSwaps];
        
        NSLog(@"possible swaps: %@", self.possibleSwaps);
    }
    while ([self.possibleSwaps count] == 0);
    
    return set;
}

- (NSSet *)createInitialsquares {
    NSMutableSet *set = [NSMutableSet set];
    
    // 1
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            if (_tiles[column][row] != nil) {
                
                // 2
                NSUInteger squareType;
                do {
                    squareType = arc4random_uniform(NumsquareTypes) + 1;
                }
                while ((column >= 2 &&
                        _squares[column - 1][row].squareType == squareType &&
                        _squares[column - 2][row].squareType == squareType)
                       ||
                       (row >= 2 &&
                        _squares[column][row - 1].squareType == squareType &&
                        _squares[column][row - 2].squareType == squareType));
                
                // 3
                QDSquare *square = [self createsquareAtColumn:column row:row withType:squareType];
                
                // 4
                [set addObject:square];
            }
        }
    }
    return set;
}

- (QDSquare *)createsquareAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)squareType {
    QDSquare *square = [[QDSquare alloc] init];
    square.squareType = squareType;
    square.column = column;
    square.row = row;
    _squares[column][row] = square;
    return square;
}

- (NSDictionary *)loadJSON:(NSString *)filename {
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find level file: %@", filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not load level file: %@, error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Level file '%@' is not valid JSON: %@", filename, error);
        return nil;
    }
    
    return dictionary;
}

- (instancetype)initWithFile:(NSString *)filename {
    self = [super init];
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:filename];
        
        // Loop through the rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop) {
            
            // Loop through the columns in the current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                // Note: In Sprite Kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object.
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[QDTile alloc] init];
                }
            }];
        }];
        
        self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
    }
    return self;
}

- (QDTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1(column >= 0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >= 0 && row < NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

- (void)performSwap:(QDSwap *)swap {
    NSInteger columnA = swap.squareA.column;
    NSInteger rowA = swap.squareA.row;
    NSInteger columnB = swap.squareB.column;
    NSInteger rowB = swap.squareB.row;
    
    _squares[columnA][rowA] = swap.squareB;
    swap.squareB.column = columnA;
    swap.squareB.row = rowA;
    
    _squares[columnB][rowB] = swap.squareA;
    swap.squareA.column = columnB;
    swap.squareA.row = rowB;
}

- (BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSUInteger squareType = _squares[column][row].squareType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column - 1; i >= 0 && _squares[i][row].squareType == squareType; i--, horzLength++) ;
    for (NSInteger i = column + 1; i < NumColumns && _squares[i][row].squareType == squareType; i++, horzLength++) ;
    if (horzLength >= 3) return YES;
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1; i >= 0 && _squares[column][i].squareType == squareType; i--, vertLength++) ;
    for (NSInteger i = row + 1; i < NumRows && _squares[column][i].squareType == squareType; i++, vertLength++) ;
    return (vertLength >= 3);
}

- (void)detectPossibleSwaps {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            QDSquare *square = _squares[column][row];
            if (square != nil) {
                
                // Is it possible to swap this square with the one on the right?
                if (column < NumColumns - 1) {
                    // Have a square in this spot? If there is no tile, there is no square.
                    QDSquare *other = _squares[column + 1][row];
                    if (other != nil) {
                        // Swap them
                        _squares[column][row] = other;
                        _squares[column + 1][row] = square;
                        
                        // Is either square now part of a chain?
                        if ([self hasChainAtColumn:column + 1 row:row] ||
                            [self hasChainAtColumn:column row:row]) {
                            
                            QDSwap *swap = [[QDSwap alloc] init];
                            swap.squareA = square;
                            swap.squareB = other;
                            [set addObject:swap];
                        }
                        
                        // Swap them back
                        _squares[column][row] = square;
                        _squares[column + 1][row] = other;
                    }
                }
                
                if (row < NumRows - 1) {
                    
                    QDSquare *other = _squares[column][row + 1];
                    if (other != nil) {
                        // Swap them
                        _squares[column][row] = other;
                        _squares[column][row + 1] = square;
                        
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            
                            QDSwap *swap = [[QDSwap alloc] init];
                            swap.squareA = square;
                            swap.squareB = other;
                            [set addObject:swap];
                        }
                        
                        _squares[column][row] = square;
                        _squares[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    self.possibleSwaps = set;
}

- (BOOL)isPossibleSwap:(QDSwap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

- (NSSet *)detectHorizontalMatches {
    // 1
    NSMutableSet *set = [NSMutableSet set];
    
    // 2
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            
            // 3
            if (_squares[column][row] != nil) {
                NSUInteger matchType = _squares[column][row].squareType;
                
                // 4
                if (_squares[column + 1][row].squareType == matchType
                    && _squares[column + 2][row].squareType == matchType) {
                    // 5
                    QDChain *chain = [[QDChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addSquare:_squares[column][row]];
                        column += 1;
                    }
                    while (column < NumColumns && _squares[column][row].squareType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            // 6
            column += 1;
        }
    }
    return set;
}

- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_squares[column][row] != nil) {
                NSUInteger matchType = _squares[column][row].squareType;
                
                if (_squares[column][row + 1].squareType == matchType
                    && _squares[column][row + 2].squareType == matchType) {
                    
                    QDChain *chain = [[QDChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addSquare:_squares[column][row]];
                        row += 1;
                    }
                    while (row < NumRows && _squares[column][row].squareType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    return set;
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    [self removesquares:horizontalChains];
    [self removesquares:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (void)removesquares:(NSSet *)chains {
    for (QDChain *chain in chains) {
        for (QDSquare *square in chain.squares) {
            _squares[square.column][square.row] = nil;
        }
    }
}

- (NSArray *)fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    // 1
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++) {
            
            // 2
            if (_tiles[column][row] != nil && _squares[column][row] == nil) {
                
                // 3
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    QDSquare *square = _squares[column][lookup];
                    if (square != nil) {
                        // 4
                        _squares[column][lookup] = nil;
                        _squares[column][row] = square;
                        square.row = row;
                        
                        // 5
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:square];
                        
                        // 6
                        break;
                    }
                }
            }
        }
    }
    return columns;
}

- (NSArray *)topUpSquares {
    NSMutableArray *columns = [NSMutableArray array];
    
    NSUInteger squareType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        NSMutableArray *array;
        
        // 1
        for (NSInteger row = NumRows - 1; row >= 0 && _squares[column][row] == nil; row--) {
            
            // 2
            if (_tiles[column][row] != nil) {
                
                // 3
                NSUInteger newsquareType;
                do {
                    newsquareType = arc4random_uniform(NumsquareTypes) + 1;
                } while (newsquareType == squareType);
                squareType = newsquareType;
                
                // 4
                QDSquare *square = [self createsquareAtColumn:column row:row withType:squareType];
                
                // 5
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:square];
            }
        }
    }
    return columns;
}

- (void)calculateScores:(NSSet *)chains {
    for (QDChain *chain in chains) {
        chain.score = 60 * ([chain.squares count] - 2) * self.comboMultiplier;
        self.comboMultiplier++;
    }
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}

@end