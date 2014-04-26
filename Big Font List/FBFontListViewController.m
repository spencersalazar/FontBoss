//
//  FBFontListViewController.m
//  FontBro
//
//  Created by Spencer Salazar on 2/24/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import "FBFontListViewController.h"
#import <CoreText/CoreText.h>
#import "FBPersistenceManager.h"


int rankStyle(CFStringRef style)
{
    if(CFStringCompare(style, CFSTR("Regular"), 0) == kCFCompareEqualTo)
        return 0;
    if(CFStringCompare(style, CFSTR("Plain"), 0) == kCFCompareEqualTo)
        return 0;
    if(CFStringCompare(style, CFSTR("Normal"), 0) == kCFCompareEqualTo)
        return 0;
    if(CFStringCompare(style, CFSTR("Italic"), 0) == kCFCompareEqualTo)
        return 1;
    if(CFStringCompare(style, CFSTR("Bold"), 0) == kCFCompareEqualTo)
        return 2;
    if(CFStringCompare(style, CFSTR("Bold Italic"), 0) == kCFCompareEqualTo)
        return 3;
    return INT_MAX;
}


CFComparisonResult sortDescriptorsCallback(CTFontDescriptorRef first, CTFontDescriptorRef second, void *refCon)
{
    CFStringRef family1 = CTFontDescriptorCopyAttribute(first, kCTFontFamilyNameAttribute);
    CFStringRef family2 = CTFontDescriptorCopyAttribute(second, kCTFontFamilyNameAttribute);
    
    CFComparisonResult result = CFStringCompare(family1, family2, 0);
    
    if(result == kCFCompareEqualTo)
    {
        CFStringRef style1 = CTFontDescriptorCopyAttribute(first, kCTFontStyleNameAttribute);
        CFStringRef style2 = CTFontDescriptorCopyAttribute(second, kCTFontStyleNameAttribute);
        
        int rank1 = rankStyle(style1);
        int rank2 = rankStyle(style2);
        
        if(rank1 < rank2)
            result = kCFCompareLessThan;
        else if(rank1 > rank2)
            result = kCFCompareGreaterThan;
        else
            result = kCFCompareEqualTo;
    }
    
    CFRelease(family1);
    CFRelease(family2);
    
    return result;
}

@interface FBFontListItem : NSObject

@property(nonatomic) NSString *name;
@property(nonatomic) NSString *family;
@property(nonatomic) NSString *style;
@property(nonatomic) BOOL isFavorite;
@property(nonatomic, weak) FBFontListViewController *viewController;

@property(nonatomic, readonly) NSAttributedString *displayValue;
@property(nonatomic, readonly) CGFloat rowHeight;

//- (NSAttributedString *)displayValue;
//- (NSString *)displayValue2;

@end

@implementation FBFontListItem

- (NSAttributedString *)displayValue
{
    NSFont *font = [NSFont fontWithName:self.name size:self.viewController.pointSize];
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - %@\n", self.family, self.style]
                                                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:self.viewController.paragraphStyle, NSParagraphStyleAttributeName,
                                                                                        nil]];
    [str appendAttributedString:[[NSAttributedString alloc] initWithString:self.viewController.text
                                                                attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                                                                            self.viewController.paragraphStyle, NSParagraphStyleAttributeName,
                                                                            nil]]];
    
    return str;
}

- (CGFloat)rowHeight
{
    return [self.viewController tableView:nil heightOfRow:0];
}

- (BOOL)isFavorite
{
    NSManagedObjectContext *context = self.viewController.persistenceManager.managedObjectContext;
    NSManagedObjectModel *model = self.viewController.persistenceManager.managedObjectModel;
    
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"NameRequest"
                                                substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:self.name, @"NAMEVAR", nil]];
    
    NSArray *fetch = [context executeFetchRequest:request error:NULL];
    
    if([fetch count])
    {
        NSManagedObject *object = [fetch objectAtIndex:0];
        return [object.isFavorite boolValue];
    }
    
    return NO;
}

- (void)setIsFavorite:(BOOL)isFavorite
{
    NSManagedObjectContext *context = self.viewController.persistenceManager.managedObjectContext;
    NSManagedObjectModel *model = self.viewController.persistenceManager.managedObjectModel;
    
    NSFetchRequest *request = [model fetchRequestFromTemplateWithName:@"NameRequest"
                                                substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:self.name, @"NAMEVAR", nil]];
    
    NSArray *fetch = [context executeFetchRequest:request error:NULL];
    
    if([fetch count])
    {
        NSManagedObject *object = [fetch objectAtIndex:0];
        object.isFavorite = [NSNumber numberWithBool:isFavorite];
    }
    else
    {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Font"
                                                                inManagedObjectContext:context];
        object.name = self.name;
        object.isFavorite = [NSNumber numberWithBool:isFavorite];
    }
    
    [context save:NULL];
}

@end


@interface FBFontListViewController ()

@end

@implementation FBFontListViewController

- (void)awakeFromNib
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.headIndent = 8;
    paragraphStyle.firstLineHeadIndent = 8;
    paragraphStyle.lineSpacing = 4;
    
    self.paragraphStyle = paragraphStyle;
    
    [self.comboBox addItemsWithObjectValues:@[@8, @9, @10, @12, @14, @16, @18, @24, @36, @72, @96, @120]];
    
    self.text = @"The quick brown fox jumped over the lazy dog.";
    self.pointSize = 24;

    // load fonts
    
    CFDictionaryRef dict = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
    CTFontCollectionRef collection = CTFontCollectionCreateFromAvailableFonts(dict);
    CFArrayRef cffonts = CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(collection, sortDescriptorsCallback, NULL);
    
    CFRelease(dict);
    
    long len = CFArrayGetCount(cffonts);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:len];
    for(int i = 0; i < len; i++)
    {
        FBFontListItem *item = [FBFontListItem new];
        
        CTFontDescriptorRef desc = CFArrayGetValueAtIndex(cffonts, i);
        
        CFStringRef cfname = CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute);
        CFStringRef cffamily = CTFontDescriptorCopyAttribute(desc, kCTFontFamilyNameAttribute);
        CFStringRef cfstyle = CTFontDescriptorCopyAttribute(desc, kCTFontStyleNameAttribute);
        
        item.name = CFBridgingRelease(cfname);
        item.family = CFBridgingRelease(cffamily);
        item.style = CFBridgingRelease(cfstyle);
        item.viewController = self;

        [array addObject:item];
    }
    
    [self.fonts addObjects:array];
    
    CFRelease(collection);
    CFRelease(cffonts);
    
    [self.tableView sizeLastColumnToFit];
}

- (void)dealloc
{
}

#pragma mark - IBActions

- (IBAction)reload:(id)sender
{
    [self.tableView reloadData];
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 40 + self.pointSize*(1 + 1.0/6.0);
}

@end
