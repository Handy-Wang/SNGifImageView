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

    /* Sample code
    SNGifImageView *gifImageView = [[SNGifImageView alloc] initWithFrame:self.view.bounds];
    [gifImageView setImageName:@"iwatch.gif"];
    [self.view addSubview:gifImageView];
    [gifImageView release];
    gifImageView = nil;
    
    SNGifImageView *gifImageView = [[SNGifImageView alloc] initWithFrame:self.view.bounds];
    [gifImageView setImageUrl:@"http://cdn.duitang.com/uploads/item/201209/05/20120905104848_Bh3BR.thumb.600_0.gif"];
    [self.view addSubview:gifImageView];
    [gifImageView release];
    gifImageView = nil;
     */
    
    SNGifImageView *gifImageView = [[SNGifImageView alloc] initWithFrame:self.view.bounds];
    [gifImageView setImageUrl:@"http://cdn.duitang.com/uploads/item/201209/05/20120905104848_Bh3BR.thumb.600_0.gif"];
    [self.view addSubview:gifImageView];
    [gifImageView release];
    gifImageView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end