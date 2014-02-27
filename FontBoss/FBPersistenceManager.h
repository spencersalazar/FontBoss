//
//  FBPersistenceManager.h
//  FontBoss
//
//  Created by Spencer Salazar on 2/26/14.
//  Copyright (c) 2014 Spencer Salazar. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FBPersistenceManager : NSObject

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end

@interface NSManagedObject (Font)

@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *isFavorite;

@end
