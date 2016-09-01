//
//  ViewController.m
//  AFNetWorkVersion
//
//  Created by kevin on 15/11/17.
//  Copyright © 2015年 kevin. All rights reserved.
//

#import "ViewController.h"
#import "AFNetWork/AFHttpClient/AFClientDataRequester.h"

@interface ViewController ()
{
    AFClientDataRequester *downLoad;
    UIImageView *loadImageView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    http://zhangbuhuai.com/img/201408/details3-合1.jpg
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [btn addTarget:self action:@selector(downloadImage:) forControlEvents:UIControlEventTouchUpInside];
    [btn setCenter:self.view.center];
    [self.view addSubview:btn];
    
    loadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(60, 80, 100, 100)];
    [self.view addSubview:loadImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)downloadImage:(UIButton*)sender{
    [AFClientDataRequester saveCookie];
    downLoad = [AFClientDataRequester manager];
//    downLoad.HTTPRequestHeaders = @{@"User-Agent":@"Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",@"Cookie":@"__uvt=; tz=-480; src=CTU; when=Sat%2C%20Sep%2010%2C%202016; whenBack=; _gat=1; _ga=GA1.2.190247211.1472202230; uvts=4xdMfux3lRBCVyqh"};
//    downLoad.isProgress = YES;
//    downLoad.delegate = (id<AFDataRequesterDelegate>)self;
    downLoad.responseSerializer = AF_JSONResponseSerializer;
    downLoad.isAuthHttps = YES;
    [downLoad testDownload];
    [downLoad progress:^(AFBaseDataRequester *requester, DataRequestType aType, NSProgress *progress) {
        NSLog(@"pro === %@",@(progress.completedUnitCount));
    } completion:^(AFBaseDataRequester *requester, DataRequestType aType, AFDataResponse *resonse) {
        
    } failure:^(AFBaseDataRequester *requester, DataRequestType aType, AFDataResponse *resonse) {
        
    }];
    
//    [downLoad completionHandler:^(AFBaseDataRequester *requester, DataRequestType aType, AFDataResponse *resonse) {
//        NSLog(@"成功");
//        
//    } failure:^(AFBaseDataRequester *requester, DataRequestType aType, AFDataResponse *resonse) {
//        NSLog(@"失败");
//    }];
}
-(void)dataRequesterSuccess:(AFBaseDataRequester *)dataRequester requesterWithType:(DataRequestType)aType receiveResponse:(AFDataResponse*)response{
    UIImage *image = [UIImage imageWithData:response.responseData];
    CGRect makeRect = loadImageView.frame;
    makeRect.origin.x = (self.view.frame.size.width - image.size.width/2.0f)/2.0f;
    makeRect.size.width = image.size.width/2.0f;
    makeRect.size.height = image.size.height/2.0f;
    loadImageView.frame = makeRect;
    loadImageView.image = image;
}
-(void)dataRequesterProgress:(AFBaseDataRequester*)dataRequester requesterWithType:(DataRequestType)aType receiveDataProgress:(NSProgress*)progress{
    
    NSLog(@"当前进度 == %f,总大小 == %lld, 当前下载的大小 == %lld",progress.fractionCompleted,progress.totalUnitCount,progress.completedUnitCount);
}
@end
