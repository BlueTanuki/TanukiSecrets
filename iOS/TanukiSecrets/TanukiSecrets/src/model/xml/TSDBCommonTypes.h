//
//  TSDBCommonTypes.h
//  TanukiSecrets
//
//  Created by Lucian Ganea on 5/11/13.
//  Copyright (c) 2013 BlueTanuki. All rights reserved.
//

#ifndef TanukiSecrets_TSDBCommonTypes_h
#define TanukiSecrets_TSDBCommonTypes_h

typedef enum {
	TSDBFieldType_DEFAULT,//short string, rendered as text field
	TSDBFieldType_SECRET,//short string, rendered as protected text input, probably encrypted as well
	TSDBFieldType_TEXT,//long string, rendered as textarea
	TSDBFieldType_NUMERIC,//numeric value [0-9]*
	TSDBFieldType_URL,//relatively short string, interpreted as URL
	TSDBFieldType_RESERVED
} TSDBFieldType;


#endif
