//
//  M2ViewController.m
//  m2048
//
//  Created by Danqing on 3/16/14.
//  Copyright (c) 2014 Danqing. All rights reserved.
//

#import "M2ViewController.h"
#import "M2SettingsViewController.h"
#import <VungleSDK/VungleSDK.h>

#import "M2Scene.h"
#import "M2GameManager.h"
#import "M2ScoreView.h"
#import "M2Overlay.h"
#import "M2GridView.h"

@implementation M2ViewController {
  IBOutlet UIButton *_restartButton;
  IBOutlet UIButton *_settingsButton;
  IBOutlet UILabel *_targetScore;
  IBOutlet UILabel *_subtitle;
  IBOutlet M2ScoreView *_scoreView;
  IBOutlet M2ScoreView *_bestView;
  
  M2Scene *_scene;
  
  IBOutlet M2Overlay *_overlay;
  IBOutlet UIImageView *_overlayBackground;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [self updateState];
  
  _bestView.score.text = [NSString stringWithFormat:@"%ld", (long)[Settings integerForKey:@"Best Score"]];
  
  _restartButton.layer.cornerRadius = [GSTATE cornerRadius];
  _restartButton.layer.masksToBounds = YES;
  
  _settingsButton.layer.cornerRadius = [GSTATE cornerRadius];
  _settingsButton.layer.masksToBounds = YES;
  
  _overlay.hidden = YES;
  _overlayBackground.hidden = YES;
  
  // Configure the view.
  SKView * skView = (SKView *)self.view;
  
  // Create and configure the scene.
  M2Scene * scene = [M2Scene sceneWithSize:skView.bounds.size];
  scene.scaleMode = SKSceneScaleModeAspectFill;
  
  // Present the scene.
  [skView presentScene:scene];
  [self updateScore:0];
  [scene startNewGame];
  
  _scene = scene;
  _scene.controller = self;
	
	[[VungleSDK sharedSDK] setDelegate:self];
}


- (void)viewDidAppear:(BOOL)animated {
	if ([self isSettingsUnlocked]) {
		[_settingsButton setTitle:@"Settings" forState:UIControlStateNormal];
		_settingsButton.alpha = 1.0;
	} else {
		[_settingsButton setTitle:@"Unlock?" forState:UIControlStateNormal];
		_settingsButton.alpha = 0.5;
	}
	
}

- (void)updateState
{
  [_scoreView updateAppearance];
  [_bestView updateAppearance];
  
  _restartButton.backgroundColor = [GSTATE buttonColor];
  _restartButton.titleLabel.font = [UIFont fontWithName:[GSTATE boldFontName] size:14];
	
  _settingsButton.backgroundColor = [GSTATE buttonColor];
  _settingsButton.titleLabel.font = [UIFont fontWithName:[GSTATE boldFontName] size:14];
  
  _targetScore.textColor = [GSTATE buttonColor];
  
  long target = [GSTATE valueForLevel:GSTATE.winningLevel];
  
  if (target > 100000) {
    _targetScore.font = [UIFont fontWithName:[GSTATE boldFontName] size:34];
  } else if (target < 10000) {
    _targetScore.font = [UIFont fontWithName:[GSTATE boldFontName] size:42];
  } else {
    _targetScore.font = [UIFont fontWithName:[GSTATE boldFontName] size:40];
  }
  
  _targetScore.text = [NSString stringWithFormat:@"%ld", target];
  
  _subtitle.textColor = [GSTATE buttonColor];
  _subtitle.font = [UIFont fontWithName:[GSTATE regularFontName] size:14];
  _subtitle.text = [NSString stringWithFormat:@"Join the numbers to get to %ld!", target];
  
  _overlay.message.font = [UIFont fontWithName:[GSTATE boldFontName] size:36];
  _overlay.keepPlaying.titleLabel.font = [UIFont fontWithName:[GSTATE boldFontName] size:17];
  _overlay.restartGame.titleLabel.font = [UIFont fontWithName:[GSTATE boldFontName] size:17];
  
  _overlay.message.textColor = [GSTATE buttonColor];
  [_overlay.keepPlaying setTitleColor:[GSTATE buttonColor] forState:UIControlStateNormal];
  [_overlay.restartGame setTitleColor:[GSTATE buttonColor] forState:UIControlStateNormal];
}


- (void)updateScore:(NSInteger)score
{
  _scoreView.score.text = [NSString stringWithFormat:@"%ld", (long)score];
  if ([Settings integerForKey:@"Best Score"] < score) {
    [Settings setInteger:score forKey:@"Best Score"];
    _bestView.score.text = [NSString stringWithFormat:@"%ld", (long)score];
  }
}

- (IBAction)settingsTapped:(id)sender {
	if ([self isSettingsUnlocked]) {
		// Pause Sprite Kit. Otherwise the dismissal of the modal view would lag.
		((SKView *)self.view).paused = YES;
		//Navigate to Advanced Settings
		[self presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"settingsNav"] animated:YES completion:nil];
	} else {
		//Present the user with a dialog allowing them to opt-in to an ad view in order to unlock advanced settings for a day
		//If the user doesn't want to unlock settings through an incentivized view, let simply dismiss the alert
		UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			NSLog(@"The user chose to leave settings locked");
		}];
		
		//If the user chooses to watch an ad, play an incentivized ad for them
		UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[self playIncentivizedAd];
		}];
		UIAlertController *unlockAlert = [UIAlertController alertControllerWithTitle:@"Unlock Settings?" message:@"Unlock advanced settings for 24 hours with a short video?" preferredStyle:UIAlertControllerStyleAlert];
		[unlockAlert addAction:cancel];
		[unlockAlert addAction:okAction];
		
		[self presentViewController:unlockAlert animated:YES completion:nil];
	}
}

- (IBAction)restart:(id)sender
{
    //Monetize here!
	[self playVideoAd];
	
    //Reset the game for another round
    [self hideOverlay];
    [self updateScore:0];
    [_scene startNewGame];
}


- (IBAction)keepPlaying:(id)sender
{
  [self hideOverlay];
}


- (IBAction)done:(UIStoryboardSegue *)segue
{
  ((SKView *)self.view).paused = NO;
  if (GSTATE.needRefresh) {
    [GSTATE loadGlobalState];
    [self updateState];
    [self updateScore:0];
    [_scene startNewGame];
  }
}


- (void)endGame:(BOOL)won
{
  _overlay.hidden = NO;
  _overlay.alpha = 0;
  _overlayBackground.hidden = NO;
  _overlayBackground.alpha = 0;
  
  if (!won) {
    _overlay.keepPlaying.hidden = YES;
    _overlay.message.text = @"Game Over";
  } else {
    _overlay.keepPlaying.hidden = NO;
    _overlay.message.text = @"You Win!";
  }
  
  // Fake the overlay background as a mask on the board.
  _overlayBackground.image = [M2GridView gridImageWithOverlay];
  
  // Center the overlay in the board.
  CGFloat verticalOffset = [[UIScreen mainScreen] bounds].size.height - GSTATE.verticalOffset;
  NSInteger side = GSTATE.dimension * (GSTATE.tileSize + GSTATE.borderWidth) + GSTATE.borderWidth;
  _overlay.center = CGPointMake(GSTATE.horizontalOffset + side / 2, verticalOffset - side / 2);
  
  [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    _overlay.alpha = 1;
    _overlayBackground.alpha = 1;
  } completion:^(BOOL finished) {
    // Freeze the current game.
    ((SKView *)self.view).paused = YES;
  }];
}


- (void)hideOverlay
{
  ((SKView *)self.view).paused = NO;
  if (!_overlay.hidden) {
    [UIView animateWithDuration:0.5 animations:^{
      _overlay.alpha = 0;
      _overlayBackground.alpha = 0;
    } completion:^(BOOL finished) {
      _overlay.hidden = YES;
      _overlayBackground.hidden = YES;
    }];
  }
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
	//Clear the VungleDelegate in the VungleSDK
	[[VungleSDK sharedSDK] setDelegate:nil];
}

- (BOOL)isSettingsUnlocked {
	NSInteger unlockPeriod = 60 * 60 * 24;  //One day worth of seconds
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"settingsUnlockedTimestamp"] > ([NSDate timeIntervalSinceReferenceDate] - unlockPeriod);
}

#pragma mark - Vungle Helper Methods

- (void)playIncentivizedAd {
	//Create a custom set of ad options for incentivized ads
	NSMutableDictionary *playAdOptions = [[NSMutableDictionary alloc] init];
	//Marks this play as an incentivized view
	[playAdOptions setObject:[NSNumber numberWithBool:YES] forKey:VunglePlayAdOptionKeyIncentivized];
	
	NSError *sdkError;
	[VungleSDK sharedSDK].incentivizedAlertText = @"Closing the video early will leave Settings locked.  Are you sure you don't want to continue?";
	[[VungleSDK sharedSDK] playAd:self withOptions:playAdOptions error:&sdkError];
	if (sdkError) {
		NSLog(@"Error encountered during playAd : %@", sdkError);
	}
}

- (void)playVideoAd {
	NSError *sdkError;
	if([[VungleSDK sharedSDK] isCachedAdAvailable]) {
		[[VungleSDK sharedSDK] playAd:self error:&sdkError];
		if (sdkError) {
			NSLog(@"Error encountered during playAd : %@", sdkError);
		}
	}
}

#pragma mark - VungleSDKDelegate

- (void)vungleSDKwillCloseAdWithViewInfo:(NSDictionary *)viewInfo willPresentProductSheet:(BOOL)willPresentProductSheet {
	//Verify that the view was completed before rewarding the user
	BOOL completedView = [[viewInfo valueForKey:@"completedView"] boolValue];
	if (completedView) {
		//View was successfully completed!  Update NSUserDefaults to unlock advanced settings
		NSInteger timestamp = [NSDate timeIntervalSinceReferenceDate];
		[Settings setInteger:timestamp forKey:@"settingsUnlockedTimestamp"];
	}
}

@end
