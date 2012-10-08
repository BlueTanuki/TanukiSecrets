//
//  TSUIDocument.m
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import "TSUIDocument.h"

@implementation TSUIDocument

@synthesize tsuiDocData = _tsuiDocData;

- (NSString *)localizedName
{
	return [self.fileURL lastPathComponent];
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	return self.tsuiDocData;
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
	self.tsuiDocData = contents;
	return YES;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
}

- (void)loadFromLocalFilesystem:(NSString *)filePath
{
	self.tsuiDocData = [NSData dataWithContentsOfFile:filePath];
}

- (BOOL)saveToLocalFilesystem:(NSString *)filePath
{
	return [[NSFileManager defaultManager] createFileAtPath:filePath contents:self.tsuiDocData attributes:nil];
}

@end
