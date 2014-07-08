//
//  QDViewController.m
//  Quadroid
//
//  Created by Erik Roloff on 7/4/14.
//  Copyright (c) 2014 Erik Roloff. All rights reserved.
//

@import AVFoundation;

#import "QDViewController.h"
#import "QDMyScene.h"
#import "QDLevel.h"

@interface QDViewController ()

@property (strong, nonatomic) QDLevel *level;
@property (strong, nonatomic) QDMyScene *scene;
@property (assign, nonatomic) NSUInteger movesLeft;
@property (assign, nonatomic) NSUInteger score;

@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

@property (strong, nonatomic) AVAudioPlayer *backgroundMusic;

@end

@implementation QDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure the view.
    SKView *skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    
    self.gameOverPanel.hidden = YES;
    
    // Create and configure the scene.
    self.scene = [QDMyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Load the level.
    self.level = [[QDLevel alloc] initWithFile:@"Level_0"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    id block = ^(QDSwap *swap) {
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
    };
    
    self.scene.swipeHandler = block;
    
    // Present the scene.
    [skView presentScene:self.scene];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"God Gave Me a Personal Tour of The Universe" withExtension:@"m4a"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    [self.backgroundMusic play];
    
    // Let's start the game!
    [self beginGame];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)beginGame {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    
    [self.level resetComboMultiplier];
    
    [self.scene animateBeginGame];
    [self shuffle];
}

- (void)shuffle {
    [self.scene removeAllSquareSprites];
    NSSet *newSquares = [self.level shuffle];
    [self.scene addSpritesForSquares:newSquares];
}

- (void)handleMatches {
    NSSet *chains = [self.level removeMatches];
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    [self.scene animateMatchedSquares:chains completion:^{
        for (QDChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingSquares:columns completion:^{
            NSArray *columns = [self.level topUpSquares];
            [self.scene animateNewSquares:columns completion:^{
                [self handleMatches];
            }];
        }];
    }];
}

- (void)beginNextTurn {
    [self.level resetComboMultiplier];
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
    [self decrementMoves];
}

- (void)updateLabels {
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
}

- (void)decrementMoves{
    self.movesLeft--;
    [self updateLabels];
    
    if (self.score >= self.level.targetScore) {
        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
        [self showGameOver];
    } else if (self.movesLeft == 0) {
        self.gameOverPanel.image = [UIImage imageNamed:@"GameOver"];
        [self showGameOver];
    }
}

- (void)showGameOver {
    [self.scene animateGameOver];
    self.gameOverPanel.hidden = NO;
    self.scene.userInteractionEnabled = NO;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    self.shuffleButton.hidden = YES;
}

- (void)hideGameOver {
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    
    [self beginGame];
    self.shuffleButton.hidden = NO;
}

- (IBAction)shuffleButtonPressed:(id)sender {
    [self shuffle];
    [self decrementMoves];
}

@end
