//
//  TSXMLUtils.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 9/14/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLWriter.h"

@interface TSXMLUtils : NSObject

+ (void)writeSimpleTagNamed:(NSString *)tagName
		  withStringContent:(NSString *)content
				   toWriter:(XMLWriter *)writer;

+ (void)writeSimpleTagNamed:(NSString *)tagName
		  withIntegerContent:(NSInteger)content
				   toWriter:(XMLWriter *)writer;

///binary data is encoded as hex string using [TSStringUtils hexStringFromData:content]
+ (void)writeSimpleTagNamed:(NSString *)tagName
		  withBinaryContent:(NSData *)content
				   toWriter:(XMLWriter *)writer;

///the date is encoded using [TSDateUtils stringFromDate:content]
+ (void)writeSimpleTagNamed:(NSString *)tagName
		  withDateTimeContent:(NSDate *)content
				   toWriter:(XMLWriter *)writer;

+ (void)writeSimpleNodesNamed:(NSArray *)tagNames
				  andContents:(NSArray *)stringContents
					 toWriter:(XMLWriter *)writer;

+ (void)writeSimpleNodesNamed:(NSArray *)tagNames
				  andContents:(NSArray *)stringContents
	   insideWrapperNodeNamed:(NSString *)parentNodeName
					 toWriter:(XMLWriter *)writer;

@end
