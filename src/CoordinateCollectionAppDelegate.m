//  CoordinateCollectionAppDelegate.m
//  CoordinateCollection
//
//  Created by rOBERTO tORO on 15/08/2006.
//  Copyright __MyCompanyName__ 2006 . All rights reserved.

#import "CoordinateCollectionAppDelegate.h"

@implementation CoordinateCollectionAppDelegate

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}

/* Change this path/code to point to your App's data store. */
- (NSString *)applicationSupportFolder {
    NSString *applicationSupportFolder = nil;
    FSRef foundRef;
    OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
    if (err != noErr) {
        NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    } else {
        unsigned char path[1024];
        FSRefMakePath(&foundRef, path, sizeof(path));
        applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
        applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"CoordinateCollection"];
    }
    return applicationSupportFolder;
}

- (NSManagedObjectContext *) managedObjectContext {
    NSError *error;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"CoordinateCollection.xml"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if ([coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    NSError *error;
    NSManagedObjectContext *context;
    int reply = NSTerminateNow;
    
    context = [self managedObjectContext];
    if (context != nil) {
        if ([context commitEditing]) {
            if (![context save:&error]) {
				
				// This default error handling implementation should be changed to make sure the error presented includes application specific error recovery. For now, simply display 2 panels.
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
				if (errorResult == YES) { // Then the error was handled
					reply = NSTerminateCancel;
				} else {
					
					// Error handling wasn't implemented. Fall back to displaying a "quit anyway" panel.
					int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
					if (alertReturn == NSAlertAlternateReturn) {
						reply = NSTerminateCancel;	
					}
				}
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    return reply;
}
-(void)changeCoordinate
{
	int	x,y,z;
	NSManagedObject *myRecord  = nil;
	myRecord = [arrayCtrlr selection];
	x=[[myRecord valueForKey:@"x"] intValue];
	y=[[myRecord valueForKey:@"y"] intValue];
	z=[[myRecord valueForKey:@"z"] intValue];
	
	if(x==0 && y==0 && z==0)
		return;

	printf("%i %i %i\n",x,y,z);
	
	NSString	*str=[NSString stringWithFormat:@"\
	tell application \"CoactivationMap\"\r\
		activate\r\
		my coordinate(%i, %i, %i, 0.1)\r\
	end tell\r\
	tell application \"CoordinateCollection\"\r\
		activate\r\
	end tell\r\
	to coordinate(x, y, z, r)\r\
		tell application \"System Events\"\r\
			tell process \"CoactivationMap\" to perform action \"AXRaise\"\r\
                      keystroke x as string\r\
                      keystroke tab\r\
                      keystroke tab\r\
                      keystroke y as string\r\
                      keystroke tab\r\
                      keystroke tab\r\
                      keystroke z as string\r\
                      keystroke tab\r\
                      keystroke tab\r\
                      keystroke tab\r\
                      keystroke tab\r\
		end tell\r\
	end coordinate\r\
	",x,y,z];
    //			tell process \"CoactivationMap\" to tell window \"Coactivation Map\" to perform action \"AXRaise\"\r\

/*
    keystroke x as string\r\
    keystroke tab\r\
    keystroke tab\r\
    keystroke y as string\r\
    keystroke tab\r\
    keystroke tab\r\
    keystroke z as string\r\
    keystroke tab\r\
    keystroke tab\r\
    keystroke r as string\r\
    keystroke tab\r\
*/
	NSAppleScript *script;
	script = [[NSAppleScript alloc] initWithSource:str];
	[script executeAndReturnError:nil];
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self changeCoordinate];
}
#pragma mark -
typedef struct
{
	int	a,b,c;
}int3D;
int3D	*peaks;
int		npeaks;
#include <sys/dir.h>
extern int alphasort();
int file_select(struct direct *entry);
int file_select(struct direct *entry)
{
	if( (strcmp(entry->d_name,".")==0) || (strcmp(entry->d_name,"..")==0) || entry->d_name[0]=='.')
		return 0;
	else
		return 1;
}
void findpeaks(short *cvol, int3D *peaks, int *npeaks, float peakthreshold)
{
	int		i,j,k,l,m,n;
	float	max;
	int		R=5;
	int		LR=46,PA=55,IS=46;
	
	*npeaks=0;
	for(i=0;i<LR;i++)
	for(j=0;j<PA;j++)
	for(k=0;k<IS;k++)
	if(cvol[k*PA*LR+j*LR+i]>peakthreshold*0x7fff)
	{
		max=0;
		for(l=-R;l<=R;l++)
		for(m=-R;m<=R;m++)
		for(n=-R;n<=R;n++)
			if(i+l>=0 && i+l<LR &&
			   j+m>=0 && j+m<PA &&
			   k+n>=0 && k+n<IS)
			if(cvol[(k+n)*PA*LR+(j+m)*LR+(i+l)]>max)
				max=cvol[(k+n)*PA*LR+(j+m)*LR+(i+l)];
		
		if(cvol[k*PA*LR+j*LR+i]==max)
		{
			peaks[*npeaks].a=i;
			peaks[*npeaks].b=j;
			peaks[*npeaks].c=k;
			(*npeaks)++;
		}
	}
}
-(void)gather:(char*)path:(float)thr:(char *)xdescPath
{
	FILE	*f,*xf;
	short	*cvol;
	char	*xvol;
	int		i,j,n,npks;
	int		nvols;
	struct	direct **files;
	char	name[255],desc[1024];
	int		LR=46,PA=55,IS=46;
	NSManagedObject *myRecord  = nil;
	myRecord = [arrayCtrlr selection];
	char	roi_dir[]="/Users/roberto/Documents/2005_11Coactivation/data3402/24mm/01_ROI/";
	

	// load correlations volume
	cvol=(short*)calloc(LR*PA*IS,sizeof(short));
	f=fopen(path,"r");
	fread(cvol,LR*PA*IS,sizeof(short),f);
	fclose(f);
	
	// find peaks of the network
	peaks=(int3D*)calloc(100,sizeof(int3D));
	findpeaks(cvol,peaks,&npeaks,0.15);

	NSString	*str=[NSString stringWithFormat:@"\
		tell application \"TextEdit\"\r\
			launch\r\
			make new document\r\
			set text of front document to \"%s\r\"\r\
			set text of front document to text of front document & \"%i peaks found.\r\r\"\r\
		end tell",[[myRecord valueForKey:@"name"] cString],npeaks];
	NSAppleScript *script;
	script = [[NSAppleScript alloc] initWithSource:str];
	[script executeAndReturnError:nil];
	[script release];
	
	// scan through the experiments for intersections with the network peaks
	xvol=(char*)calloc(LR*PA*IS,sizeof(char));
    nvols=scandir(roi_dir, &files, file_select, alphasort);
	xf=fopen(xdescPath,"r");
	n=0;

	for(i=0;i<nvols;i++)
	{
		sprintf(name,"%s%s",roi_dir,files[i]->d_name);
		f=fopen(name,"r");
		fread(xvol,LR*PA*IS,sizeof(char),f);
		fclose(f);
		
		fgets(desc,1024,xf);
		
		npks=0;
		for(j=0;j<npeaks;j++)
		if(xvol[peaks[j].c*PA*LR+peaks[j].b*LR+peaks[j].a])
			npks++;
		
		if(npks>=2)
		{
			str=[NSString stringWithFormat:@"\
				tell application \"TextEdit\"\r\
					set text of front document to text of front document & \"%i (%i/%i). %s\"\r\
				end tell",i,npks,npeaks,desc];
			script = [[NSAppleScript alloc] initWithSource:str];
			[script executeAndReturnError:nil];
			[script release];

			n++;
		}
	}
	fclose(xf);
	
	str=[NSString stringWithFormat:@"\
		tell application \"TextEdit\"\r\
			set text of front document to text of front document & \"\r%i experiments contributing to the network\"\r\
		end tell",n];
	script = [[NSAppleScript alloc] initWithSource:str];
	[script executeAndReturnError:nil];
	[script release];
}
-(IBAction)articles:(id)sender
{
	char	cvol[512];
	int	x,y,z;
	NSManagedObject *myRecord  = nil;
	myRecord = [arrayCtrlr selection];
	x=[[myRecord valueForKey:@"x"] intValue];
	y=[[myRecord valueForKey:@"y"] intValue];
	z=[[myRecord valueForKey:@"z"] intValue];

	sprintf(cvol,"/Users/roberto/Documents/2005_11Coactivation/data3402/24mm/04_correlations/%03i%03i%03i.img",x,y,z);
	[self gather:cvol:0.9:"/Users/roberto/Documents/2005_11Coactivation/data3402/xdescriptions.txt"];
}

@end
