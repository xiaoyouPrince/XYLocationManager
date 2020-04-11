//
//  ViewController.m
//  XYLocationManager
//
//  Created by 渠晓友 on 2020/4/11.
//  Copyright © 2020 渠晓友. All rights reserved.
//

#import "ViewController.h"
#import "XYLocationManager.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *btns;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

/** 保存当前地点 */
@property (nonatomic, strong)       CLLocation *currentLocation;
/** 天安门地点 */
@property (nonatomic, strong)       CLLocation *tamLocation;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    int i = 0;
    for (UIButton *btn in self.btns) {
        btn.tag = i;
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        i++;
    }
    
    int j = 0;
    for (UILabel *label in self.labels) {
        label.tag = j;
        j++;
    }
    
}

- (void)btnClick:(UIButton *)sender{
    
    NSInteger tag = sender.tag;
    UILabel *label = self.labels[tag];
    
    switch (tag) {
        case 0:
        {
            [XYLocationManager getCurrentLocation:^(CLLocation * _Nonnull currentLocation, NSString * _Nonnull errorMsg) {
                if (errorMsg) {
                    label.text = errorMsg;
                }else
                {
                    label.text = currentLocation.description;
                    self.currentLocation = currentLocation;
                }
            }];
        }
            break;
        case 1:
        {
            label.text = @"努力加载中。。。。";
            [XYLocationManager getCurrentLocationAndGEO:^(CLLocation * _Nonnull currentLocation, CLPlacemark * _Nonnull placemark, NSString * _Nonnull errorMsg) {
                if (errorMsg) {
                    label.text = errorMsg;
                }else
                {
                    label.text = [currentLocation.description stringByAppendingFormat:@"\n%@",placemark.description];
                }
            }];
        }
            break;
        case 2:
        {
            [XYLocationManager reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (error) {
                    label.text = error.description;
                }else
                {
                    label.text = placemarks.firstObject.description;
                }
            }];
        }
            break;
        case 3:
        {
            [XYLocationManager geocodeAddressString:@"北京天安门" completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
                if (error) {
                    label.text = error.description;
                }else
                {
                    label.text = placemarks.firstObject.description;
                    self.tamLocation = placemarks.firstObject.location;
                }
            }];
        }
            break;
        case 4:
        {
            if (!self.currentLocation) {
                label.text = @"请先获取第一步，定位当前位置";
                return;
            }
            if (!self.tamLocation) {
                label.text = @"请先反编码北京天安门";
                return;
            }
            if ([XYLocationManager isLocation:self.currentLocation inRegion:self.tamLocation radius:1000]) {
                label.text = @"你在天安门一公里范围内";
            }else
            {
                label.text = @"你不在天安门一公里范围内";
            }
        }
            break;
            
        default:
            break;
    }
}


@end
