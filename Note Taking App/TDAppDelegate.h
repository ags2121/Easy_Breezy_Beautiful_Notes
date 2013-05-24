//
//  TDAppDelegate.h
//  Note Taking App
//
//  Created by Alex Silva on 5/21/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <EventKit/EventKit.h>
#import <UIKit/UIKit.h>

@interface TDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSDateFormatter *aDateFormatter;
@property (strong, nonatomic) EKEventStore *eventStore;
+ (TDAppDelegate *)sharedDelegate;

@end
