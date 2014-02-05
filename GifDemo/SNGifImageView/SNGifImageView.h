//
//  SNGifImageView.h
//  GifDemo
//
//  Created by handy wang on 1/24/14.
//  Copyright (c) 2014 handy wang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^GifImageLoadComplete_blk)(void);
typedef void(^GifImageLoadFail_blk)(void);

@interface SNGifImageView : UIImageView

- (void)setImageName:(NSString *)imageName;
- (void)setImageUrl:(NSString *)imageUrl fail:(GifImageLoadFail_blk)failBlk complete:(GifImageLoadComplete_blk)completeBlk;

@end