//
//  PTBarButtonItem.h
//  igamma
//
//  Created by Alessandro Zoffoli on 22/07/13.
//  Copyright (c) 2013 Apex-net. All rights reserved.
//

#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class interface
////////////////////////////////////////////////////////////////////////////////

@interface PTBarButtonItem : UIBarButtonItem

// Bar button subclass, to manage uniqueName and index
@property (nonatomic, strong) NSString *showcaseUniqueName;
@property (nonatomic, strong) NSString *itemUniqueName;
@property (nonatomic, assign) NSUInteger index;

@end
