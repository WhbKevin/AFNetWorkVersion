//
//  AFClientDataRequester.h
//  AFClientDataRequester
//
//  Created by kevin on 15/7/7.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#import "AFBaseDataRequester.h"

@interface AFClientDataRequester : AFBaseDataRequester

+(instancetype)manager;

/******************************************
 *@Description:获取验证码
 *@Params: 参数
 *@Return:成功或者失败
 ******************************************/
- (void)testDownload;
@end
