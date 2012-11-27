//
//  GDAppDelegate.h
//  GoDavenImporter
//
//  Created by Moshe Berman on 11/27/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GDAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) NSMutableArray *shuls;

@end
