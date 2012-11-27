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
    return [[[[[[[[self stringByDeletingOccurencesOfString:@"<span>"]
                  stringByDeletingOccurencesOfString:@"</span>"]
                 stringByDeletingOccurencesOfString:@"<br>"]
                stringByDeletingOccurencesOfString:@"<p>"]
               stringByDeletingOccurencesOfString:@"</p>"]
              stringByDeletingOccurencesOfString:@"&nbsp;"]
             stringByDeletingOccurencesOfString:@"<p class=\"tel\">"]
            stringByDeletingOccurencesOfString:@"\t"];
    
}

- (NSString *) stringByDeletingOccurencesOfString:(NSString *)string{
 return [self stringByReplacingOccurrencesOfString:string withString:@""];
}
@end
