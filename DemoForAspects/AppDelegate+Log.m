//
//  AppDelegate+Log.m
//  DemoForAspects
//
//  Created by luhai on 15/12/24.
//  Copyright © 2015年 Dev. All rights reserved.
//

#import "AppDelegate+Log.h"
#import "Aspects.h"
#import <objc/runtime.h>

#define GLLoggingPageImpression @"GLLoggingPageImpression"
#define GLLoggingTrackedEvents @"GLLoggingTrackedEvents"
#define GLLoggingEventName @"GLLoggingEventName"
#define GLLoggingEventSelectorName @"GLLoggingEventSelectorName"
#define GLLoggingEventHandlerBlock @"GLLoggingEventHandlerBlock"

typedef void (^AspectHandlerBlock)(id<AspectInfo> aspectInfo);
static const void *ClickTimes = &ClickTimes;

@implementation AppDelegate (Log)
@dynamic clickTimes;

- (void)initLog
{
    NSDictionary *config = @{
                             @"ViewController": @{
                                     GLLoggingPageImpression: @"page imp - main page",
                                     GLLoggingTrackedEvents: @[
                                             @{
                                                 GLLoggingEventName: @"button one clicked",
                                                 GLLoggingEventSelectorName: @"btnClick:",
                                                 GLLoggingEventHandlerBlock: ^(id<AspectInfo> aspectInfo) {
                                                     self.clickTimes++;
                                                     NSLog(@"%ld",(long)self.clickTimes);
                                                 },
                                                 }
                                             ],
                                     }
                             };
    
    [self setupWithConfiguration:config];
}

- (void)setupWithConfiguration:(NSDictionary *)configs
{
    // Hook Page Impression
    [UIViewController aspect_hookSelector:@selector(viewDidAppear:)
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo) {
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                       NSString *className = NSStringFromClass([[aspectInfo instance] class]);
                                       NSString *pageImp = configs[className][GLLoggingPageImpression];
                                       if (pageImp) {
                                           NSLog(@"%@", pageImp);
                                       }
                                   });
                               } error:NULL];
    
    // Hook Events
    for (NSString *className in configs) {
        Class clazz = NSClassFromString(className);
        NSDictionary *config = configs[className];
        
        if (config[GLLoggingTrackedEvents]) {
            for (NSDictionary *event in config[GLLoggingTrackedEvents]) {
                SEL selekor = NSSelectorFromString(event[GLLoggingEventSelectorName]);
                AspectHandlerBlock block = event[GLLoggingEventHandlerBlock];
                
                [clazz aspect_hookSelector:selekor
                               withOptions:AspectPositionAfter
                                usingBlock:^(id<AspectInfo> aspectInfo) {
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        block(aspectInfo);
                                    });
                                } error:NULL];
                
            }
        }
    }
}

-(NSInteger)clickTimes
{
    return [objc_getAssociatedObject(self, ClickTimes) intValue];
}

-(void)setClickTimes:(NSInteger)clickTimes
{
    NSNumber *number= [[NSNumber alloc] initWithInteger:clickTimes];
    objc_setAssociatedObject(self, ClickTimes, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
