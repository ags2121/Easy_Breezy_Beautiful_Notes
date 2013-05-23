//
//  TDNoteListControllerViewController.h
//  Note Taking App
//
//  Created by Alex Silva on 5/22/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Dropbox/Dropbox.h>

@class TDNoteListControllerViewController;

@protocol NoteListDelegate

-(void)noteListResigned:(TDNoteListControllerViewController*)noteList withFile:(DBFile*)file;

@end

@interface TDNoteListControllerViewController : UITableViewController

- (IBAction)addNoteButtonPressed:(id)sender;
- (IBAction)cancelBtnPressed:(id)sender;

- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root;
-(void)setFilesystem:(DBFilesystem *)filesystem withRoot:(DBPath *)root;

@property (nonatomic, weak) id <NoteListDelegate> delegate;
@property (nonatomic, readonly) DBAccount *account;

@end
