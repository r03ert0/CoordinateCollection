//  CoordinateCollectionAppDelegate.h
//  CoordinateCollection
//
//  Created by rOBERTO tORO on 15/08/2006.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import <Cocoa/Cocoa.h>

@interface CoordinateCollectionAppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	IBOutlet NSArrayController	*arrayCtrlr;
}

-(NSManagedObjectModel *)managedObjectModel;
-(NSManagedObjectContext *)managedObjectContext;

-(IBAction)saveAction:sender;
-(void)changeCoordinate;
-(IBAction)articles:(id)sender;
@end
