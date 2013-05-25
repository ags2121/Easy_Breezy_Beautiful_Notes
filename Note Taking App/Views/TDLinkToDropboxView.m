//
//  TDLinkToDropboxView.m
//  Note Taking App
//
//  Created by Alex Silva on 5/22/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "TDLinkToDropboxView.h"

@implementation TDLinkToDropboxView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (IBAction)accountBtnPressed:(id)sender
{
    [self.delegate didPressLinkToAccountBtn:self];
}

@end
