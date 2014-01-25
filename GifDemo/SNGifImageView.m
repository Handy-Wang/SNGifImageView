//
//  SNGifImageView.m
//  GifDemo
//
//  Created by handy wang on 1/24/14.
//  Copyright (c) 2014 handy wang. All rights reserved.
//

#import "SNGifImageView.h"
#import <ImageIO/ImageIO.h>

#define DEBUG_MODE (1)
#if DEBUG_MODE
    #if TARGET_IPHONE_SIMULATOR || 1
        #define GifDebugLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
    #else
        #define GifDebugLog( s, ... ) LogMessageCompat( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
    #endif
#else
    #define GifDebugLog( s, ... ) ((void)0)
#endif

#define kRenderCountPerCycle                (50)
#define kQueueMaxSize                       (10)

#define kSigal_NO_DATA                      (0)
#define kSigal_HAS_DATA                     (1)

//##########################################################################################
//#################################### SNGifImage ##########################################
//##########################################################################################
@interface SNGifImage : NSObject

@property (nonatomic, retain)UIImage *content;
@property (nonatomic, assign)NSTimeInterval delayTime;

@end

@implementation SNGifImage

- (void)dealloc {
    CGImageRef imgRef = _content.CGImage;
    CFRelease(imgRef);
    self.content = nil;
    self.delayTime = 0;
    
    [super dealloc];
}

@end

//##########################################################################################
//############################## SNGifImageKeyFramesQueue ##################################
//##########################################################################################
@interface SNGifImageKeyFramesQueue : NSObject

@property (atomic, retain)NSMutableArray *queueContent;
@property (nonatomic, retain)NSLock *synchronizedLock;

@end

@implementation SNGifImageKeyFramesQueue

- (id)init {
    self = [super init];
    if (self) {
        self.queueContent = [NSMutableArray array];
        _synchronizedLock = [[NSLock alloc] init];
    }
    return self;
}

- (int)count {
    [_synchronizedLock lock];
    int ___count = [self.queueContent count];
    [_synchronizedLock unlock];
    return ___count;
}

- (void)enqueue:(SNGifImage *)image {
    if (!image) {
        return;
    }
    
    [_synchronizedLock lock];
    [self.queueContent addObject:image];
    [_synchronizedLock unlock];
}

- (SNGifImage *)dequeue {
    [_synchronizedLock lock];
    
    SNGifImage *img = nil;
    if (self.queueContent.count > 0) {
        SNGifImage *tempImg = [self.queueContent objectAtIndex:0];
        
        img = [[SNGifImage alloc] init];
        img.content = tempImg.content;
        img.delayTime = tempImg.delayTime;
        
        [self.queueContent removeObjectAtIndex:0];
    }
    
    [_synchronizedLock unlock];
    
    return [img autorelease];
}

- (void)clearAll {
    [_synchronizedLock lock];
    [self.queueContent removeAllObjects];
    [_synchronizedLock unlock];
}

- (void)dealloc {
    [self clearAll];
    self.queueContent = nil;
    [super dealloc];
}
@end

//##########################################################################################
//############################## SNGifImageKeyFrameProducer ################################
//##########################################################################################
@interface SNGifImageKeyFrameProducer : NSObject
@property (nonatomic, retain)SNGifImageKeyFramesQueue *queue;
@property (nonatomic, retain)NSConditionLock *conditionLock;

//gif加载环境
@property (nonatomic, retain)NSData *data;
@property (nonatomic, assign)CGImageSourceRef source;
@property (nonatomic, assign)size_t dataFrameCount;
@end

@implementation SNGifImageKeyFrameProducer

- (id)initWithSharedQueue:(SNGifImageKeyFramesQueue *)queue sharedConditionLock:(NSConditionLock *)lock {
    self = [super init];
    if (self) {
        self.queue = queue;
        self.conditionLock = lock;
        
        //初始化gif加载环境
        NSString *path = [[NSBundle mainBundle] pathForResource:@"iwatch" ofType:@"gif"];
        self.data = [NSData dataWithContentsOfFile:path];
        
        if (self.data) {
            self.source = CGImageSourceCreateWithData((__bridge CFDataRef)self.data, NULL);
            self.dataFrameCount = CGImageSourceGetCount(self.source);
        }
    }
    return self;
}

- (void)dealloc {
    self.queue = nil;
    self.conditionLock = nil;
    
    self.data = nil;
    CFRelease(self.source);
    
    [super dealloc];
}

- (void)produceInThread {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int index = 0;
//        while (index < self.dataFrameCount) {
        while (true) {
            GifDebugLog(@"Before Produce condition lock : %d", self.conditionLock.condition);
            [self.conditionLock lockWhenCondition:kSigal_NO_DATA];
            
            GifDebugLog(@"Producing %d", index);
            SNGifImage *keyFrame = [self loadAGifKeyFrameFromSourceWithIndex:index];
            [self.queue enqueue:keyFrame];
            index ++;
            
            [self.conditionLock unlockWithCondition:kSigal_HAS_DATA];
            GifDebugLog(@"After Produce condition lock : %d", self.conditionLock.condition);
        }
    });
}

- (SNGifImage *)loadAGifKeyFrameFromSourceWithIndex:(int)index {
    index = index%self.dataFrameCount;
    if (!(self.data) || self.dataFrameCount <= 0 || index > self.dataFrameCount) {
        return nil;
    }
    
    SNGifImage *gifImage = [[SNGifImage alloc] init];
    
    CGImageRef image = CGImageSourceCreateImageAtIndex(self.source, index, NULL);
    gifImage.content = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    
    CGImageRelease(image);
    
    NSDictionary *frameProperties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(self.source, index, NULL));
    NSTimeInterval duration = [[[frameProperties objectForKey:(NSString*)kCGImagePropertyGIFDictionary] objectForKey:(NSString*)kCGImagePropertyGIFDelayTime] doubleValue];
    if (!duration) {
        duration = 1.0f/10.0f;//(十分之一秒)
    }
    gifImage.delayTime = duration;
    
    return [gifImage autorelease];
}

@end

//##########################################################################################
//############################## SNGifImageKeyFrameConsumer ################################
//##########################################################################################
@interface SNGifImageKeyFrameConsumer : NSObject
@property (nonatomic, retain)SNGifImageKeyFramesQueue *queue;
@property (nonatomic, retain)NSConditionLock *conditionLock;
@property (nonatomic, assign)SNGifImageView *imageView;
@end

@implementation SNGifImageKeyFrameConsumer

- (id)initWithSharedQueue:(SNGifImageKeyFramesQueue *)queue sharedConditionLock:(NSConditionLock *)lock imageView:(SNGifImageView *)imageView {
    self = [super init];
    if (self) {
        self.queue = queue;
        self.conditionLock = lock;
        self.imageView = imageView;
    }
    return self;
}

- (void)consumeInThread {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            @autoreleasepool {
//                NSDate *past = (NSDate *)[NSDate date];
                
                SNGifImage *gifImage = [self.queue dequeue];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    GifDebugLog(@"Before Consume condition lock : %d", self.conditionLock.condition);
                    
                    [self.conditionLock lockWhenCondition:kSigal_HAS_DATA];
                    GifDebugLog(@"Consuming...");

                    self.imageView.image = gifImage.content;
                    
                    [self.conditionLock unlockWithCondition:kSigal_NO_DATA];
                    GifDebugLog(@"After Consume condition lock : %d", self.conditionLock.condition);
                });
                
                /**
                 * 因为按实际的时长gifImage.delayTime发现偏慢，可能是因为sleepForTimeInterval有延迟，所以减去0.62
                 */
                double detlayDuration = gifImage.delayTime-0.062;
                
                [NSThread sleepForTimeInterval:detlayDuration];
                
//                NSTimeInterval codeExcutionCost = [(NSDate *)[NSDate date] timeIntervalSinceDate:past];
//                NSTimeInterval originalDelayTime = gifImage.delayTime;
//
//                if (originalDelayTime > codeExcutionCost) {
//                    NSTimeInterval finalDelayTime = originalDelayTime-codeExcutionCost;
//                    [NSThread sleepForTimeInterval:finalDelayTime];
//                }
//                else {
//                    [NSThread sleepForTimeInterval:originalDelayTime];
//                }
            }
        }
    });
}

- (void)dealloc {
    self.queue = nil;
    self.conditionLock = nil;
    self.imageView = nil;
    [super dealloc];
}

@end

//##########################################################################################
//################################# SNGifImageView #########################################
//##########################################################################################
@interface SNGifImageView()

@property (nonatomic, retain)NSConditionLock *conditionLock;
@property (nonatomic, retain)SNGifImageKeyFramesQueue *queue;
@property (nonatomic, retain)SNGifImageKeyFrameProducer *producer;
@property (nonatomic, retain)SNGifImageKeyFrameConsumer *consumer;

@end

@implementation SNGifImageView

#pragma mark - Lifecycle
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeCenter;
        
        _conditionLock = [[NSConditionLock alloc] initWithCondition:kSigal_NO_DATA];
        _queue = [[SNGifImageKeyFramesQueue alloc] init];
        _producer = [[SNGifImageKeyFrameProducer alloc] initWithSharedQueue:_queue sharedConditionLock:_conditionLock];
        _consumer = [[SNGifImageKeyFrameConsumer alloc] initWithSharedQueue:_queue sharedConditionLock:_conditionLock imageView:self];
    }
    return self;
}

- (void)dealloc {
    self.conditionLock = nil;
    [self.queue clearAll];
    self.queue = nil;
    self.producer = nil;
    self.consumer = nil;
    
    [super dealloc];
}

#pragma mark -
- (void)layout {
    [self.producer produceInThread];
    [self.consumer consumeInThread];
}

@end
