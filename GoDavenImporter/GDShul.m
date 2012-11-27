//
//  GDShul.m
//  GoDavenImporter
//
//  Created by Moshe Berman on 11/27/12.
//  Copyright (c) 2012 Moshe Berman. All rights reserved.
//

#import "GDShul.h"

@implementation GDShul

- (NSString *)description{
    return [NSString stringWithFormat:@"---- Shul #%i -----\nName: %@\nAddress: %@\nPhone:%@\n\n", self.identifier, self.name, self.address, self.phoneNumber];
}

@end
