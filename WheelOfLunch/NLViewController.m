//
//  NLViewController.m
//  WheelOfLunch
//
//  Created by Nick Lupinetti on 7/22/12.
//  Copyright (c) 2012 Nick Lupinetti. All rights reserved.
//

#import "NLViewController.h"
#import "NLSpinWheel.h"

@interface NLViewController ()

@end


@implementation NLViewController

@synthesize spinner;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.spinner];
}

- (NLSpinWheel*)spinner {
    if (!spinner) {
        CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
        CGFloat spinnerSize = floorf(screenSize.width * 0.9);
        CGRect spinnerFrame = CGRectMake((screenSize.width - spinnerSize) / 2, (screenSize.height - spinnerSize) / 2, spinnerSize, spinnerSize);
        spinner = [[NLSpinWheel alloc] initWithFrame:spinnerFrame];
    }
    
    return spinner;
}

- (void)didReceiveMemoryWarning {
    spinner = nil;
    
    [super didReceiveMemoryWarning];
}

@end
