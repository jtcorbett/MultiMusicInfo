//
//  Task_.mm
//  Task+
//
//  Created by John Corbett on 8/20/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//
//  MobileSubstrate, libsubstrate.dylib, and substrate.h are
//  created and copyrighted by Jay Freeman a.k.a saurik and 
//  are protected by various means of open source licensing.
//
//  Additional defines courtesy Lance Fetters a.k.a ashikase
// 



#import <objc/message.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

#include <substrate.h>

#define HOOK(class, name, type, args...) \
static IMP __ ## class ## $ ## name; \
type _ ## class ## $ ## name (id self, SEL _cmd, ## args)

#define CALL_ORIG(class, name, args...) \
__ ## class ## $ ## name(self, _cmd, ## args)

#define MS(selector, class, name) \
MSHookMessageEx( class , selector, \
(IMP) _ ## class ## $ ## name , (IMP *) &__ ## class ## $ ## name )

#pragma mark -
#pragma mark Now playing bar

#define kLowestLabel 72
#define kMediumLabel 59
#define kHighestLabel 46
#define kLabelXval -7
#define kLabelHieght 18
#define kLabelWidth 159

#define kLoadingSecondTime 2 

#define kAlbumImageViewX 156

#define kLeftButtonTag 97
#define kPlayButtonTag 96
#define kRightButtonTag 95

#define kAnimationDuration 0.5

static id controlView = nil;
static id musicViewRef = nil;

static UILabel *artistLabel = nil;
static UILabel *albumLabel = nil;
static UILabel *songLabel = nil;
static UIView *albumImageView = nil;

static UIButton *prevButton;
static UIButton *playButton;
static UIButton *nextButton;

static NSArray * subviews = nil;

static MPMediaItem *nowPlayingMediaItem = nil;
static NSString *artist = nil;
static NSString *album = nil;
static MPMediaItemArtwork *albumItemCover = nil;
static UIImage *albumCover = nil;

static UIImageView *overlay = nil;
static UIImageView *cover = nil;

static NSUInteger coverFrame = 53;
static BOOL isPlaying = NO;

BOOL overlayEnabled;
BOOL onlyShowAlbum;

NSUInteger indexz = 5;
Class SBUserInstalledApplicationIcon = objc_getClass("SBUserInstalledApplicationIcon");
Class SBAppIcon = objc_getClass("SBApplicationIcon");
Class SBNowPlayingView = objc_getClass("SBNowPlayingBarView");

//NSArray *supportedApps = [NSArray arrayWithObjects:@"iPod", @"Music", nil];

@interface UIView (falseCatagory)
-(void)setText:(id)text;
-(void)setInDock:(BOOL)dock;
@end

@protocol MultiMusicInfo
-(id)prevButton;
-(id)playButton;
-(id)nextButton;
-(id)nowPlayingIcon;
@end

#pragma mark -
#pragma mark 4.3.1


#pragma mark -
#pragma mark 4.2.1



void resetViewsNew(id self) {
	
	[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
	[artistLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
	[artistLabel setHidden:YES];
	[albumLabel setHidden:YES];
	
	[UIView beginAnimations:@"moveButtonsReset" context:nil];
	[UIView setAnimationDuration:kAnimationDuration];
	[UIView setAnimationDidStopSelector:@selector(hideAlbumViews)];
	
	[playButton setFrame:CGRectMake(48, 22, 47, 47)];
	[prevButton setFrame:CGRectMake(0, 22, 47, 47)];
	[nextButton setFrame:CGRectMake(95, 22, 47, 47)];	
	[songLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
	[songLabel setText:@""];
	
	if (![controlView isMemberOfClass:SBUserInstalledApplicationIcon]) {
		objc_msgSend([controlView nowPlayingIcon], @selector(setIconImageAlpha:), 0.01f);
	}
	
	[UIView commitAnimations];
	
	NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
	
	overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
	
	[preferences dealloc];
	
	[albumImageView setHidden:YES];
	if (![[controlView nowPlayingIcon] isMemberOfClass:SBUserInstalledApplicationIcon]) {
		[albumImageView setHidden:NO];
	}
	
	if (!overlayEnabled) {
		[albumImageView setHidden:YES];
	}
}

void reloadViewsNew(id self) {
	
	object_getInstanceVariable(musicViewRef, "_isPlaying", (void**) &isPlaying);
	
	if (isPlaying && !([[controlView nowPlayingIcon] isMemberOfClass:SBUserInstalledApplicationIcon]))	{
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle];
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences dealloc];
		
		if (!onlyShowAlbum) {
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		}
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]];
		
		
		BOOL albumCoverAvailable = (albumCover == nil);
		float alphaValues[] = {1.0f, 0.01f};
		
		[albumImageView setHidden:albumCoverAvailable];
		[cover setImage:albumCover];
		
		[UIView beginAnimations:@"updateLabel" context:nil];
		[UIView setAnimationDuration:kAnimationDuration];
		
		objc_msgSend([controlView nowPlayingIcon], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[UIView commitAnimations];
	}
	
}	

void reloadSongInfo(id self, SEL _cmd) {
	[self performSelector:@selector(reloadViewsWithDelay) withObject:self afterDelay:.5];
}

void hideAlbumView(id self, SEL _cmd) {
	[albumImageView setHidden:YES];
}

void playButtonHit(id, SEL);

HOOK($SB_NowPlayingBarView, init, id, CGRect frame) {
	if (!(self = CALL_ORIG($SB_NowPlayingBarView, init, frame))) 
		return nil;
	
	controlView = self;
	
	return self;
}

HOOK ($SB_NowPlayingBarMediaControlsView, init, id, CGRect frame) {
	
	if (!(self = CALL_ORIG($SB_NowPlayingBarMediaControlsView, init, frame)))
		return nil;
	
	artistLabel = [[UILabel alloc] init];
	[artistLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 49
	[artistLabel setTextColor:[UIColor whiteColor]];
	[artistLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[artistLabel setTextAlignment:UITextAlignmentCenter];
	[artistLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[artistLabel setText:@""];
	
	albumLabel = [[UILabel alloc] init];
	[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 73
	[albumLabel setTextColor:[UIColor whiteColor]];
	[albumLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[albumLabel setTextAlignment:UITextAlignmentCenter];
	[albumLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[albumLabel setText:@""];
	
	songLabel = [[UILabel alloc] init];
	[songLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 76
	[songLabel setTextColor:[UIColor whiteColor]];
	[songLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[songLabel setTextAlignment:UITextAlignmentCenter];
	[songLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[songLabel setText:@""];
	
	albumImageView = [[UIView alloc] initWithFrame:CGRectMake(kAlbumImageViewX, 16, 59, 59)];
	
	[self addSubview:albumLabel];
	[self addSubview:artistLabel];
	[self addSubview:songLabel];
	
	
	cover = [[UIImageView alloc] initWithFrame:CGRectMake(5, 3, 50, 52)];
	[albumImageView addSubview:cover];
	
	overlay = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 59, 59)];
	UIImage *overlayImage = [[UIImage alloc] initWithContentsOfFile:@"/var/mobile/Library/MultiMusicInfo/Overlay.png"];
	[overlay setImage:overlayImage];
	[overlayImage release];
	[albumImageView addSubview:overlay];
	
	[albumImageView setHidden:YES]; 
	[self insertSubview:albumImageView atIndex:0];
	
	
	id hideView;
	object_getInstanceVariable(self, "_trackLabel", (void**) &hideView);
	objc_msgSend(hideView, @selector(setHidden:), YES);
	object_getInstanceVariable(self, "_orientationLabel", (void**) &hideView);
	objc_msgSend(hideView, @selector(setHidden:), YES);
	
	playButton = [self playButton];
	prevButton = [self prevButton];
	nextButton = [self nextButton];
	
	class_addMethod([self class], @selector(playButtonHit), (IMP)playButtonHit, "@:");
	[playButton addTarget:self action:@selector(playButtonHit) forControlEvents:UIControlEventTouchUpInside];
	class_addMethod([self class], @selector(reloadViews), (IMP)reloadSongInfo, "@:");
	class_addMethod([self class], @selector(reloadViewsWithDelay), (IMP)reloadViewsNew, "@:");
	class_addMethod([self class], @selector(hideAlbumView), (IMP)hideAlbumView, "@:");
	[nextButton addTarget:self action:@selector(reloadViews) forControlEvents:UIControlEventTouchUpInside];
	[prevButton addTarget:self action:@selector(reloadViews) forControlEvents:UIControlEventTouchUpInside];
	
	musicViewRef = self;
	
	return self;
}

void playButtonHit(id self, SEL _cmd) {
	
	object_getInstanceVariable(self, "_isPlaying", (void**) &isPlaying);
	static Byte needsToLoad = true;
	
	//	NSLog(@"\n\n\n\n%@\n\n\n\n\n", [[iPodIcon nowPlayingIcon] class]);
	
	if ((!isPlaying || (needsToLoad == kLoadingSecondTime)) && !([[controlView nowPlayingIcon] isMemberOfClass:SBUserInstalledApplicationIcon])) {
		
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle]; 		
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		if (needsToLoad == true) {
			needsToLoad = kLoadingSecondTime;
			[self performSelector:_cmd withObject:self afterDelay:3];
		}
		else if (needsToLoad == kLoadingSecondTime) {
			needsToLoad = false;
		}
		
		[cover setImage:albumCover];
		BOOL albumCoverAvailable = (albumCover == nil);
		[albumImageView setHidden:albumCoverAvailable];
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences release];
		
		[UIView beginAnimations:@"moveButtonsReset" context:nil];
		[UIView setAnimationDuration:kAnimationDuration];
		
		if (!onlyShowAlbum) {
			
			[playButton setFrame:CGRectMake(48, 5, 47, 47)];
			[prevButton setFrame:CGRectMake(0, 5, 47, 47)];
			[nextButton setFrame:CGRectMake(95, 5, 47, 47)];
			[songLabel setFrame:CGRectMake(kLabelXval, kMediumLabel, kLabelWidth, kLabelHieght)];
			[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];
			[artistLabel setFrame:CGRectMake(kLabelXval, kHighestLabel, kLabelWidth, kLabelHieght)];
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		}
		
		float alphaValues[] = {1.0f, 0.01f};
		objc_msgSend([controlView nowPlayingIcon], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[UIView commitAnimations];
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]]; 
	}
	
	else 
		resetViewsNew(self);
}



HOOK($SB_NowPlayingBar, prepareToAppear, void) {
	
	
	NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
	
	overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
	onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
	
	[preferences dealloc];
	
	if (overlayEnabled) {
		[overlay setHidden:NO];
		[cover setFrame:CGRectMake(3, 3, 52, 52)];
		coverFrame = 52;
	}
	else {
		[overlay setHidden:YES];
		[cover setFrame:CGRectMake(0, 0, 59, 59)];
		coverFrame = 59;
	}
	
	if (onlyShowAlbum) {
		[playButton setFrame:CGRectMake(48, 22, 47, 47)];
		[prevButton setFrame:CGRectMake(0, 22, 47, 47)];
		[nextButton setFrame:CGRectMake(95, 22, 47, 47)];
		[songLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
		[albumLabel setHidden:YES];
		[artistLabel setHidden:YES];
		
	} 
	
	object_getInstanceVariable(musicViewRef, "_isPlaying", (void**) &isPlaying);
	
	if (isPlaying && !([[controlView nowPlayingIcon] isMemberOfClass:SBUserInstalledApplicationIcon])) {
		
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle]; 		
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		[cover setImage:albumCover];
		BOOL albumCoverAvailable = (albumCover == nil);
		
		[albumImageView setHidden:albumCoverAvailable];	
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences release];
		
		if (!onlyShowAlbum) {
			[playButton setFrame:CGRectMake(48, 5, 47, 47)];
			[prevButton setFrame:CGRectMake(0, 5, 47, 47)];
			[nextButton setFrame:CGRectMake(95, 5, 47, 47)];
			[songLabel setFrame:CGRectMake(kLabelXval, kMediumLabel, 159, 18)];
			[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
			[artistLabel setFrame:CGRectMake(kLabelXval, kHighestLabel, 159, 18)];
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		} 
		
		float alphaValues[] = {1.0f, 0.01f};
		
		objc_msgSend([controlView nowPlayingIcon], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]]; 
	}
	
	else 
		resetViewsNew(musicViewRef);
}

HOOK($SB_NowPlayingBarMediaControlsView, dealloc, void) {
	[artistLabel release];
	[songLabel release];
	[albumLabel release];
	[cover release];
	[overlay release];
	[albumImageView release];
	
	CALL_ORIG($SB_NowPlayingBarMediaControlsView, dealloc);
}

#pragma mark -
#pragma mark 5.0

HOOK($SB_NowPlayingBar, viewDidAppear, void) {
	
	
	NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
	
	overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
	onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
	
	[preferences dealloc];
	
	if (overlayEnabled) {
		[overlay setHidden:NO];
		[cover setFrame:CGRectMake(3, 3, 52, 52)];
		coverFrame = 52;
	}
	else {
		[overlay setHidden:YES];
		[cover setFrame:CGRectMake(0, 0, 59, 59)];
		coverFrame = 59;
	}
	
	if (onlyShowAlbum) {
		[playButton setFrame:CGRectMake(48, 22, 47, 47)];
		[prevButton setFrame:CGRectMake(0, 22, 47, 47)];
		[nextButton setFrame:CGRectMake(95, 22, 47, 47)];
		[songLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
		[albumLabel setHidden:YES];
		[artistLabel setHidden:YES];
		
	} 
	
	object_getInstanceVariable(musicViewRef, "_isPlaying", (void**) &isPlaying);
	
    //fix that ^
    
	if (isPlaying && !([[controlView nowPlayingIcon] isMemberOfClass:SBUserInstalledApplicationIcon])) {
		
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle]; 		
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		[cover setImage:albumCover];
		BOOL albumCoverAvailable = (albumCover == nil);
		
		[albumImageView setHidden:albumCoverAvailable];	
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences release];
		
		if (!onlyShowAlbum) {
			[playButton setFrame:CGRectMake(48, 5, 47, 47)];
			[prevButton setFrame:CGRectMake(0, 5, 47, 47)];
			[nextButton setFrame:CGRectMake(95, 5, 47, 47)];
			[songLabel setFrame:CGRectMake(kLabelXval, kMediumLabel, 159, 18)];
			[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, 159, 18)];
			[artistLabel setFrame:CGRectMake(kLabelXval, kHighestLabel, 159, 18)];
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		} 
		
		float alphaValues[] = {1.0f, 0.01f};
		
		objc_msgSend([controlView nowPlayingIcon], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]]; 
	}
	
	else 
		resetViewsNew(musicViewRef);
}

/*

HOOK ($SB_NowPlayingBarMediaControlsView, init, id, CGRect frame) {
	
	if (!(self = CALL_ORIG($SB_NowPlayingBarMediaControlsView, init, frame)))
		return nil;
	
	artistLabel = [[UILabel alloc] init];
	[artistLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 49
	[artistLabel setTextColor:[UIColor whiteColor]];
	[artistLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[artistLabel setTextAlignment:UITextAlignmentCenter];
	[artistLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[artistLabel setText:@""];
	
	albumLabel = [[UILabel alloc] init];
	[albumLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 73
	[albumLabel setTextColor:[UIColor whiteColor]];
	[albumLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[albumLabel setTextAlignment:UITextAlignmentCenter];
	[albumLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[albumLabel setText:@""];
	
	songLabel = [[UILabel alloc] init];
	[songLabel setFrame:CGRectMake(kLabelXval, kLowestLabel, kLabelWidth, kLabelHieght)];//80 76
	[songLabel setTextColor:[UIColor whiteColor]];
	[songLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[songLabel setTextAlignment:UITextAlignmentCenter];
	[songLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[songLabel setText:@""];
	
	albumImageView = [[UIView alloc] initWithFrame:CGRectMake(kAlbumImageViewX, 16, 59, 59)];
	
	[self addSubview:albumLabel];
	[self addSubview:artistLabel];
	[self addSubview:songLabel];
	
	
	cover = [[UIImageView alloc] initWithFrame:CGRectMake(5, 3, 50, 52)];
	[albumImageView addSubview:cover];
	
	overlay = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 59, 59)];
	UIImage *overlayImage = [[UIImage alloc] initWithContentsOfFile:@"/var/mobile/Library/MultiMusicInfo/Overlay.png"];
	[overlay setImage:overlayImage];
	[overlayImage release];
	[albumImageView addSubview:overlay];
	
	[albumImageView setHidden:YES]; 
	[self insertSubview:albumImageView atIndex:0];
	
	
	id hideView;
	object_getInstanceVariable(self, "_trackLabel", (void**) &hideView);
	objc_msgSend(hideView, @selector(setHidden:), YES);
	object_getInstanceVariable(self, "_orientationLabel", (void**) &hideView);
	objc_msgSend(hideView, @selector(setHidden:), YES);
	
	playButton = [self playButton];
	prevButton = [self prevButton];
	nextButton = [self nextButton];
	
	class_addMethod([self class], @selector(playButtonHit), (IMP)playButtonHit, "@:");
	[playButton addTarget:self action:@selector(playButtonHit) forControlEvents:UIControlEventTouchUpInside];
	class_addMethod([self class], @selector(reloadViews), (IMP)reloadSongInfo, "@:");
	class_addMethod([self class], @selector(reloadViewsWithDelay), (IMP)reloadViewsNew, "@:");
	class_addMethod([self class], @selector(hideAlbumView), (IMP)hideAlbumView, "@:");
	[nextButton addTarget:self action:@selector(reloadViews) forControlEvents:UIControlEventTouchUpInside];
	[prevButton addTarget:self action:@selector(reloadViews) forControlEvents:UIControlEventTouchUpInside];
	
	musicViewRef = self;
	
	return self;
}

HOOK($SB_NowPlayingBarMediaControlsView, dealloc, void) {
	[artistLabel release];
	[songLabel release];
	[albumLabel release];
	[cover release];
	[overlay release];
	[albumImageView release];
	
	CALL_ORIG($SB_NowPlayingBarMediaControlsView, dealloc);
}
*/
#pragma mark -
#pragma mark 4.1

void resetViews(id self) {
	
	[albumLabel setFrame:CGRectMake(80, 76, 159, 18)];
	[artistLabel setFrame:CGRectMake(80, 76, 159, 18)];
	
	[UIView beginAnimations:@"moveButtonsReset" context:nil];
	[UIView setAnimationDuration:kAnimationDuration];
	
	[[[self view] viewWithTag:kPlayButtonTag] setFrame:CGRectMake(137, 22, 47, 47)];
	[[[self view] viewWithTag:kLeftButtonTag] setFrame:CGRectMake(89, 22, 47, 47)];
	[[[self view] viewWithTag:kRightButtonTag] setFrame:CGRectMake(185, 22, 47, 47)];	
	[songLabel setFrame:CGRectMake(80, 76, 159, 18)];

	if (![[[[self view] subviews] lastObject] isMemberOfClass:SBUserInstalledApplicationIcon]) {
		objc_msgSend([subviews objectAtIndex:indexz], @selector(setIconImageAlpha:), 0.01f);
	}
	
	[UIView commitAnimations];
	
	NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
	
	overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
	onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
	
	[preferences dealloc];
	
	[albumImageView setHidden:YES];
	if (![[[[self view] subviews] lastObject] isMemberOfClass:SBUserInstalledApplicationIcon]) {
		[albumImageView setHidden:NO];
	}
	
	if (!overlayEnabled) {
		[albumImageView setHidden:YES];
	}
	
	[artistLabel setHidden:YES];
	[albumLabel setHidden:YES];
}

void reloadViews(id self) {
	if ([[MPMusicPlayerController iPodMusicPlayer] playbackState] == MPMusicPlaybackStatePlaying) {
		
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem];
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle];
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences dealloc];
		
		if (!onlyShowAlbum) {
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		}
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]];
		
				
		BOOL albumCoverAvailable = (albumCover == nil);
		float alphaValues[] = {1.0f, 0.01f};
		
		[albumImageView setHidden:albumCoverAvailable];
		[cover setImage:albumCover];

		[UIView beginAnimations:@"updateLabel" context:nil];
		[UIView setAnimationDuration:kAnimationDuration];
		
		objc_msgSend([subviews objectAtIndex:indexz], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[UIView commitAnimations];
	}
}	

HOOK($SB_NowPlayingBar, init, id) {	
	
	artistLabel = [[UILabel alloc] init];
	[artistLabel setFrame:CGRectMake(80, 49, 159, 18)];
	[artistLabel setTextColor:[UIColor whiteColor]];
	[artistLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[artistLabel setTextAlignment:UITextAlignmentCenter];
	[artistLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[artistLabel setText:@""];

	albumLabel = [[UILabel alloc] init];
	[albumLabel setFrame:CGRectMake(80, 73, 159, 18)];
	[albumLabel setTextColor:[UIColor whiteColor]];
	[albumLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[albumLabel setTextAlignment:UITextAlignmentCenter];
	[albumLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[albumLabel setText:@""];

	albumImageView = [[UIView alloc] initWithFrame:CGRectMake(244, 16, 59, 59)];

	[[self view] addSubview:albumLabel];
	[[self view] addSubview:artistLabel];
	
	
	cover = [[UIImageView alloc] initWithFrame:CGRectMake(5, 3, 50, 52)];
	[albumImageView addSubview:cover];
	
	overlay = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 59, 59)];
	UIImage *overlayImage = [[UIImage alloc] initWithContentsOfFile:@"/var/mobile/Library/MultiMusicInfo/Overlay.png"];
	[overlay setImage:overlayImage];
	[overlayImage release];
	[albumImageView addSubview:overlay];
	
	[albumImageView setHidden:YES]; 
	[[self view] insertSubview:albumImageView atIndex:0];
	
	[[[[self view] subviews] objectAtIndex:2] setTag:kPlayButtonTag];
	[[[[self view] subviews] objectAtIndex:3] setTag:kLeftButtonTag];
	[[[[self view] subviews] objectAtIndex:4] setTag:kRightButtonTag];
	[[[[self view] subviews] objectAtIndex:6] setHidden:YES];

	songLabel = [[UILabel alloc] init];
	[songLabel setFrame:CGRectMake(80, 76, 159, 18)];
	[songLabel setTextColor:[UIColor whiteColor]];
	[songLabel setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.0f]];
	[songLabel setTextAlignment:UITextAlignmentCenter];
	[songLabel setFont:[UIFont boldSystemFontOfSize:11.0f]];
	[songLabel setText:@""];
	
	[[self view] addSubview:songLabel];
	
	subviews = [[[self view] subviews] retain];
	
	return CALL_ORIG($SB_NowPlayingBar, init);
}

HOOK($SB_NowPlayingBar, viewWillAppear, void) {
	NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
	
	overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
	onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
	
	[preferences dealloc];
	
	if (overlayEnabled) {
		[overlay setHidden:NO];
		[cover setFrame:CGRectMake(3, 3, 52, 52)];
		coverFrame = 52;
	}
	else {
		[overlay setHidden:YES];
		[cover setFrame:CGRectMake(0, 0, 59, 59)];
		coverFrame = 59;
	}
	
	if (onlyShowAlbum) {
		[[[self view] viewWithTag:kPlayButtonTag] setFrame:CGRectMake(137, 22, 47, 47)];
		[[[self view] viewWithTag:kLeftButtonTag] setFrame:CGRectMake(89, 22, 47, 47)];
		[[[self view] viewWithTag:kRightButtonTag] setFrame:CGRectMake(185, 22, 47, 47)];	
		[songLabel setFrame:CGRectMake(80, 76, 159, 18)];
		[albumLabel setHidden:YES];
		[artistLabel setHidden:YES];
		
	} 
	
	object_getInstanceVariable(self, "_isPlaying", (void**) &isPlaying);
	
	if (isPlaying && (![[[[self view] subviews] lastObject] isMemberOfClass:SBUserInstalledApplicationIcon])) {
		if ([[[[self view] subviews] lastObject] isMemberOfClass:SBAppIcon] && (indexz == 5)) 
			indexz = 10;
		
		[subviews release];
		subviews = [[[self view] subviews] retain];
				
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem]; NSLog(@"2.5");
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle]; 		
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		[cover setImage:albumCover];
		BOOL albumCoverAvailable = (albumCover == nil);
		[albumImageView setHidden:albumCoverAvailable];	
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences release];
				
		if (!onlyShowAlbum) {
			[[[self view] viewWithTag:kPlayButtonTag] setFrame:CGRectMake(137, 5, 47, 47)];
			[[[self view] viewWithTag:kLeftButtonTag] setFrame:CGRectMake(89, 5, 47, 47)];
			[[[self view] viewWithTag:kRightButtonTag] setFrame:CGRectMake(185, 5, 47, 47)];
			[songLabel setFrame:CGRectMake(80, 61, 159, 18)];
			[albumLabel setFrame:CGRectMake(80, 73, 159, 18)];
			[artistLabel setFrame:CGRectMake(80, 49, 159, 18)];
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
		}
		
		float alphaValues[] = {1.0f, 0.01f};
		objc_msgSend([subviews objectAtIndex:indexz], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]]; 
	}
	
	else 
		resetViews(self);
}


HOOK($SB_NowPlayingBar, _playButtonHit, void, id hit) {
	CALL_ORIG($SB_NowPlayingBar, _playButtonHit, hit);
	
	object_getInstanceVariable(self, "_isPlaying", (void**) &isPlaying);
	
	if (!isPlaying && (![[[[self view] subviews] lastObject] isMemberOfClass:SBUserInstalledApplicationIcon])) {

		if ([[[[self view] subviews] lastObject] isMemberOfClass:SBAppIcon] && (indexz == 5)) 
			indexz = 10;
		
		[subviews release];
		subviews = [[[self view] subviews] retain];
				
		nowPlayingMediaItem = [[MPMusicPlayerController iPodMusicPlayer] nowPlayingItem]; NSLog(@"2.5");
		artist = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtist];
		album = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyAlbumTitle]; 		
		albumItemCover = [nowPlayingMediaItem valueForProperty:MPMediaItemPropertyArtwork];
		albumCover = objc_msgSend(albumItemCover, @selector(imageWithSize:), CGSizeMake(coverFrame, coverFrame));
		
		[cover setImage:albumCover];
		BOOL albumCoverAvailable = (albumCover == nil);
		[albumImageView setHidden:albumCoverAvailable];	
		
		NSDictionary *preferences = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.flyingguitar.MultiMusicInfo.plist"];
		
		overlayEnabled = [[preferences objectForKey:@"overlayEnabled"] boolValue];
		onlyShowAlbum = [[preferences objectForKey:@"onlyShowAlbum"] boolValue];
		
		[preferences release];
				
		if (!onlyShowAlbum) {
			
			[UIView beginAnimations:@"moveButtonsReset" context:nil];
			[UIView setAnimationDuration:kAnimationDuration];
			[[[self view] viewWithTag:kPlayButtonTag] setFrame:CGRectMake(137, 5, 47, 47)];
			[[[self view] viewWithTag:kLeftButtonTag] setFrame:CGRectMake(89, 5, 47, 47)];
			[[[self view] viewWithTag:kRightButtonTag] setFrame:CGRectMake(185, 5, 47, 47)];
			[songLabel setFrame:CGRectMake(80, 61, 159, 18)];
			[albumLabel setFrame:CGRectMake(80, 73, 159, 18)];
			[artistLabel setFrame:CGRectMake(80, 49, 159, 18)];
			[artistLabel setHidden:NO];
			[albumLabel setHidden:NO];
			[UIView commitAnimations];
		}
		
		float alphaValues[] = {1.0f, 0.01f};
		objc_msgSend([subviews objectAtIndex:indexz], @selector(setIconImageAlpha:), alphaValues[albumCoverAvailable]);
		
		[artistLabel setText:artist];
		[albumLabel setText:album];
		[songLabel setText:[nowPlayingMediaItem valueForProperty:MPMediaItemPropertyTitle]]; 
	}
	
	else 
		resetViews(self);
}

HOOK($SB_NowPlayingBar, _trackButtonUp, void, id up) {

	CALL_ORIG($SB_NowPlayingBar, _trackButtonUp, up);
		
	reloadViews(self);
}
	
HOOK($SB_NowPlayingBar, _trackButtonDown, void, id down) {
	
	CALL_ORIG($SB_NowPlayingBar, _trackButtonDown, down);
	
	reloadViews(self);
}

HOOK($SB_NowPlayingBar, dealloc, void) {
	[subviews release];
	[artistLabel release];
	[songLabel release];
	[albumLabel release];
	[cover release];
	[overlay release];
	[albumImageView release];
	CALL_ORIG($SB_NowPlayingBar, dealloc);
}
 
HOOK($SB_NowPlayingBar, _displayOrientationStatus, void, BOOL status) {}
	
#pragma mark -
#pragma mark dylib initialization and initial hooks

static __attribute__((constructor)) void hookInit() {	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	

	Class $SB_NowPlayingBar = objc_getClass("SBNowPlayingBar");
	Class $SB_NowPlayingBarView = objc_getClass("SBNowPlayingBarView");
	Class $SB_NowPlayingBarMediaControlsView = objc_getClass("SBNowPlayingBarMediaControlsView");

	NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
		
	char version = [systemVersion characterAtIndex:2];
	bool runningFirmware = ([systemVersion characterAtIndex:0] >= '4');
		
    if ([systemVersion characterAtIndex:0] >= '5') {
		MS(@selector(viewDidAppear), $SB_NowPlayingBar, viewDidAppear);
		MS(@selector(initWithFrame:), $SB_NowPlayingBarMediaControlsView, init);
		MS(@selector(dealloc), $SB_NowPlayingBarMediaControlsView, dealloc); 
		MS(@selector(initWithFrame:), $SB_NowPlayingBarView, init);
    }
    
	if (([systemVersion characterAtIndex:0] >= '5') || (version >= '2' && runningFirmware)) {
		MS(@selector(prepareToAppear), $SB_NowPlayingBar, prepareToAppear);
		MS(@selector(initWithFrame:), $SB_NowPlayingBarMediaControlsView, init);
		MS(@selector(dealloc), $SB_NowPlayingBarMediaControlsView, dealloc); 
		MS(@selector(initWithFrame:), $SB_NowPlayingBarView, init);
	}
	
	else if (version == '1' && runningFirmware) {
		MS(@selector(viewWillAppear), $SB_NowPlayingBar, viewWillAppear);
	//	MS(@selector(_updateNowPlayingInfo), $SB_NowPlayingBar, _updateNowPlayingInfo);
		MS(@selector(_playButtonHit:), $SB_NowPlayingBar, _playButtonHit);
		MS(@selector(_trackButtonUp:), $SB_NowPlayingBar, _trackButtonUp);
		MS(@selector(_trackButtonDown:), $SB_NowPlayingBar, _trackButtonDown);
		MS(@selector(init), $SB_NowPlayingBar, init);
		MS(@selector(dealloc), $SB_NowPlayingBar, dealloc); 
		MS(@selector(_displayOrientationStatus:), $SB_NowPlayingBar, _displayOrientationStatus); 
	}
	
	[pool release];
}