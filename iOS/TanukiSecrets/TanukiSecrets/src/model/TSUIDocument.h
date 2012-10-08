//
//  TSUIDocument.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 10/6/12.
//  Copyright (c) 2012 BlueTanuki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSUIDocument : UIDocument

@property(nonatomic, strong) NSData *tsuiDocData;

- (void)loadFromLocalFilesystem:(NSString *)filePath;
- (BOOL)saveToLocalFilesystem:(NSString *)filePath;

@end
