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

#import "AZTutorialViewController.h"
#import "AZTutorialView.h"
#import "AZPageControl.h"

@interface AZTutorialViewController () <UIScrollViewDelegate>

/// Casted view controller base view
@property (nonatomic, strong, readonly) AZTutorialView * castedView;
/// Current page of tutorial
@property (nonatomic, assign) AZTutorialPage currentPage;
/// Disabling of didScroll actions
@property (nonatomic, assign, getter = isSelectionDisabled) BOOL selectionDisabled;
/// Tutorial finished flag (used for prevention for multiple calls of tutorialViewControllerDidFinished on delegate)
@property (nonatomic, assign, getter = isFinished) BOOL finished;

@end

@implementation AZTutorialViewController

// MARK: Properties

- (AZTutorialView *)castedView
{
  return (AZTutorialView *)self.view;
}

// MARK: Lifecycle

- (instancetype)init
{
  self = [super init];
  if ( self == nil ) return nil;
  
  _disableSelection = NO;
  _finished = NO;
  
  return self;
}

// MARK: UIViewController

- (void)loadView
{
  self.view = [[AZTutorialView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.castedView.scrollView.delegate = self;
  [self.castedView.ringButton addTarget:self
                                 action:@selector(handleAction)
                       forControlEvents:UIControlEventTouchUpInside];
}

// MARK: UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if ( self.isSelectionDisabled == YES )
  {
    return;
  }
  CGFloat offset = scrollView.contentOffset.x;
  CGFloat max = scrollView.contentSize.width - scrollView.frame.size.width + 10;
  if ( self.isFinished == NO && offset > max )
  {
    [self.delegate tutorialViewControllerDidFinished];
    self.finished = YES;
  }
  NSInteger page = [self currentPageFromOffset];
  if ( page == self.currentPage )
  {
    return;
  }
  self.currentPage = page;
  self.castedView.pageControl.currentPage = page;
  [self.castedView setContentWithPageIndex:page];
  [self.delegate tutorialViewControllerDidSelectedPage:self.currentPage];
}

// MARK: General

- (void)moveToNextPage
{
  self.selectionDisabled = YES;
  AZTutorialPage nextPage = self.currentPage + 1;
  if ( self.isFinished == NO && nextPage == AZTutorialPageFinished )
  {
    [self.delegate tutorialViewControllerDidFinished];
    self.finished = YES;
    return;
  }
  self.currentPage = nextPage;
  [UIView animateWithDuration:0.25
                        delay:0
                      options:0
                   animations:^{
                     self.castedView.scrollView.contentOffset = CGPointMake(self.castedView.scrollView.frame.size.width * nextPage, 0);
                     [self.castedView setContentWithPageAtIndex:nextPage];
                   }
                   completion:nil];
  self.castedView.pageControl.currentPage = nextPage;
  self.selectionDisabled = NO;
}

/**
 Determines current page from UIScrollView left content offset
 @return Current page identifier
 */
- (AZTutorialPage)currentPageFromOffset
{
  CGFloat left = self.castedView.scrollView.contentOffset.x + self.castedView.scrollView.frame.size.width / 2.0;
  NSInteger page = left / self.castedView.scrollView.frame.size.width;
  page = MAX(0, MIN(page, AZTutorialPageFinished));
  return page;
}

/**
 Called when ring overlay button is pressed
 */
- (void)handleAction
{
  [self.delegate tutorialViewControllerDidParformActionOnPage:[self currentPage]];
}

@end
