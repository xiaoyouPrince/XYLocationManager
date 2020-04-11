//
//  XYLocationManager.m
//  XYLocationManager
//
//  Created by 渠晓友 on 2020/4/11.
//  Copyright © 2020 渠晓友. All rights reserved.
//
//  一个简单的管理地理位置的工具类，适用于获取地理位置，刷新地理位置，基本功能
//  自动处理权限问题

#import "XYLocationManager.h"

typedef void(^GetCurrentLocationBlock)(CLLocation *currentLocation, NSString *errorMsg);
typedef void(^GetCurrentLocationAndGEOBlock)(CLLocation *currentLocation, CLPlacemark *placemark, NSString *errorMsg);

@interface XYLocationManager()<CLLocationManagerDelegate>
/** locMgr */
@property (nonatomic, strong)       CLLocationManager * locMgr;
/** location地理反编码 */
@property (nonatomic, strong) CLGeocoder * locationGeocoder;
/** getCurrentLocationBlock */
@property (nonatomic, copy)         GetCurrentLocationBlock getCurrentLocationBlock;
/** getCurrentLocationAndGEOBlock */
@property (nonatomic, copy)         GetCurrentLocationAndGEOBlock getCurrentLocationAndGEOBlock;
@end
static XYLocationManager *_instance;
@implementation XYLocationManager

#pragma mark - Public Methods

+ (void)getCurrentLocation:(void (^)(CLLocation * _Nonnull,NSString *errorMsg))result
{
    [self configInstanceWithAuthResult:^(NSString *errorMsg) {
        if (!errorMsg) {
            _instance.getCurrentLocationBlock = result;
            _instance.getCurrentLocationAndGEOBlock = nil;
            [_instance.locMgr startUpdatingLocation];
        }
    }];
}

+ (void)getCurrentLocationAndGEO:(void (^)(CLLocation * _Nonnull, CLPlacemark * _Nonnull, NSString * _Nonnull))result
{
    [self configInstanceWithAuthResult:^(NSString *errorMsg) {
        if (!errorMsg) {
            _instance.getCurrentLocationAndGEOBlock = result;
            _instance.getCurrentLocationBlock = nil;
            [_instance.locMgr startUpdatingLocation];
        }
    }];
}

+ (BOOL)isLocation:(CLLocation *)targetLocation inRegion:(CLLocation *)centerLocation radius:(CLLocationDistance)radius
{
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:centerLocation.coordinate radius:radius identifier:@"mycustomregion"];
    return [region containsCoordinate:targetLocation.coordinate];
}

+ (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(CLGeocodeCompletionHandler)completionHandler{
    [self configInstanceWithAuthResult:^(NSString *errorMsg) {
        if (!errorMsg) {
            [_instance.locationGeocoder reverseGeocodeLocation:location completionHandler:completionHandler];
        }
    }];
}

+ (void)geocodeAddressString:(NSString *)addressString completionHandler:(CLGeocodeCompletionHandler)completionHandler{
    [self configInstanceWithAuthResult:^(NSString *errorMsg) {
        if (!errorMsg) {
            [_instance.locationGeocoder cancelGeocode];
            [_instance.locationGeocoder geocodeAddressString:addressString completionHandler:completionHandler];
        }
    }];
}

+ (void)dealloc
{
    if (!_instance) {
        _instance = nil;
    }
}

#pragma mark - private

+ (void)configInstanceWithAuthResult:(void(^)(NSString *errorMsg))handler{
    
    if (!_instance) {
        _instance = [XYLocationManager new];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        if (handler) {
            handler(nil);
        }
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [_instance.locMgr requestWhenInUseAuthorization];
        if (handler) {
            handler(nil);
        }
    }
    {
        if (handler) {
            handler(@"没有定位权限");
        }
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"无定位权限" message:@"打开定位权限，请去设置->隐私->定位来打开当前应用权限" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction: [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *settingUrl = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:settingUrl options:@{} completionHandler:nil];
            }]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
        
        
    }
}

- (instancetype)init
{
    if (self == [super init]) {
        self.locMgr = [CLLocationManager new];
        self.locationGeocoder = [CLGeocoder new];
        self.locMgr.delegate = self;
    }
    return self;
}

// 一开始就请求地理位置
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    // 拿到最近的location,去解析地理位置，并请求对应的天气
    NSLog(@"请求到的地址为: - locations = %@",locations);
    // 解析第一个地址,用来请求位置
    CLLocation *location = locations.firstObject;
    if (self.getCurrentLocationBlock) {
        self.getCurrentLocationBlock(location,nil);
    }
    
    if (self.getCurrentLocationAndGEOBlock) { // 需要geo
        [self.locationGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (error) {
                self.getCurrentLocationAndGEOBlock(location, nil, @"地理编码失败");
            }else
            {
                self.getCurrentLocationAndGEOBlock(location, placemarks.firstObject, nil);
            }
        }];
    }
    
    [self.locMgr stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (self.getCurrentLocationBlock) {
        self.getCurrentLocationBlock(nil,@"定位失败,请检查定位权限");
    }
    if (self.getCurrentLocationAndGEOBlock) {
        self.getCurrentLocationAndGEOBlock(nil,nil,@"定位失败,请检查定位权限");
    }
    [self.locMgr stopUpdatingLocation];
}


/// 监听用户已经在设置中修改
/// @param manager manager description
/// @param status status description
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locMgr startUpdatingLocation];
    }else
    {
        if (self.getCurrentLocationBlock) {
            self.getCurrentLocationBlock(nil, @"无定位权限");
        }
        if (self.getCurrentLocationAndGEOBlock) {
            self.getCurrentLocationAndGEOBlock(nil, nil, @"无定位权限");
        }
    }
}

@end
