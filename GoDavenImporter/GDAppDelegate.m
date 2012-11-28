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

const int kNumberOfShuls = 10000;

const int kInitialIndex = 1527;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [self performSelectorInBackground:@selector(loadShuls) withObject:nil];
        
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    [self save];
}

//
//  Updates the UI with progress information.
//

- (void) setProgress:(double)progress{
    
    //
    //  Calculate the percentage
    //
    
    NSUInteger count = [[self shuls] count];
    NSUInteger totalShuls = (NSUInteger)progress;
    
    double percent = (double)progress/(kNumberOfShuls-kInitialIndex) * 100.0f;
    
    NSString *success = [NSString stringWithFormat:@"Succeeded at %li of %li attempted URLs. (%i total)\n%.02f%% complete", count, totalShuls, kNumberOfShuls-kInitialIndex, percent];
    
    //
    //  Calculate time per shul, expected finish
    //
    
    NSDate *now = [NSDate date];
    
    NSTimeInterval elapsedInterval = [now timeIntervalSinceDate:[self startTime]];
    
    NSTimeInterval timePerShul = elapsedInterval/count;
    
    NSTimeInterval timeExpectedToRemain = timePerShul * (kNumberOfShuls -kInitialIndex - count);
    
    NSString *timeElapsed = [self stringFromTimeInterval:elapsedInterval];
    NSString *timeRemaining = [self stringFromTimeInterval:timeExpectedToRemain];
    
    NSString *remaining = [NSString stringWithFormat:@"It's been %@ since I began. I expect to finish in about %@.", timeElapsed, timeRemaining];
    
    //
    //  Update the UI on the main thread
    //
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self indicator] setDoubleValue:percent];
        [[self succeededLabel] setStringValue:success];
        [[self timeLabel] setStringValue:remaining];
    });
}

//
//  Load the shul data from GoDaven
//

- (void) loadShuls{
    
    //
    //  Prepare an array to hold the shuls
    //
    
    [self setShuls:[@[] mutableCopy]];
    
    //
    //  Track the date
    //
    
    [self setStartTime:[NSDate date]];
    
    //
    //  Set up the max ID to scrape
    //
    
    NSUInteger maxID = kNumberOfShuls;
    
    //  Prepare the indicator with the max value of 100%
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[self indicator] setMaxValue:100];
    });
    
    //
    //  Loop through all of the URLs and scrape the data
    //
    
    for (NSUInteger identifier = kInitialIndex; identifier < maxID; identifier++) {
        
        NSString *path =  [NSString stringWithFormat:@"http://godaven.com/detail.asp?Id=%li&City=Airmont&State=NY", identifier];
        
        NSURL *url = [NSURL URLWithString:path];
        
        NSString *webpage = [self stringWithUrl:url];
        
        //
        //  Greate a GDShul object to store our data
        //
        
        GDShul *shul = [GDShul new];
        
        [shul setIdentifier:identifier];
        
        NSString *name = [[self shulNameFromPage:webpage] sanitizedString];
        NSString *address = [[self locationFromPage:webpage] sanitizedString];
        NSString *phone = [self extractedPhoneFromString:webpage];
        NSString *details = [self additionalInfoForPage:webpage];
        
        if(name && address){
            
            [shul setName:name];
            [shul setAddress:address];
            [shul setPhoneNumber:phone ? phone : @""];
            [shul setDetails:details ? details : @""];
            [[self shuls] addObject:shul];
        }
        
        //
        //  This method will run on the main thread
        //
        
        [self setProgress:(double)identifier+1-kInitialIndex];
    }
    
    [self save];
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

//
//  This method extracts a shul name from the webpage
//

- (NSString *) shulNameFromPage:(NSString *)webpage{

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
    
    NSRange rangeOfLocationSpan = [webpage rangeOfString:@"GMAP-API\">"];
    
    //
    //  If it's there, process
    //
    
    if(rangeOfLocationSpan.location != NSNotFound){
        
        //
        //  Remove the first half of the string, until the part we want.
        //
        
        NSString *parsedPage = [webpage substringFromIndex:rangeOfLocationSpan.location+rangeOfLocationSpan.length];
        
        //
        //  Find the closing tag
        //
        
        rangeOfLocationSpan = [parsedPage rangeOfString:@"</div>"];
        
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

- (NSString *)additionalInfoForPage:(NSString *)webpage{
    
    //
    //  Find the location span in the page
    //
    
    NSRange rangeOfLocationSpan = [webpage rangeOfString:@"addtlInfo\">"];
    
    //
    //  If it's there, process
    //
    
    if(rangeOfLocationSpan.location != NSNotFound){
        
        //
        //  Remove the first half of the string, until the part we want.
        //
        
        NSString *parsedPage = [webpage substringFromIndex:rangeOfLocationSpan.location+rangeOfLocationSpan.length];
        
        //
        //  Find the closing tag
        //
        
        rangeOfLocationSpan = [parsedPage rangeOfString:@"</div>"];
        
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

//
//  Convert a time interval into 00:00:00 format
//

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = MAX(0,(NSInteger)interval);
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02li:%02li:%02li", hours, minutes, seconds];
}

//
//  Use NSDataDetector to pull the phone number out of the webpage
//

- (NSString *)extractedPhoneFromString:(NSString *)string{
    
    if (string == nil) {
        return nil;
    }
    
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypePhoneNumber error:nil];
    
    NSArray *matches = [detector matchesInString:string
                                         options:0
                                           range:NSMakeRange(0, [string length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];

        return [string substringWithRange:matchRange];
    }
    
    return nil;
}

#pragma mark - Save

//
//  Save the data to the desktop
//

- (void) save{
    
    NSURL *url = [NSURL URLWithString:@"file:///Users/Moshe/Desktop/shuls2.txt"];
    
    NSError *error = nil;
    
    NSString * data = [[self shuls] componentsJoinedByString:@"\n"];
    
    if(![data writeToURL:url atomically:NO encoding:NSUTF16StringEncoding error:&error]){
        NSLog(@"Write failed. %@", error);
    }

}
@end
