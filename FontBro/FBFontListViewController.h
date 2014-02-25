//
//  FBFontListViewController.h
//  FontBro
//
//  Created by Spencer Salazar on 2/24/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FBFontListViewController : NSViewController <NSTableViewDataSource>

@property NSString *text;
@property CGFloat pointSize;

@property IBOutlet NSTableView *tableView;
@property IBOutlet NSComboBox *comboBox;

- (IBAction)reload:(id)sender;

@end
