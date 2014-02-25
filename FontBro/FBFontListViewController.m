//
//  FBFontListViewController.m
//  FontBro
//
//  Created by Spencer Salazar on 2/24/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import "FBFontListViewController.h"
#import <CoreText/CoreText.h>


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

@property NSString *name;
@property NSString *family;
@property NSString *style;
@property(weak) FBFontListViewController *viewController;

@property(readonly) NSAttributedString *displayValue;
@property(readonly) CGFloat rowHeight;

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
    return 40 + self.viewController.pointSize*(1 + 1.0/6.0);
}

@end


@interface FBFontListViewController ()
{
}

- (NSAttributedString *)makeString:(CTFontDescriptorRef)desc;

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
}

- (void)dealloc
{
}

- (NSAttributedString *)makeString:(CTFontDescriptorRef)desc
{
    CFStringRef cfname = CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute);
    CFStringRef cffamily = CTFontDescriptorCopyAttribute(desc, kCTFontFamilyNameAttribute);
    CFStringRef cfstyle = CTFontDescriptorCopyAttribute(desc, kCTFontStyleNameAttribute);
    
    NSString *name = CFBridgingRelease(cfname);
    NSString *family = CFBridgingRelease(cffamily);
    NSString *style = CFBridgingRelease(cfstyle);
    
    NSFont *font = [NSFont fontWithName:name size:self.pointSize];

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - %@\n", family, style]
                                                                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:_paragraphStyle, NSParagraphStyleAttributeName,
                                                                                        nil]];
    [str appendAttributedString:[[NSAttributedString alloc] initWithString:self.text
                                                                attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                                                                            _paragraphStyle, NSParagraphStyleAttributeName,
                                                                            nil]]];
    
    return str;
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

//#pragma mark - NSTableViewDataSource
//
//- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
//{
//    return CFArrayGetCount(_fonts);
//}
//
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//    CTFontDescriptorRef desc = CFArrayGetValueAtIndex(_fonts, row);
//    return [self makeString:desc];
//}

@end
