//
//  ICViewController.m
//  Test AFNetwork
//
//  Created by 刘平伟 on 14-5-1.
//  Copyright (c) 2014年 刘平伟. All rights reserved.
//

#import "ICViewController.h"
#import "AFNetworking/AFNetworking.h"
#import <CommonCrypto/CommonDigest.h>


//约定串
#define APPOINT_KEY @"894D94361A243577F0A497C4EAB6462A178900022D1D95B2EAE04"

@interface ICViewController ()

@end

@implementation ICViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
//    [manager GET:@"http://www.verycd.com/api/v1/base/index?limit=12&catalog_id=1" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
////    manager.requestSerializer = [AFJSONRequestSerializer serializer];
////    manager.responseSerializer = [AFJSONResponseSerializer serializer];
////    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
//    NSDictionary *parameters = @{@"lat": @"37.785834",
//                                 @"lon":@"-122.406417",
//                                 @"units":@"imperial"};
//    AFHTTPRequestOperation *op = [manager POST:@"http://api.openweathermap.org/data/2.5/weather?lat=37.785834&lon=-122.406417&units=imperial" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"response dict is %@",responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error is %@",error);
//    }];
//    [op pause];
//    NSLog(@"op is %@\n queue is %@",op,manager.operationQueue.operations);
//    [op cancel];
//    NSLog(@"op is %@\n quwuw is %@",op,manager.operationQueue.operations);
//    [op start];
//        NSLog(@"op is %@ \n queue is %@",op,manager.operationQueue.operations);
    
//    AFHTTPRequestOperation *op1 = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://api.openweathermap.org/data/2.5/weather?lat=37.785834&lon=-122.406417&units=imperial"]]];
//    [op1 setResponseSerializer:[AFJSONResponseSerializer serializer]];
//    [op1 setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"respose dict is %@",responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"error is %@",error);
//    }];
//    [op1 start];
//    [op1 cancel];
    
//    [QWHTTPClient get_RequestWithPath:@"http://www.verycd.com/api/v1/base/index?limit=12&catalog_id=1"
//                           paramaters:nil
//                              success:^(id task, id response) {
//                                  NSLog(@"response is %@",response);
//                              } failed:^(id task, id error) {
//                                  NSLog(@"error is %@",error);
//                              }];
    
//    NSString *sign = [[@"18701828057" stringByAppendingString:validType] stringByAppendingString:APPOINT_KEY];
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setObject:@"18701828057" forKey:@"loginName"];
    [param setObject:@"2" forKey:@"validType"];
    [param setObject:@"8alskdlanksdlskfdklf" forKey:@"sign"];

    
    [QWHTTPClient post_requestWithPath:@"http://api.ichronocloud.com/sendValidCode.htm" paramaters:param success:^(id task, id response) {
        NSLog(@"response is %@",response[@"msg"]);
    } failed:^(id task, NSError *error) {
        NSLog(@"error is %@",error);
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.

}

@end