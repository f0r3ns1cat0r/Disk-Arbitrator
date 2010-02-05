//
//  DiskArbitratorAppController.m
//  DiskArbitrator
//
//  Created by Aaron Burghardt on 1/10/10.
//  Copyright 2010 Aaron Burghardt. All rights reserved.
//

#import "DiskArbitratorAppController.h"
#import "Arbitrator.h"
#import "Disk.h"

@implementation AppController

@synthesize window;
@synthesize statusMenu;
@synthesize tableView;
@synthesize disksArrayController;
@synthesize sortDescriptors;
@synthesize statusItem;
@synthesize arbitrator;

- (void)dealloc
{
	if (arbitrator.isActivated)
		[arbitrator deactivate];
	[arbitrator release];
	[sortDescriptors release];
	[statusItem release];
	[super dealloc];
}

- (void)setStatusItemIconWithName:(NSString *)name
{
	NSString *iconPath = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
	NSImage *statusIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
	[statusItem setImage:statusIcon];
	[statusIcon release];
}

- (void)refreshStatusItemIcon
{
	if (arbitrator.isActivated == NO)
		[self setStatusItemIconWithName:@"StatusItem Disabled 1"];
	
	else if (arbitrator.mountMode == MM_BLOCK)
		[self setStatusItemIconWithName:@"StatusItem Green"];

	else if (arbitrator.mountMode == MM_READONLY)
		[self setStatusItemIconWithName:@"StatusItem Orange"];
	
	else
		NSAssert1(NO, @"Invalid mount mode: %d\n", arbitrator.mountMode);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	// Insert code here to initialize your application 
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	self.statusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
	[self setStatusItemIconWithName:@"StatusItem Disabled 1"];
	[statusItem setMenu:statusMenu];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(diskDidChange:) name:DADiskDidChangeNotification object:nil];
	
	self.arbitrator = [Arbitrator new];
	[arbitrator addObserver:self forKeyPath:@"isActivated" options:0 context:NULL];
	[arbitrator addObserver:self forKeyPath:@"mountMode" options:0 context:NULL];
	arbitrator.isActivated = YES;
	[arbitrator release];
	
	self.sortDescriptors = [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"BSDName" ascending:YES] autorelease]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == arbitrator)
		if ([keyPath isEqual:@"isActivated"] || [keyPath isEqual:@"mountMode"])
			[self refreshStatusItemIcon];
}

- (IBAction)showMainWindow:(id)sender
{
//	[NSApp showWindow:window];
	[window orderFront:sender];
}

- (IBAction)performActivation:(id)sender
{
	[arbitrator activate];
}

- (IBAction)performDeactivation:(id)sender
{
	[arbitrator deactivate];
}

- (IBAction)toggleActivation:(id)sender
{
	if (arbitrator.isActivated)
		[self performDeactivation:sender];
	else
		[self performActivation:sender];
}

- (IBAction)performSetMountBlockMode:(id)sender
{
	arbitrator.mountMode = MM_BLOCK;
}

- (IBAction)performSetMountReadOnlyMode:(id)sender
{
	arbitrator.mountMode = MM_READONLY;
}


#pragma mark TableView Delegates

// A custom cell is used for the media description column.  Couldn't find a way to bind it to the disk
// object, so implemented the dataSource delegate.

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)column row:(int)rowIndex
{
    Disk *disk;
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [arbitrator.disks count]);
    disk = [[disksArrayController arrangedObjects] objectAtIndex:rowIndex];

	if ([[column identifier] isEqual:@"BSDName"])
		return disk.BSDName;

	//	fprintf(stdout, "getting value: %s\n", [disk.BSDName UTF8String]);
	return disk;
}

- (void)diskDidChange:(NSNotification *)notif
{
	NSUInteger row = [[disksArrayController arrangedObjects] indexOfObject:[notif object]];
	
	[tableView setNeedsDisplayInRect:[tableView rectOfRow:row]];
}

@end
