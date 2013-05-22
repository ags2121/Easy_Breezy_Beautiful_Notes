//
//  TDLinkToDropboxView.h
//  Note Taking App
//
//  Created by Alex Silva on 5/22/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TDLinkToDropboxView;

@protocol LinkToDropBoxViewDelegate

-(void)didPressLinkToAccountBtn:(TDLinkToDropboxView*)dropboxView;

@end

@interface TDLinkToDropboxView : UIView

@property (nonatomic, weak) id <LinkToDropBoxViewDelegate> delegate;
- (IBAction)accountBtnPressed:(id)sender;

@end
