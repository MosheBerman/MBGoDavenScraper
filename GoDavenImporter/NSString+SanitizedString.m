//
//  NSString+SanitizedString.m
//  GoDavenImporter
//
//  Created by Moshe Berman on 11/27/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "NSString+SanitizedString.h"

@implementation NSString (SanitizedString)

- (NSString *) sanitizedString{
    return [[[[[[[[[self stringByDeletingOccurencesOfString:@"<span>"]
                  stringByDeletingOccurencesOfString:@"</span>"]
                 stringByDeletingOccurencesOfString:@"<p>"]
                stringByDeletingOccurencesOfString:@"</p>"]
               stringByDeletingOccurencesOfString:@"&nbsp;"]
              stringByDeletingOccurencesOfString:@"<p class=\"tel\">"]
             stringByDeletingOccurencesOfString:@"\t"]
            stringByDeletingOccurencesOfString:@"\n"] stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    
}

- (NSString *) stringByDeletingOccurencesOfString:(NSString *)string{
 return [self stringByReplacingOccurrencesOfString:string withString:@""];
}
@end
