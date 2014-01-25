//
//  ViewController.m
//  GifDemo
//
//  Created by handy wang on 1/23/14.
//  Copyright (c) 2014 handy wang. All rights reserved.
//

#import "ViewController.h"
#import "SNGifImageView.h"
#import <ImageIO/ImageIO.h>


#define kRenderCountPerCycle                (5)

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SNGifImageView *gifImageView = [[SNGifImageView alloc] initWithFrame:self.view.bounds];
    [gifImageView setImageName:@"iwatch.gif"];
    [self.view addSubview:gifImageView];
    [gifImageView release];
    gifImageView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end