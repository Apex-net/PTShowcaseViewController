//
// Copyright (C) 2012 Ali Servet Donmez. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "PTShowcaseViewController.h"

#import "PTImageAlbumViewController.h"
#import <MediaPlayer/MediaPlayer.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private APIs
////////////////////////////////////////////////////////////////////////////////
@interface PTShowcaseView () <GMGridViewDataSource>

@end

@interface PTShowcaseViewController () <GMGridViewActionDelegate, PTImageAlbumViewDataSource, PTImageAlbumViewDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *activityPopoverController;
@property (strong, nonatomic) UIBarButtonItem *actionBarButtonItem;
@property (assign, nonatomic) NSInteger selectedItemPosition;
@property (assign, nonatomic) NSInteger selectedNestedItemPosition;

- (void)dismissImageDetailViewController;

@end

#pragma mark - Group detail

@implementation PTGroupDetailViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [[self.navigationController.viewControllers objectAtIndex:0] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class implementation
////////////////////////////////////////////////////////////////////////////////
@implementation PTShowcaseViewController

#pragma mark - Initializing

- (id)init
{
    return [self initWithUniqueName:nil];
    
    // share option disabled by default
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSAssert(nibBundleOrNil == nil, @"Initializing showcase view controller with the nib file is not supported yet!");
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarInDetails = NO;
        self.activityButtonEnabled = YES;
    }
    return self;
}

- (id)initWithUniqueName:(NSString *)uniqueName
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.showcaseView = [[PTShowcaseView alloc] initWithUniqueName:uniqueName];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView
{
    if (self.nibName) {
        // although documentation states that custom implementation of this method
        // should not call super, it is easier than loading nib on my own, because
        // I'm too lazy! ;-)
        [super loadView];
    }
    else {
        self.view = self.showcaseView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.showcaseView == nil) {
        self.showcaseView = (PTShowcaseView *)self.view;
    }
    
    if (self.showcaseView.showcaseDelegate == nil) {
        self.showcaseView.showcaseDelegate = self;
    }
    
    if (self.showcaseView.showcaseDataSource == nil) {
        self.showcaseView.showcaseDataSource = self;
    }
    
    // Internal
    self.showcaseView.dataSource = self.showcaseView; // this will trigger 'reloadData' automatically
    self.showcaseView.actionDelegate = self;
    
    self.selectedItemPosition = 0;
    self.selectedNestedItemPosition = 0;
    self.showcaseView.maxSharingFileSize = self.maxSharingFileSize;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.showcaseView = nil;
}

/*
 * Prior to iOS 6, when a low-memory warning occurred, the UIViewController
 * class purged its views if it knew it could reload or recreate them again
 * later. If this happens, it also calls the viewWillUnload and viewDidUnload
 * methods to give your code a chance to relinquish ownership of any objects
 * that are associated with your view hierarchy, including objects loaded from
 * the nib file, objects created in your viewDidLoad method, and objects created
 * lazily at runtime and added to the view hierarchy.
 
 * On iOS 6, views are never purged and these methods are never called. If a
 * view controller needs to perform specific tasks when memory is low, it should
 * override the didReceiveMemoryWarning method.
 *
 * This will simulate previous behavior also in iOS 6 without hurting much.
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && [self.view window] == nil) {
        [self viewWillUnload];
        [self setView:nil];
        [self viewDidUnload];
    }
}

#pragma mark - Setter

- (void)setMaxSharingFileSize:(NSNumber *)maxSharingFileSize
{
    _maxSharingFileSize = maxSharingFileSize;
    self.showcaseView.maxSharingFileSize = maxSharingFileSize;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Phone: any orientation except upside down
    // Pad  : any orientation is just fine
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return interfaceOrientation =! UIInterfaceOrientationPortraitUpsideDown;
    }
    
    return YES;
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#warning move to view

#pragma mark - ()

- (void)dismissImageDetailViewController
{
    UINavigationController *navCtrl = (UINavigationController *)self.presentedViewController;
    PTImageAlbumViewController *imageAlbumViewController = (PTImageAlbumViewController *)[[navCtrl viewControllers] objectAtIndex:0];
    NSInteger relativeIndex = imageAlbumViewController.photoAlbumView.centerPageIndex;
    NSInteger index = [self.showcaseView indexForItemAtRelativeIndex:relativeIndex withContentType:PTContentTypeImage];
    [self.showcaseView scrollToObjectAtIndex:index atScrollPosition:GMGridViewScrollPositionTop animated:NO];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - GMGridViewActionDelegate

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    self.selectedItemPosition = position;
    PTContentType contentType = [self.showcaseView contentTypeForItemAtIndex:position];
    
    switch (contentType)
    {
        case PTContentTypeGroup:
        {
            NSString *uniqueName = [self.showcaseView uniqueNameForItemAtIndex:position];
            NSString *text = [self.showcaseView textForItemAtIndex:position];
            
            PTGroupDetailViewController *detailViewController = [[PTGroupDetailViewController alloc] initWithUniqueName:uniqueName];
            detailViewController.showcaseView.showcaseDelegate = self.showcaseView.showcaseDelegate;
            detailViewController.showcaseView.showcaseDataSource = self.showcaseView.showcaseDataSource;
            
            detailViewController.activityButtonEnabled = self.activityButtonEnabled;
            detailViewController.excludedActivityTypes = self.excludedActivityTypes;
            detailViewController.maxSharingFileSize = self.maxSharingFileSize;
            
            detailViewController.title = text;
            detailViewController.view.backgroundColor = self.view.backgroundColor;
            
            detailViewController.hidesBottomBarWhenPushed = self.hidesBottomBarInDetails;
            
            NSMutableArray *barButtons = [[NSMutableArray alloc] init];
            
            // additional buttons
            if ([self.showcaseView.showcaseDelegate respondsToSelector:@selector(showcaseView:barButtonItemsForItemAtIndex:)]) {
                NSArray *buttons = [self.showcaseView.showcaseDelegate showcaseView:self.showcaseView barButtonItemsForItemAtIndex:position];
                [barButtons addObjectsFromArray:buttons];
            }
            
            detailViewController.navigationItem.rightBarButtonItems = barButtons;
            
            [self.navigationController pushViewController:detailViewController animated:YES];
            
            break;
        }
            
        case PTContentTypeImage:
        {
            NSInteger relativeIndex = [self.showcaseView relativeIndexForItemAtIndex:position withContentType:contentType];
            
            PTImageAlbumViewController *detailViewController = [[PTImageAlbumViewController alloc] initWithImageAtIndex:relativeIndex];
            detailViewController.imageAlbumView.imageAlbumDataSource = self;
            detailViewController.imageAlbumView.imageAlbumDelegate = self;
            detailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            
            self.selectedNestedItemPosition = relativeIndex;
            
            UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            
            // button to close the image album
            UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissImageDetailViewController)];
            detailViewController.navigationItem.leftBarButtonItem = dismissButton;
            
            NSMutableArray *barButtons = [[NSMutableArray alloc] init];
            
            // button to share image
            if (self.activityButtonEnabled) {
                self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped)];
                [barButtons addObject:self.actionBarButtonItem];
            }
            
            // additional buttons
            if ([self.showcaseView.showcaseDelegate respondsToSelector:@selector(showcaseView:barButtonItemsForItemAtIndex:)]) {
                NSArray *buttons = [self.showcaseView.showcaseDelegate showcaseView:self.showcaseView barButtonItemsForItemAtIndex:position];
                [barButtons addObjectsFromArray:buttons];
            }
                        
            detailViewController.navigationItem.rightBarButtonItems = barButtons;
            
            // TODO zoom in/out (just like in Photos.app in the iPad)
            [self presentViewController:navCtrl animated:YES completion:NULL];
            
            break;
        }
            
        case PTContentTypeVideo:
        {
            NSString *path = [self.showcaseView pathForItemAtIndex:position];
            NSString *text = [self.showcaseView textForItemAtIndex:position];
            
            // TODO remove duplicate
            // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            NSURL *url = nil;
            
            // Check for file URLs.
            if ([path hasPrefix:@"/"]) {
                // If the url starts with / then it's likely a file URL, so treat it accordingly.
                url = [NSURL fileURLWithPath:path];
            }
            else {
                // Otherwise we assume it's a regular URL.
                url = [NSURL URLWithString:path];
            }
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            MPMoviePlayerViewController *detailViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            detailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            detailViewController.moviePlayer.controlStyle = MPMovieControlStyleDefault;
            detailViewController.title = text;
            
            UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            
            // button to close the movie player
            UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissDetailViewController)];
            detailViewController.navigationItem.leftBarButtonItem = dismissButton;
            
            NSMutableArray *barButtons = [[NSMutableArray alloc] init];
            
            // button to share image
            if (self.activityButtonEnabled) {
                self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped)];
                [barButtons addObject:self.actionBarButtonItem];
            }
            
            // additional buttons
            if ([self.showcaseView.showcaseDelegate respondsToSelector:@selector(showcaseView:barButtonItemsForItemAtIndex:)]) {
                NSArray *buttons = [self.showcaseView.showcaseDelegate showcaseView:self.showcaseView barButtonItemsForItemAtIndex:position];
                [barButtons addObjectsFromArray:buttons];
            }
            
            detailViewController.navigationItem.rightBarButtonItems = barButtons;
            
            // TODO zoom in/out (just like in Photos.app in the iPad)
            [self presentViewController:navCtrl animated:YES completion:NULL];
            
            break;
        }
            
        case PTContentTypePdf:
        {
            NSString *path = [self.showcaseView pathForItemAtIndex:position];
            NSString *text = [self.showcaseView textForItemAtIndex:position];
            
            // TODO remove duplicate
            // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            NSURL *url = nil;
            
            // Check for file URLs.
            if ([path hasPrefix:@"/"]) {
                // If the url starts with / then it's likely a file URL, so treat it accordingly.
                url = [NSURL fileURLWithPath:path];
            }
            else {
                // Otherwise we assume it's a regular URL.
                url = [NSURL URLWithString:path];
            }
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            PSPDFDocument *document = [PSPDFDocument PDFDocumentWithUrl:url];
            document.title = text;
            
            PSPDFViewController *detailViewController = [[PSPDFViewController alloc] initWithDocument:document];
            detailViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            detailViewController.backgroundColor = self.view.backgroundColor;
            
            // PSPDFKit buttons
            NSMutableArray *barButtons = [[NSMutableArray alloc] initWithObjects: detailViewController.searchButtonItem, detailViewController.outlineButtonItem, detailViewController.viewModeButtonItem, nil];
            
            // button to share image
            if (self.activityButtonEnabled) {
                self.actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonItemTapped)];
                [barButtons addObject:self.actionBarButtonItem];
            }
            
            // additional buttons
            if ([self.showcaseView.showcaseDelegate respondsToSelector:@selector(showcaseView:barButtonItemsForItemAtIndex:)]) {
                NSArray *buttons = [self.showcaseView.showcaseDelegate showcaseView:self.showcaseView barButtonItemsForItemAtIndex:position];
                [barButtons addObjectsFromArray:buttons];
            }
            
            detailViewController.navigationItem.rightBarButtonItems = barButtons;
            
            UINavigationController *navCtrl = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            
            // TODO zoom in/out (just like in Photos.app in the iPad)
            [self presentViewController:navCtrl animated:YES completion:NULL];
            
            break;
        }
            
        default: NSAssert(NO, @"Unknown content-type.");
    }
}

#pragma mark - PTImageAlbumViewDataSource

- (NSInteger)numberOfImagesInAlbumView:(PTImageAlbumView *)imageAlbumView
{
    return [self.showcaseView.imageItems count];
}

- (NSString *)imageAlbumView:(PTImageAlbumView *)imageAlbumView sourceForImageAtIndex:(NSInteger)index
{
    NSInteger i = [self.showcaseView indexForItemAtRelativeIndex:index withContentType:PTContentTypeImage];
    return [self.showcaseView pathForItemAtIndex:i];
}

- (NSString *)imageAlbumView:(PTImageAlbumView *)imageAlbumView sourceForThumbnailImageAtIndex:(NSInteger)index
{
    NSInteger i = [self.showcaseView indexForItemAtRelativeIndex:index withContentType:PTContentTypeImage];
    return [self.showcaseView sourceForThumbnailImageOfItemAtIndex:i];
}

- (NSString *)imageAlbumView:(PTImageAlbumView *)imageAlbumView captionForImageAtIndex:(NSInteger)index
{
    NSInteger i = [self.showcaseView indexForItemAtRelativeIndex:index withContentType:PTContentTypeImage];
    return [self.showcaseView detailTextForItemAtIndex:i];
}

#pragma mark - PTShowcaseViewDataSource

- (NSInteger)numberOfItemsInShowcaseView:(PTShowcaseView *)showcaseView
{
    NSAssert(NO, @"missing required method implementation 'numberOfItemsInShowcaseView:'");
    abort();
}

- (PTContentType)showcaseView:(PTShowcaseView *)showcaseView contentTypeForItemAtIndex:(NSInteger)index
{
    NSAssert(NO, @"missing required method implementation 'showcaseView:contentTypeForItemAtIndex:'");
    abort();
}

- (NSString *)showcaseView:(PTShowcaseView *)showcaseView pathForItemAtIndex:(NSInteger)index
{
    NSAssert(NO, @"missing required method implementation 'showcaseView:pathForItemAtIndex:'");
    abort();
}

#pragma mark - PTImageAlbumViewDelegate
- (void)imageAlbumView:(PTImageAlbumView *)imageAlbumView didChangeImageAtIndex:(NSInteger)index
{
    self.selectedNestedItemPosition = index;
}

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#pragma mark - Movie Player utility

- (void)dismissDetailViewController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIPopoverController and WEPopoverController delegate

- (void)popoverControllerDidDismissPopover:(NSObject *)popoverController
{
    self.activityPopoverController = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(NSObject *)popoverController
{
    return YES;
}

#pragma mark - Share utility
- (void)shareButtonItemTapped
{
    // prevent crash when tapping on bar button item and popover is already on screen
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && self.activityPopoverController != nil) {
        [self.activityPopoverController dismissPopoverAnimated:YES];
        self.activityPopoverController = nil;
        return;
    }
    
    PTContentType contentType = [self.showcaseView contentTypeForItemAtIndex:self.selectedItemPosition];    
    NSString *text = nil;
    NSString *url = nil;
    
    NSMutableArray *excludedActivities = [self.excludedActivityTypes mutableCopy];
    
    switch (contentType)
    {
        case PTContentTypeGroup:
        {
            // nothing to do
            break;
        }
            
        case PTContentTypeImage:
        {            
            // Only text and image
            NSInteger absoluteIndex = [self.showcaseView indexForItemAtRelativeIndex:self.selectedNestedItemPosition withContentType:PTContentTypeImage];
            NSString *path = [self.showcaseView pathForItemAtIndex:absoluteIndex];
            
            // check max filesize
            if ([self.showcaseView fileExceededMaxFileSize:path]) {
                return;
            }
            
            // TODO remove duplicate
            // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>            
            // Check for file URLs.
            if ([path hasPrefix:@"/"]) {
                // If the url starts with / then it's likely a file URL, so treat it accordingly.
                url = [NSURL fileURLWithPath:path];
            }
            else {
                // Otherwise we assume it's a regular URL.
                url = [NSURL URLWithString:path];
            }
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            text = [self.showcaseView detailTextForItemAtIndex:absoluteIndex] != nil
            ? [self.showcaseView detailTextForItemAtIndex:absoluteIndex]
            : [NSString string];
            
            NSLog(@"Image: %@ url: %@", text, path);
            break;
        }
            
        case PTContentTypeVideo:
        {
            NSString *path = [self.showcaseView pathForItemAtIndex:self.selectedItemPosition];
            text = [self.showcaseView textForItemAtIndex:self.selectedItemPosition];
            
            // TODO remove duplicate
            // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            // Check for file URLs.
            if ([path hasPrefix:@"/"]) {
                // If the url starts with / then it's likely a file URL, so treat it accordingly.
                url = [NSURL fileURLWithPath:path];
            }
            else {
                // Otherwise we assume it's a regular URL.
                url = [NSURL URLWithString:path];
            }
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

            // check max filesize
            if ([self.showcaseView fileExceededMaxFileSize:path]) {
                return;
            }
            
            // exclude facebook and twitter share
            [excludedActivities addObjectsFromArray:@[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter]];
            
            NSLog(@"Video: %@ url: %@", text, url);
            break;
        }
            
        case PTContentTypePdf:
        {
            NSString *path = [self.showcaseView pathForItemAtIndex:self.selectedItemPosition];
            text = [self.showcaseView textForItemAtIndex:self.selectedItemPosition];
            
            // TODO remove duplicate
            // >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>            
            // Check for file URLs.
            if ([path hasPrefix:@"/"]) {
                // If the url starts with / then it's likely a file URL, so treat it accordingly.
                url = [NSURL fileURLWithPath:path];
            }
            else {
                // Otherwise we assume it's a regular URL.
                url = [NSURL URLWithString:path];
            }
            // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            // check max filesize
            if ([self.showcaseView fileExceededMaxFileSize:path]) {
                return;
            }
            
            // exclude facebook and twitter share
            [excludedActivities addObjectsFromArray:@[ UIActivityTypePostToFacebook, UIActivityTypePostToTwitter]];
            
            NSLog(@"PDF: %@ url: %@", text, url);
            break;
        }
            
        default: NSAssert(NO, @"Unknown content-type.");
    }
    
    NSArray *items = @[ text, url ];
    
    UIActivityViewControllerCompletionHandler completitionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"Completed dialog - activity: %@ - finished flag: %d", activityType, completed);
        self.activityPopoverController = nil;
    };
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:self.applicationActivities];
    activityViewController.excludedActivityTypes = excludedActivities;
    activityViewController.completionHandler = completitionHandler;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [[self topViewController:self] presentViewController:activityViewController animated:YES completion:NULL];
    }
    else {
        self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        self.activityPopoverController.delegate = self;
        [self.activityPopoverController presentPopoverFromBarButtonItem:self.actionBarButtonItem
                                               permittedArrowDirections:UIPopoverArrowDirectionUp
                                                               animated:YES];
    }

}

#pragma mark - Private methods

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

@end
