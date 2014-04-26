//
//  FBFontListViewController.h
//  FontBro
//
//  Created by Spencer Salazar on 2/24/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FBPersistenceManager;

@interface FBFontListViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property NSString *text;
@property CGFloat pointSize;
@property NSParagraphStyle *paragraphStyle;

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSComboBox *comboBox;
@property IBOutlet NSArrayController *fonts;

@property IBOutlet NSArrayController *fontData;
@property IBOutlet FBPersistenceManager *persistenceManager;

- (IBAction)reload:(id)sender;

@end
