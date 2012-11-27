//
//  GDAppDelegate.m
//  GoDavenImporter
//
//  Created by Moshe Berman on 11/27/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "GDAppDelegate.h"

#import "GDShul.h"

#import "NSString+SanitizedString.h"

@implementation GDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSUInteger maxID = 100000;
    
    for (NSUInteger identifier = 0; identifier < maxID; identifier++) {
        
        NSString *path =  [NSString stringWithFormat:@"http://godaven.com/detail.asp?Id=%li&City=Airmont&State=NY", identifier];
        
        
        NSURL *url = [NSURL URLWithString:path];
        
        NSString *webpage = [self stringWithUrl:url];
        
        
        GDShul *shul = [[GDShul alloc] init];
        
        
        shul.name = [[self shulNameFromPage:webpage] sanitizedString];
        shul.address = [[self locationFromPage:webpage] sanitizedString];
        
        if(shul.address && shul.name){
            [[self shuls] addObject:shul];
        }
    }
    
        NSLog(@"Shuls: %@", [self shuls]);
    
}

- (NSString *)stringWithUrl:(NSURL *)url
{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                            timeoutInterval:30];
    
    // Fetch the JSON response
    NSData *urlData;
    NSURLResponse *response;
    NSError *error;
    
    // Make synchronous request
    urlData = [NSURLConnection sendSynchronousRequest:urlRequest
                                    returningResponse:&response
                                                error:&error];
    
    // Construct a String around the Data from the response
    return [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
}

- (NSString *) shulNameFromPage:(NSString *)webpage{
    
    /*
    if([webpage rangeOfString:@"cong-name"].location != NSNotFound){
        
        NSRange rangeOfOpenHeader = [webpage rangeOfString:@"<h1>"];
        
        NSString *afterOpen = [webpage substringFromIndex:rangeOfOpenHeader.location];
        
        NSRange rangeOfCloseHeader = [afterOpen rangeOfString:@"</h1>"];
        
        NSString *title = [webpage substringToIndex:rangeOfCloseHeader.location];
        
        return title;
    }
     */
    NSRange firstRange = [webpage rangeOfString:@"cong-name"];
    
    if(firstRange.location != NSNotFound){
        
        NSString *afterCongName = [webpage substringFromIndex:firstRange.location];
        NSRange rangeOfOpenHeader = [afterCongName rangeOfString:@"<h1>" options:NSCaseInsensitiveSearch];
        
        NSString *shulNameBefore = [afterCongName substringFromIndex: rangeOfOpenHeader.location + rangeOfOpenHeader.length];
        
        NSRange rangeOfCloseHeader = [shulNameBefore rangeOfString:@"</h1>" options:NSCaseInsensitiveSearch];
        
        NSString *shulNameToReturn = [shulNameBefore substringToIndex: rangeOfCloseHeader.location];
        
        return shulNameToReturn;
    }
    
    return nil;
    
}

- (NSString *) locationFromPage:(NSString *)webpage{
    
    //
    //  Find the location span in the page
    //
    
    NSRange rangeOfLocationSpan = [webpage rangeOfString:@"\"loc\">"];
    
    //
    //  If it's there, process
    //
    
    if(rangeOfLocationSpan.location != NSNotFound){
        
        //
        //  Remove the first half of the string, until the part we want.
        //
        
        NSString *parsedPage = [webpage substringFromIndex:rangeOfLocationSpan.location];
        
        //
        //  Find the closing tag
        //
        
        rangeOfLocationSpan = [parsedPage rangeOfString:@"</span>"];
        
        //
        //  Remove everything after and including the closing tag.
        //
        
        rangeOfLocationSpan.length = rangeOfLocationSpan.location;
        rangeOfLocationSpan.location = 0;
        
        parsedPage = [[parsedPage substringWithRange:rangeOfLocationSpan] sanitizedString];
        
        //
        //  Return
        //
        
        return parsedPage;
    }
    
    return nil;
}

@end
