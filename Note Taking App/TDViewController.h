//
//  TDViewController.h
//  Note Taking App
//
//  Created by Alex Silva on 5/21/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDLinkToDropboxView.h"
#import "TDNoteListControllerViewController.h"

@interface TDViewController : UIViewController<LinkToDropBoxViewDelegate, NoteListDelegate, UITextViewDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *notesTextview;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *updateButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *listOfNotesBtn;

- (IBAction)updateButtonPressed:(id)sender;
- (IBAction)listOfNotesBtnPressed:(id)sender;

@end
