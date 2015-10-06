// ******************************************************************************
//
// Copyright © 2015, Adam Zdara. All rights reserved.
//
// All rights reserved. This source code can be used only for purposes specified
// by the given license contract signed by the rightful deputy of Adam Zdara.
// This source code can be used only by the owner of the license.
//
// Any disputes arising in respect of this agreement (license) shall be brought
// before the Municipal Court of Prague.
//
// ******************************************************************************

#import <UIKit/UIKit.h>

// MARK: Types

/**
 Enumerator of all tutorial pages
 */
typedef NS_ENUM(NSInteger, AZTutorialPage) {
  AZTutorialPageSelection = 0,
  AZTutorialPageCut = 1,
  AZTutorialPageMove = 2,
  AZTutorialPageDelete = 3,
  AZTutorialPageFinished = 4
};

/**
 Tutorial delegate
 */
@protocol AZTutorialViewControllerDelegate <NSObject>

/**
 Called when tutorial is finished
 */
- (void)tutorialViewControllerDidFinished;

/**
 Called when tutorial changed its current page
 @param page New page
 */
- (void)tutorialViewControllerDidSelectedPage:(AZTutorialPage)page;

/**
 Called when user performs action that should lead to next page
 @param page Current page
 */
- (void)tutorialViewControllerDidParformActionOnPage:(AZTutorialPage)page;

@end

// MARK: Interface

/**
 View controller handles presentation and all actions of overlay tutorial layer
 with multiple pages that shows instructions for user
 */
@interface AZTutorialViewController: UIViewController

@property (nonatomic, weak) id<AZTutorialViewControllerDelegate> delegate;

/**
 Moves tutorial to next page. Usually called after execution of 
 tutorialViewControllerDidParformActionOnPage is finished.
 */
- (void)moveToNextPage;

@end


