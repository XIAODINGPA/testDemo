//
//  BlueToothHelper.m
//  BodyScale
//
//  Created by August on 14-10-12.
//  Copyright (c) 2014年 August. All rights reserved.
//

#import "BlueToothHelper.h"

NSString *const selectUserSuccessAck = @"<080506a5";
NSString *const instanceMesureDataPrefix = @"<080706b001";
NSString *const selectUserMesureCompletePrefix = @"<081106b1";
NSString *const mesureCompleteExtraDataPrefix = @"<081006b1";//081006b1
NSString *const createNewUserCompleteDataPrefix = @"<080506a0";
NSString *const deleteExsitUserCompletePrefix = @"<080506a1";
NSString *const UpdateExistUserInfoCompletePrefix = @"<080506a2";
NSString *const GetAllUserInfosCompletePrefix = @"<081106b3";
NSString *const getAllUserInfoLastPrefix = @"<080d06b3";
NSString *const DeleteUserMesureDataCompletePrefix = @"<080506a7";
NSString *const ResetBodyScaleCompletePrefix = @"<080506af";
NSString *const GetBodyScaleSoftVersionCompletePrefix = @"<080506ae";
NSString *const GetBodyScaleBlueToothVersionCompletePrefix = @"<060506a0";

#define GetUserAckStringWith(index) [NSString stringWithFormat:@"090506b3%02ld",index]
#define StrToULong(string) strtoul([string UTF8String], 0, 16)

@interface BlueToothHelper ()

@property (nonatomic, strong) NSMutableArray *templeUsers;

@end

@implementation BlueToothHelper

#pragma mark - init methods

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        _peripherals = [NSMutableArray array];
        self.templeUsers = [NSMutableArray array];
    }
    return self;
}
+(instancetype)shareInstance
{
    static BlueToothHelper *blueToothHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blueToothHelper = [[BlueToothHelper alloc] init];
    });
    return blueToothHelper;
}

#pragma mark - private methdos
-(void)setNotifyOnForPeripheral:(CBPeripheral *)peripheral
{
    DLog(@"msg_lyywhg: peripheral ~%@", peripheral);
    CBService *service = [self findServiceInPeripheral:peripheral];
    if (service)
    {
        CBCharacteristic *characteristic = [self findCharacteristicWithUUID:NotifyCharactarID OnService:service];
        if (characteristic)
        {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}
-(CBService *)findServiceInPeripheral:(CBPeripheral *)peripheral
{
    for (CBService *service in peripheral.services)
    {
        DLog(@"msg_lyywhg:~ service %@", service.UUID.UUIDString);
        if ([service.UUID.UUIDString isEqual:ServiceID])
        {
            DLog(@"msg_lyywhg: discover service");
            return service;
        }
    }
    return nil;
}
-(CBCharacteristic *)findCharacteristicWithUUID:(NSString *)UUID OnService:(CBService *)service
{
    for (CBCharacteristic *c in service.characteristics)
    {
        if ([c.UUID.UUIDString isEqualToString:UUID])
        {
            return c;
        }
    }
    return nil;
}
#pragma mark - public methods
-(void)centralManagerChangedStateBlock:(void (^)(CBCentralManagerState))block
{
    _centerChangedStateBlock = block;
}
-(void)centralManagerScanPeripheralsWithBlock:(void (^)(NSArray *))block
{
    [self centralManagerScanPeripheralsWithSeviceUUIDS:nil completeBlock:block];
}
-(void)centralManagerScanPeripheralsWithSeviceUUIDS:(NSArray *)serviceUUIDs completeBlock:(void (^)(NSArray *))block
{
    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    _scanPeripheralsBlock = block;
}
-(void)centralManagerConnectToPeripheral:(CBPeripheral *)peripheral completeBlock:(void (^)(CBPeripheral *,NSError *))block
{
    NSAssert(peripheral != nil, @"will connect to a peripheral which should not be nil");
    [self.centralManager connectPeripheral:peripheral options:nil];
    _connectPeripheralBlock = block;
}
-(void)centralManagerCancelConnectPeripheral:(CBPeripheral *)peripheral comleteBlock:(void (^)(CBPeripheral *,NSError *))block
{
    NSAssert(peripheral != nil, @"will cancel connect a peripheral which should not be nil");
    [self.centralManager cancelPeripheralConnection:peripheral];
    _cancelConnectPeripheralBlock = block;
}
-(void)centralManagerSendData:(NSData *)data ToPeripheral:(CBPeripheral *)peripheral
{
    [self setNotifyOnForPeripheral:peripheral];
    CBService *service = [self findServiceInPeripheral:peripheral];
    if (service != nil)
    {
        CBCharacteristic *characteristic = [self findCharacteristicWithUUID:WriteCharactarID OnService:service];
        if (characteristic != nil)
        {
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    }
    else
    {
        DLog(@"msg_lyywhg: can't find service");
    }
}
-(void)centralManagerDidRecieveDataWithBlock:(void (^)(MeasureActionType, id , CBPeripheral *, NSError *))block
{
    _peripheralResponseBlock = block;
}
#pragma mark - CBCentralManagerDelegate methods
//状态更改
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    DLog(@"msg_lyywhg: Device State Change");
    _centerChangedStateBlock(central.state);
}
//发现外围
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceDiscover" object:self];
    if (![_peripherals containsObject:peripheral] && [peripheral.name.lowercaseString hasPrefix:@"cookst"])
    {
        NSData *manufacture = advertisementData[CBAdvertisementDataManufacturerDataKey];
        NSString *macString = [NSString stringWithFormat:@"%@",manufacture];
        macString = [macString stringByReplacingOccurrencesOfString:@" " withString:@""];
        macString = [macString substringWithRange:NSMakeRange(1, 12)];
        [peripheral setMAC:macString];
        [AppDelegate currentAppDelegate].deviceId = macString;
        [self setNotifyOnForPeripheral:peripheral];
        DLog(@"msg_lyywhg: find Device ~ data is %@ and services %@ and name %@",advertisementData, peripheral.services, peripheral.name);
        [_peripherals addObject:peripheral];
        peripheral.delegate = self;
        _scanPeripheralsBlock(_peripherals);

        if (self.peripherals.count > 0)
        {
            [self centralManagerConnectToPeripheral :self.peripherals[0] completeBlock:^(CBPeripheral *peripheral, NSError *error) {
                 DLog(@"msg_lyywhg: find Device ~ connect error is %@",error);
             }];
        }
    }
}
//连接
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    DLog(@"msg_lyywhg: Connect ~ %@", peripheral);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceConnectOK" object:self];
    [AppDelegate currentAppDelegate].connectType = 1;
    _connectedPeripheral = peripheral;
    _connectedPeripheral.delegate = self;
    [peripheral discoverServices:nil];
//    [_connectedPeripheral discoverServices:@[[CBUUID UUIDWithString:ServiceID]]];
    _connectPeripheralBlock(peripheral,nil);
}

//失去连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [AppDelegate currentAppDelegate].connectType = 2;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceDisConnectOK" object:self];
    DLog(@"msg_lyywhg: Disconnect ~ ");
    if (_cancelConnectPeripheralBlock)
    {
        DLog(@"msg_lyywhg: Disconnect ~ error %@", error);
        _cancelConnectPeripheralBlock(peripheral,error);
    }
}
//连接失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [AppDelegate currentAppDelegate].connectType = 3;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceConnectFail" object:self];
    DLog(@"msg_lyywhg: FailToConnect ~ error %@", error);
    _connectPeripheralBlock(peripheral,error);
}

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
}
-(void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
}
-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
}
#pragma mark - CBPeripheralDelegate methdos
-(void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (peripheral.services.count > 0)
    {
        DLog(@"msg_lyywhg: discover service ~ %s %@",__PRETTY_FUNCTION__,peripheral.services);
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:WriteCharactarID],[CBUUID UUIDWithString:NotifyCharactarID]] forService:peripheral.services[0]];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
}
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
}
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSString *tString = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSString *str = [NSString stringWithFormat:@"%@",characteristic.value];
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    DLog(@"msg_lyywhg: Update Value str is %@ %@",str, tString);
    if ([str hasPrefix:selectUserSuccessAck])
    {
        _peripheralResponseBlock(selectUserMesureAck,nil,peripheral,error);
    }
    else if ([str hasPrefix:instanceMesureDataPrefix])
    {
        str = [str substringWithRange:NSMakeRange(str.length-5, 4)];
        unsigned long result = strtoul([str UTF8String], 0, 16);
        _peripheralResponseBlock(InstanceWeight,@(result/20),peripheral,error);
    }
    else if ([str hasPrefix:selectUserMesureCompletePrefix])
    {
        NSString *waterStr = [str substringWithRange:NSMakeRange(str.length-5, 4)];
        unsigned long water = strtoul([waterStr UTF8String], 0, 16);

        NSString *fatStr = [str substringWithRange:NSMakeRange(str.length-9, 4)];
        unsigned long fat = strtoul([fatStr UTF8String], 0, 16);

        NSString *weightStr = [str substringWithRange:NSMakeRange(str.length-13, 4)];
        unsigned long weight = strtoul([weightStr UTF8String], 0, 16);

        DLog(@"msg_lyywhg: Update Value Ok");

        _peripheralResponseBlock(selectUserMesureComplpete,@{@"water":@(water/10.0), @"bodyFat":@(fat/10.0), @"weight":@(weight/200.0)},peripheral,error);
        
        //test
//        NSString *dataStr = [NSString stringWithFormat:@"090501b1010109%@",[str substringWithRange:NSMakeRange(str.length - 21, 20)]];
        NSString *dataStr = @"090506b101";
        NSData *cmdData = hexToBytes(dataStr);
        
        [self centralManagerSendData:cmdData ToPeripheral:self.connectedPeripheral];
    }
    else if ([str hasPrefix:mesureCompleteExtraDataPrefix])
    {
//        NSString *AMRStr = [str substringWithRange:NSMakeRange(str.length-5, 4)];
//        unsigned long AMR = strtoul([AMRStr UTF8String], 0, 16);
        
        NSString *bodyAgeStr = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long bodyAge = strtoul([bodyAgeStr UTF8String], 0, 16);

        NSString *inFatStr = [str substringWithRange:NSMakeRange(str.length-5, 2)];
        unsigned long inFat = strtoul([inFatStr UTF8String], 0, 16);
        
        NSString *SFatStr = [str substringWithRange:NSMakeRange(str.length-9, 4)];
        unsigned long SFat = strtoul([SFatStr UTF8String], 0, 16);

        NSString *BMRStr = [str substringWithRange:NSMakeRange(str.length-13, 4)];
        unsigned long BMR = strtoul([BMRStr UTF8String], 0, 16);

        NSString *BoneStr = [str substringWithRange:NSMakeRange(str.length-15, 2)];
        unsigned long bone = strtoul([BoneStr UTF8String], 0, 16);

        NSString *muscleStr = [str substringWithRange:NSMakeRange(str.length-19, 4)];
        unsigned long muscle = strtoul([muscleStr UTF8String], 0, 16);

        _peripheralResponseBlock(selectUserMesureComplpeteExtra,@{@"bodyAge":@(bodyAge), @"inFat":@(inFat), @"sFat":@(SFat), @"BMR":@(BMR), @"bone":@(bone/10), @"muscle":@(muscle/10)},peripheral,error);
        //test
//        NSString *dataStr = [NSString stringWithFormat:@"090501b1020209%@",[str substringWithRange:NSMakeRange(str.length - 23, 20)]];
        NSString *dataStr = @"090506b102";
        NSData *cmdData = hexToBytes(dataStr);
        
        [self centralManagerSendData:cmdData ToPeripheral:self.connectedPeripheral];
    }
    else if ([str hasPrefix:createNewUserCompleteDataPrefix])
    {
        NSString *locationString = [str substringWithRange:NSMakeRange(str.length - 3, 2)];
        unsigned long location = strtoul([locationString UTF8String], 0, 16);
        _peripheralResponseBlock(CreateNewUser,@{@"location":@(location)},peripheral,error);
    }
    else if ([str hasPrefix:deleteExsitUserCompletePrefix])
    {
        NSString *statusCodeStr = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long statusCode = strtoul([statusCodeStr UTF8String], 0, 16);
        _peripheralResponseBlock(DeleteExistUser,@{@"status":@(statusCode)},peripheral,error);
    }
    else if ([str hasPrefix:UpdateExistUserInfoCompletePrefix])
    {
        NSString *statusCodeStr = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long statusCode = strtoul([statusCodeStr UTF8String], 0, 16);
        _peripheralResponseBlock(UpdateExistUserInfo,@{@"status":@(statusCode)},peripheral,error);
    }
    else if ([str hasPrefix:GetAllUserInfosCompletePrefix] || [str hasPrefix:getAllUserInfoLastPrefix])
    {
        NSString *indexStr = [str substringWithRange:NSMakeRange(9, 2)];
        unsigned long index = strtoul([indexStr UTF8String], 0, 16);
        switch (index)
        {
            case 1:
            {
                [self.templeUsers removeAllObjects];
                NSString *user3 = [str substringWithRange:NSMakeRange(str.length-9, 8)];
                NSString *user2 = [str substringWithRange:NSMakeRange(str.length-17, 8)];
                NSString *user1 = [str substringWithRange:NSMakeRange(str.length-25, 8)];
                DLog(@"user1 %@\n%@\n%@",user1,user2,user3);
                
                [self transformToUserInfosWithString:user1 location:1];
                [self transformToUserInfosWithString:user2 location:2];
                [self transformToUserInfosWithString:user3 location:3];
                NSString *ackString = GetUserAckStringWith(index);
                [self centralManagerSendData:hexToBytes(ackString) ToPeripheral:self.connectedPeripheral];
            }
                break;
            case 2:
            {
                NSString *user3 = [str substringWithRange:NSMakeRange(str.length-9, 8)];
                NSString *user2 = [str substringWithRange:NSMakeRange(str.length-17, 8)];
                NSString *user1 = [str substringWithRange:NSMakeRange(str.length-25, 8)];
                [self transformToUserInfosWithString:user1 location:4];
                [self transformToUserInfosWithString:user2 location:5];
                [self transformToUserInfosWithString:user3 location:6];
                NSString *ackString = GetUserAckStringWith(index);
                [self centralManagerSendData:hexToBytes(ackString) ToPeripheral:self.connectedPeripheral];
            }
                break;
            case 3:
            {
                NSString *user2 = [str substringWithRange:NSMakeRange(str.length-9, 8)];
                NSString *user1 = [str substringWithRange:NSMakeRange(str.length-17, 8)];
                [self transformToUserInfosWithString:user1 location:7];
                [self transformToUserInfosWithString:user2 location:8];
                
                _peripheralResponseBlock(GetAllUserInfos,self.templeUsers,peripheral,error);
            }
                break;
            default:
                break;
        }
    }
    else if ([str hasPrefix:DeleteUserMesureDataCompletePrefix])
    {
        NSString *errorString = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long errorCode = StrToULong(errorString);
        NSError *err = errorCode == 1 ? nil:[NSError errorWithDomain:@"" code:3 userInfo:@{@"delete error":@"user is not exist"}];
        _peripheralResponseBlock(DeleteUserMeasureData,err,peripheral,error);
    }
    else if ([str hasPrefix:ResetBodyScaleCompletePrefix])
    {
        NSString *errorString = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long errorCode = StrToULong(errorString);
        NSError *err = errorCode == 1 ? nil:[NSError errorWithDomain:@"" code:3 userInfo:@{@"reset error":@"some unkonow error"}];
        _peripheralResponseBlock(ResetBodyScale,err,peripheral,error);
    }
    else if ([str hasPrefix:GetBodyScaleSoftVersionCompletePrefix])
    {
        NSString *versionString = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long version = StrToULong(versionString);
        _peripheralResponseBlock(DeleteUserMeasureData,@(version),peripheral,error);

    }
    else if ([str hasPrefix:GetBodyScaleBlueToothVersionCompletePrefix])
    {
        NSString *versionString = [str substringWithRange:NSMakeRange(str.length-3, 2)];
        unsigned long version = StrToULong(versionString);
        _peripheralResponseBlock(DeleteUserMeasureData,@(version),peripheral,error);
    }
}
-(void)transformToUserInfosWithString:(NSString *)string location:(NSUInteger)location
{
    NSString *userNum = [string substringWithRange:NSMakeRange(0, 2)];
    unsigned long num = strtoul([userNum UTF8String], 0, 16);
    if (num)
    {
        NSString *height = [string substringWithRange:NSMakeRange(2, 2)];
        NSString *age = [string substringWithRange:NSMakeRange(4, 2)];
        NSString *sex = [string substringWithRange:NSMakeRange(6, 2)];
        
        NSDictionary *info = @{@"location":@(location), @"height":@(StrToULong(height)), @"age":@(StrToULong(age)), @"sex":@(StrToULong(sex))};
        [self.templeUsers addObject:info];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    DLog(@"msg_lyywhg: Discover Characteristics ~ error %@",error);
    if (error==nil)
    {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:NotifyCharactarID]])
            {
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    DLog(@"msg_lyywhg: Update Notification ~ error %@",error);
    if (error==nil)
    {
        [peripheral readValueForCharacteristic:characteristic];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error
{
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
}

@end