//
//  CommunicationKeyDefinition.h
//  
//
//  Created by kevin on 15/7/7.
//  Copyright (c) 2015年 kevin. All rights reserved.
//

#ifndef __COMMUNICATION_KEY_DEFINITION_H__
#define __COMMUNICATION_KEY_DEFINITION_H__

/**
 *  返回数据的格式
 */
static NSString *const textPlain = @"text/plain";
static NSString *const textHtml = @"text/html";
static NSString *const cotetStream = @"application/octet-stream";
static NSString *const textJson = @"text/json";
static NSString *const appJson = @"application/json";
static NSString *const textJavascript = @"text/javascript";
static NSString *const textXML =  @"text/xml";
static NSString *const httpImages = @"image/*";
/**
 *  设置请求／或者返回数据的 超时时间
 */
static int const  timeoutInterval = 30;
/**
 *  支持HTTPS 证书名.cer文件
 */
static NSString *const SSLCertificate = @"";

/**
 请求格式(最常用:AFHTTPRequestSerializer,AFJSONRequestSerializer)
 */
typedef enum {
    AF_HTTPRequestSerializer,
    AF_JSONRequestSerializer,
}AFRequestSerializer;

/**
 返回数据格式(最常用AFHTTPResponseSerializer,AFJSONResponseSerializer)
 */
typedef enum {
    AF_HTTPResponseSerializer,
    AF_JSONResponseSerializer
}AFResponseSerializer;
/**
 HTTP 请求数据的状态（可自行扩展）
 */
typedef enum {
    AFURLResponeStateFailure, //请求失败
    AFURLResponeStateSuccess, //请求成功
}AFURLResponeState;

typedef enum
{
    //GET 方式
    DRT_TYPE_GET_BEGIN,
      TEST_TYPE,
    DRT_TYPE_GET_END,
    
    //POST 方式
    DRT_TYPE_POST_BEGIN,
    DRT_TYPE_POST_END,
    
    
    //从本地RESOURCE读取
    DRT_TYPE_RESOURCE_BEGIN,
    DRT_TYPE_RESOURCE_END,
    
    //上传
    DRT_TYPE_UPLOAD_BEGIN,
    DRT_TYPE_UPLOAD_END,
    
    //下载
    DRT_TYPE_DOWNLOAD_BEGIN,
       DRT_TYPE_DOWNLOADIMAGE,
    DRT_TYPE_DOWNLOAD_END,
    
} DataRequestType;

#pragma mark - V1.0版本
//请求的IP或者域名
#define AF_BASE_URL @""

#endif

