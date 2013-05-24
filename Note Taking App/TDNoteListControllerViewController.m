//
//  TDNoteListControllerViewController.m
//  Note Taking App
//
//  Created by Alex Silva on 5/22/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "TDNoteListControllerViewController.h"
#import "Util.h"

@interface TDNoteListControllerViewController ()<UIActionSheetDelegate>

@property (nonatomic, retain) DBFilesystem *filesystem;
@property (nonatomic, retain) DBPath *root;
@property (nonatomic, retain) NSMutableArray *contents;
@property (nonatomic, assign) BOOL creatingFolder;
@property (nonatomic, retain) DBPath *fromPath;
@property (nonatomic, assign) BOOL loadingFiles;
@property (nonatomic, assign, getter=isMoving) BOOL moving;

@end

@implementation TDNoteListControllerViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (id)initWithFilesystem:(DBFilesystem *)filesystem root:(DBPath *)root
{
	if ((self = [super init])) {
		self.filesystem = filesystem;
		self.root = root;
		self.navigationItem.title = [root isEqual:[DBPath root]] ? @"Dropbox" : [root name];
	}
	return self;
}

//Use this method to create other directories.
-(void)setFilesystem:(DBFilesystem *)filesystem withRoot:(DBPath *)root
{
    self.filesystem = filesystem;
    self.root = root;
    self.navigationItem.title = [root isEqual:[DBPath root]] ? @"Dropbox" : [root name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
	__weak TDNoteListControllerViewController *weakSelf = self;
	[_filesystem addObserver:self block:^() { [weakSelf reload]; }];
	[_filesystem addObserver:self forPathAndChildren:self.root block:^() { [weakSelf loadFiles]; }];
	[self.navigationController setToolbarHidden:NO];
	[self loadFiles];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[_filesystem removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - IB Actions
- (IBAction)addNoteButtonPressed:(id)sender
{
    // if there are no saved notes in the directory OR if the date of the most recent file is NOT the same
    // as todays date, then we'll allow the user to create a new file
    if (self.contents.count == 0 ||
        ![ [(DBFileInfo*)self.contents[0] path].name isEqualToString: [self todaysFormattedDate] ] ) {
        
        [self.delegate noteListResigned:self withFile:nil createdNewFile:YES];

    }
    else{
        [self showErrorAlert:@"You already have a note created for today." text: @"Please add notes to an existing day."];
    }
}

- (IBAction)cancelBtnPressed:(id)sender
{
    [self.delegate noteListResigned:self withFile:nil createdNewFile:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.contents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
    
	DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
	cell.textLabel.text = [info.path name];
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
	DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
	if ([_filesystem deletePath:info.path error:nil]) {
		[_contents removeObjectAtIndex:[indexPath row]];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.delegate didDeleteFileAtPath:info];
	} else {
		[self showErrorAlert:@"Error" text: @"There was an error deleting that file."];
	}
    [self reload];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DBFileInfo *info = [_contents objectAtIndex:[indexPath row]];
    
    DBError *error = [[DBError alloc] init];
    DBFile *file = [_filesystem openFile:info.path error:&error];
    if (!file) {
        NSLog(@"error: %@", error.userInfo[@"desc"]);
        
        if ([self string:error.userInfo[@"desc"] contains:@"open"])
            [self.delegate noteListResigned:self withFile:nil createdNewFile:NO];
        else{

            [self showErrorAlert:@"Error" text:@"There was an error opening your note"];
            return;
        }
    }
    else{
        [self.delegate noteListResigned:self withFile:file createdNewFile:NO];
    }
}

- (void)reload
{
    [self.tableView reloadData];
}

- (void)loadFiles
{
	if (_loadingFiles) return;
	_loadingFiles = YES;
    
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
		NSArray *immContents = [_filesystem listFolder:_root error:nil];
		NSMutableArray *mContents = [NSMutableArray arrayWithArray:immContents];
		[mContents sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj2 path] compare:[obj1 path]];
        }];
		dispatch_async(dispatch_get_main_queue(), ^() {
			self.contents = mContents;
			_loadingFiles = NO;
			[self reload];
		});
	});
}

-(void)showErrorAlert:(NSString*)title text:(NSString*)msg
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [av show];
}

-(BOOL)string:(NSString*)string contains:(NSString*)otherString
{
    NSRange isRange = [string rangeOfString:otherString options:NSCaseInsensitiveSearch];
    return isRange.location != NSNotFound;
}
    
-(NSString*)todaysFormattedDate
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"dd-MM-yyyy"];
    NSString *theDate = [format stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"%@.txt", theDate];
}



@end
