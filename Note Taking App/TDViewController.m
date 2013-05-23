//
//  TDViewController.m
//  Note Taking App
//
//  Created by Alex Silva on 5/21/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "TDViewController.h"
#import "TDNoteListControllerViewController.h"
#import "TDLinkToDropboxView.h"

@interface TDViewController ()

@property (nonatomic, strong) UIView *inputAccessoryView;
@property (nonatomic, strong) TDLinkToDropboxView *linkToDropboxView;
@property (nonatomic, strong) DBFilesystem *fileSystem;
@property (nonatomic, strong) DBFile *theFileBeingViewed;
@property (nonatomic, assign) BOOL textViewLoaded;
@property (nonatomic, retain) NSTimer *writeTimer;

@end

@implementation TDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.activityIndicator startAnimating];
    
	DBAccount *account = [[DBAccountManager sharedManager].linkedAccounts objectAtIndex:0];
	if (!account) {
        [self showOptionToLinkAccount];
	}

    [self setInputAccessoryView];
    [self setFileSystem];
    [self openFirstNoteIfThereIsOne];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    DBFileInfo *info = [self.fileSystem fileInfoForPath:self.theFileBeingViewed.info.path error:nil];
    if(!info){
        self.theFileBeingViewed = nil;
        self.textViewLoaded = NO;
    }


    if ([self.theFileBeingViewed observationInfo] == nil){
        __weak TDViewController *weakSelf = self;
        [self.theFileBeingViewed addObserver:self block:^() { [weakSelf reload]; }];
    }
    
    if (!self.textViewLoaded) {
        [self reload];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
    if ([self.theFileBeingViewed observationInfo] != nil)
        [self.theFileBeingViewed removeObserver:self];
	[self saveChanges];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"segue happening");
    
    UINavigationController *navController = segue.destinationViewController;
    
    TDNoteListControllerViewController *nlvc = (TDNoteListControllerViewController*)navController.topViewController;
    nlvc.delegate = self;
    [nlvc setFilesystem:self.fileSystem withRoot:[DBPath root]];
    
}

- (IBAction)updateButtonPressed:(id)sender
{
    [self.theFileBeingViewed update:nil];
	_textViewLoaded = NO;
	[self reload];
}

- (IBAction)listOfNotesBtnPressed:(id)sender
{
    NSLog(@"segue happening");
    
    //if user tried to navigate to note list before saving a draft
    if(!self.theFileBeingViewed && self.notesTextview.text.length > 0){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create a note?" message:@"If you don't save your notes will be discarded." delegate:self
                                                  cancelButtonTitle:@"Cancel" otherButtonTitles:@"Create", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        alertView.tag = 100;
        [alertView show];
    }
    else{
        [self performSegueWithIdentifier:@"segueToNotes" sender:self];
    }
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex) {
        [self createAt];
	}
    [self.notesTextview resignFirstResponder];
    
    if (alertView.tag==100) {
        [self performSegueWithIdentifier:@"segueToNotes" sender:self];
    }
}

-(void)didPressLinkToAccountBtn:(TDLinkToDropboxView*)dropboxView
{
    //begins process for linking to accounts
   [[DBAccountManager sharedManager] linkFromController:self];
    //remove showOptionToLink view
    [self.linkToDropboxView removeFromSuperview];
    self.linkToDropboxView = nil;
}

-(void)showOptionToLinkAccount
{
    self.linkToDropboxView = [[[NSBundle mainBundle] loadNibNamed:@"TDLinkToDropboxView" owner:self options:nil] objectAtIndex:0];
    self.linkToDropboxView.delegate = self;
    self.linkToDropboxView.frame = self.view.frame;
    self.linkToDropboxView.center = self.view.center;
    [self.view addSubview:self.linkToDropboxView];
    //self.noDataViewShowing = YES;
}

- (void)createAt
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MM-yyyy"];
    NSString *theDate = [format stringFromDate:[NSDate date]];
    NSString *noteFilename = [NSString stringWithFormat:@"%@.txt", theDate];
    DBPath *path = [[DBPath root] childPath:noteFilename];
    self.theFileBeingViewed = [self.fileSystem createFile:path error:nil];
    
    [self.theFileBeingViewed writeString:self.notesTextview.text error:nil];
    
    if (!self.theFileBeingViewed) {
        [self showErrorAlert:@"An error has occurred" text: @"Unable to create note"];
    }
    else{
        self.navigationItem.title = [self.theFileBeingViewed.info.path.stringValue substringFromIndex:1];
    }
}

-(void)noteListResigned:(TDNoteListControllerViewController *)noteList withFile:(DBFile *)file
{
    if(file){
        self.theFileBeingViewed = file;
        
        self.navigationItem.title = [file.info.path.stringValue substringFromIndex:1];
        self.notesTextview.text = [self.theFileBeingViewed readString:nil];
        [self reload];
    }
                                     
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)setInputAccessoryView
{
    UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    keyboardToolbar.barStyle = UIBarStyleBlackTranslucent;
    keyboardToolbar.tintColor = [UIColor darkGrayColor];
    
    UIBarButtonItem* photoBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhoto)];

    UIBarButtonItem* flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveNote)];
    
    [keyboardToolbar setItems:[NSArray arrayWithObjects: photoBtn, flexSpace, doneButton, nil] animated:NO];
    
    [self.notesTextview setInputAccessoryView:keyboardToolbar];
}

#pragma mark - Accessory View Button Selectors

-(void)saveNote
{
    if(!self.theFileBeingViewed){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create a note?" message:nil delegate:self
                                                  cancelButtonTitle:@"No" otherButtonTitles:@"Create", nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;
        [alertView show];
    }
    else{
        [self saveChanges];
        [self.notesTextview resignFirstResponder];
    }
}

-(void)takePhoto
{
    
}

-(void)setFileSystem
{
    if(!self.fileSystem){
        DBAccount *account = [[DBAccountManager sharedManager].linkedAccounts objectAtIndex:0];
        self.fileSystem = [[DBFilesystem alloc] initWithAccount:account];
    }
}

-(void)showErrorAlert:(NSString*)title text:(NSString*)msg
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [av show];
}

#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"textview did change");
	[_writeTimer invalidate];
	self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(saveChanges)
                                                     userInfo:nil repeats:NO];
}


#pragma mark - private methods

- (void)reload {
	BOOL updateEnabled = NO;
	if (self.theFileBeingViewed.status.cached) {
		if (!_textViewLoaded) {
			_textViewLoaded = YES;
			NSString *contents = [self.theFileBeingViewed readString:nil];
            
            self.navigationItem.title = [self.theFileBeingViewed.info.path.stringValue substringFromIndex:1];
			self.notesTextview.text = contents;
            NSLog(@"textview text: %@", self.notesTextview.text);
		}
		
		[self.activityIndicator stopAnimating];
		self.notesTextview.hidden = NO;
		
		if (self.theFileBeingViewed.newerStatus.cached) {
			updateEnabled = YES;
		}
	} else if(self.theFileBeingViewed == nil){
        self.notesTextview.text = @"";
        self.navigationItem.title = @"Note";
		//[self.activityIndicator startAnimating];
		//self.notesTextview.hidden = YES;
	}
	
	self.updateButton.enabled = updateEnabled;
}

- (void)saveChanges {
	if (!_writeTimer) return;
	[_writeTimer invalidate];
	self.writeTimer = nil;
	
	[self.theFileBeingViewed writeString:self.notesTextview.text error:nil];
}

- (void)openFirstNoteIfThereIsOne
{
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
		NSArray *immContents = [self.fileSystem listFolder: [DBPath root] error:nil];
		NSMutableArray *mContents = [NSMutableArray arrayWithArray:immContents];
        [mContents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj2 path] compare:[obj1 path]];
        }];
		dispatch_async(dispatch_get_main_queue(), ^() {
			if (self.theFileBeingViewed == nil && mContents.count > 0) {
                DBFileInfo *firstNote = mContents[0];
                DBFile *file = [self.fileSystem openFile:firstNote.path error:nil];
                if (file) {
                    self.theFileBeingViewed = file;
                    [self reload];
                }
                [self.activityIndicator stopAnimating];
            }
		});
	});
}

@end
