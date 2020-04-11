//
//  XYLocationManager.h
//  XYLocationManager
//
//  Created by 渠晓友 on 2020/4/11.
//  Copyright © 2020 渠晓友. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XYLocationManager : NSObject

/// 获取当前地理位置
/// @param result 获取地理位置结果回调
+ (void)getCurrentLocation:(void(^)(CLLocation *currentLocation, NSString *errorMsg))result;

/// 获取当前地理位置和地理反编码
/// @param result 获取地理位置结果回调
+ (void)getCurrentLocationAndGEO:(void(^)(CLLocation *currentLocation, CLPlacemark *placemark, NSString *errorMsg))result;

/// 判断目标点是否在距离中心点规定半径的区域内
/// @param targetLocation 目标点
/// @param centerLocation 区域中心点
/// @param radius 规定半径
+ (BOOL)isLocation:(CLLocation *)targetLocation inRegion:(CLLocation *)centerLocation radius:(CLLocationDistance)radius;

/// 对某个点进行地理反编码
/// @param location 需要反编码的地点
/// @param completionHandler 地理反编码完成回调
+ (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(CLGeocodeCompletionHandler)completionHandler;

/// 对某个地理位置进行地理编码
/// @param addressString 需要编码的地理位置
/// @param completionHandler 地理编码完成回调
+ (void)geocodeAddressString:(NSString *)addressString completionHandler:(CLGeocodeCompletionHandler)completionHandler;

/// 手动销毁定位相关内部创建的对象
+ (void)dealloc;

@end

NS_ASSUME_NONNULL_END
