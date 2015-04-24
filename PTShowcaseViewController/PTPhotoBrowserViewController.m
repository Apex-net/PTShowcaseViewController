//
//  PTPhotoBrowserViewController.m
//  igamma
//
//  Created by Andrea Calisesi on 24/04/15.
//  Copyright (c) 2015 Apex-net. All rights reserved.
//

#import "PTPhotoBrowserViewController.h"

@interface PTPhotoBrowserViewController ()

@end

@implementation PTPhotoBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // UI adjustements
    if (self.navigationItem.rightBarButtonItem) {
        // remove right done button
        //UIBarButtonItem *dismissButton = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // Add additional buttons
    if (self.additionalBarButtonItems) {
        self.navigationItem.rightBarButtonItems = self.additionalBarButtonItems;
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
