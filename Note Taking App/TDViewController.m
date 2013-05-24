//
//  TDViewController.m
//  Note Taking App
//
//  Created by Alex Silva on 5/21/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "UIImage+Resize.h"
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
    
    if (!self.textViewLoaded) {
        [self reload];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
    if ( self.theFileBeingViewed != nil ){
        [self.theFileBeingViewed removeObserver:self];
        [self saveChanges];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addObserverToFile
{
    __weak TDViewController *weakSelf = self;
    [self.theFileBeingViewed addObserver:self block:^() { [weakSelf reload]; }];
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
    
    if( self.photoImageView.image ){
        UIImage *composite = [self imageByCombiningImageViewWithTextView];
        NSData *imageData = UIImagePNGRepresentation(composite);
        [self.theFileBeingViewed writeData:imageData error:nil];
    }
    else{
        [self.theFileBeingViewed writeString:self.notesTextview.text error:nil];
    }
    
    if (!self.theFileBeingViewed) {
        [self showErrorAlert:@"An error has occurred" text: @"Unable to create note"];
    }
    else{
        self.navigationItem.title = self.theFileBeingViewed.info.path.name;
        [self addObserverToFile];
    }
}

-(void)noteListResigned:(TDNoteListControllerViewController *)noteList withFile:(DBFile *)file createdNewFile:(BOOL)createdNewFile
{
    if(file && !createdNewFile){
        
        self.theFileBeingViewed = file;
        [self addObserverToFile];
        self.navigationItem.title = file.info.path.name;
        self.notesTextview.text = [self.theFileBeingViewed readString:nil];
        [self reload];
    }
    else if(createdNewFile){
        self.theFileBeingViewed = nil;
        self.photoImageView.image = nil;
        [self createAt];
        [self addObserverToFile];
        self.navigationItem.title = self.theFileBeingViewed.info.path.name;
        self.notesTextview.text = @"";
        [self.notesTextview setEditable:YES];
        self.notesTextview.userInteractionEnabled = YES;
    }
    
    else if (self.theFileBeingViewed != nil) {
        [self addObserverToFile];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)didDeleteFileAtPath:(DBFileInfo*)fileinfo
{
    if ( [fileinfo.path.name isEqualToString:self.theFileBeingViewed.info.path.name] ){
        
        self.theFileBeingViewed = nil;
        self.photoImageView.image = nil;
        [self.notesTextview setEditable:YES];
        self.notesTextview.userInteractionEnabled = YES;
    }
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

    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
#if TARGET_IPHONE_SIMULATOR
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
#else
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
    imagePickerController.editing = YES;
    imagePickerController.delegate = (id)self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];

}


#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView
{
    NSLog(@"textview did change");
	[_writeTimer invalidate];
	self.writeTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(saveChanges)
                                                     userInfo:nil repeats:NO];
}

#pragma mark - UIImagePickerController delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    // Resize the image from the camera
	UIImage *scaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(self.photoImageView.frame.size.width, self.photoImageView.frame.size.height) interpolationQuality:kCGInterpolationHigh];
    // Crop the image to a square (yikes, fancy!)
    UIImage *croppedImage = [scaledImage croppedImage:CGRectMake((scaledImage.size.width - self.photoImageView.frame.size.width)/2, (scaledImage.size.height - self.photoImageView.frame.size.height)/2, self.photoImageView.frame.size.width, self.photoImageView.frame.size.height)];
    // Show the photo on the screen
    self.photoImageView.image = croppedImage;
    
    [self addObserverToFile];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self addObserverToFile];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - private methods

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

- (void)reload {
	BOOL updateEnabled = NO;
	if (self.theFileBeingViewed.status.cached) {
		if (!_textViewLoaded) {
			_textViewLoaded = YES;
            
            NSData *data = [self.theFileBeingViewed readData:nil];
            
            //if data is a String
            if ( [TDViewController contentTypeForImageData:data] == nil) {
                NSString *contents = [self.theFileBeingViewed readString:nil];
                self.notesTextview.text = contents;
                NSLog(@"textview text: %@", self.notesTextview.text);
            }
            else{
                self.photoImageView.image = [UIImage imageWithData:data];
                self.notesTextview.text = @"";
                [self.notesTextview setEditable:NO];
                self.notesTextview.userInteractionEnabled = NO;
            }
            self.navigationItem.title = self.theFileBeingViewed.info.path.name;

		}
		
		[self.activityIndicator stopAnimating];
		self.notesTextview.hidden = NO;
		
		if (self.theFileBeingViewed.newerStatus.cached) {
			updateEnabled = YES;
		}
	} else if(self.theFileBeingViewed == nil){
        
        if(!self.photoImageView.image)
            self.notesTextview.text = @"";
        self.navigationItem.title = @"Note";
		//[self.activityIndicator startAnimating];
		//self.notesTextview.hidden = YES;
	}
	
	self.updateButton.enabled = updateEnabled;
}

- (void)saveChanges {
//	if (!_writeTimer) return;
//	[_writeTimer invalidate];
//	self.writeTimer = nil;
    
	if( self.photoImageView.image ){
        UIImage *composite = [self imageByCombiningImageViewWithTextView];
        NSData *imageData = UIImagePNGRepresentation(composite);
        [self.theFileBeingViewed writeData:imageData error:nil];
        [self.notesTextview setEditable:NO];
        self.notesTextview.userInteractionEnabled = NO;

    }
    else{
        [self.theFileBeingViewed writeString:self.notesTextview.text error:nil];
    }
    
    if(self.theFileBeingViewed)
        [self reload];
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
                    [self addObserverToFile];
                    [self reload];
                }
            }
            [self.activityIndicator stopAnimating];
		});
	});
}

- (UIImage*)imageByCombiningImageViewWithTextView
{
    
    UIGraphicsBeginImageContextWithOptions(self.photoImageView.image.size, NO, 0.0); //retina res
    [self.photoImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:self.notesTextview.text];    NSInteger _stringLength = self.notesTextview.text.length;
    [str addAttribute:NSBackgroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, _stringLength)];
    [str addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0] range:NSMakeRange(0, _stringLength)];
    
    self.notesTextview.attributedText = str;
    [self.notesTextview setNeedsDisplay];
    
    [self.notesTextview.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

@end
