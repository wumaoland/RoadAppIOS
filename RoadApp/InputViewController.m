//
//  InputViewController.m
//  RoadApp
//
//  Created by devil2010 on 12/28/16.
//  Copyright © 2016 admin2. All rights reserved.
//

#import "InputViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "Utilities.h"
#import "Constant.h"
#import "InputImageForCell.h"
#import "WYPopoverController.h"
#import "DataTypeItemModel.h"
#import "DataTypeItemDb.h"
#import "ImageModel.h"
#import "ImageDb.h"

static int const CATEGORY_TEXTFIELD_PICKER_TAG = 1;
static int const STATUS_TEXTFIELD_PICKER_TAG = 2;
static int const INFOR_TEXTFIELD_INPUT_TAG = 3;
static int const LYTRINH_TEXTFIELD_INPUT_TAG = 4;

@implementation InputViewController{
    bool firstLocationUpdate;
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    UIPickerView *pickerCategory, *pickerStatus;
    UIToolbar *accessoryView;
    int currentEdit;
    NSMutableArray *dataList, *imageList;
    NSArray *categoryList, *statusList;
    UITextField *focusedTextfield;
    CGPoint contentOffset;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    firstLocationUpdate = NO;
    [self setTitle:_dataItemModel.ItemName];
    [self initGoogleMap];
    [_cvInput registerNib:[UINib nibWithNibName:@"InputViewCell" bundle:nil] forCellWithReuseIdentifier:@"InputViewCell"];
    [self initPickerAndTable];
    
    [self initFirstData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self deregisterFromKeyboardNotifications];
}

- (void) initFirstData{
    currentEdit = 0;
    
    // data for datatype
    dataList = [[NSMutableArray alloc] init];
    DataTypeItemModel *firstDataTypeItem = [[DataTypeItemModel alloc] init];
    firstDataTypeItem.DataID = [Utilities generateUUID];
    [dataList addObject:firstDataTypeItem];
    [_cvInput reloadData];
    
    // data for image
    imageList = [[NSMutableArray alloc] init];
    NSMutableArray *firstImgArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *imgDict = [[NSMutableDictionary alloc] init];
    [imgDict setValue:firstDataTypeItem.DataID  forKey:@"UUID"];
    [imgDict setValue:firstImgArr forKey:@"imageData"];

    [imageList addObject:imgDict];
    
    
    // data for picker
    NSMutableDictionary* dictPickerItem = [Utilities dataFromPlist:(int) _dataItemModel.ItemID];
    categoryList = [[NSArray alloc] initWithArray:[dictPickerItem objectForKey:@"category"]];
    statusList = [[NSArray alloc] initWithArray:[dictPickerItem objectForKey:@"status"]];
    
}
#pragma mark - table


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return dataList.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    InputViewCell *cell = (InputViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"InputViewCell" forIndexPath:indexPath];
    
    cell.rootVIew.layer.cornerRadius = 12.0f;
    [cell.rootVIew setBackgroundColor:[Utilities colorFromHexString:INPUT_COLOR]];
    
    cell.pkRequiredItem.inputView = pickerCategory;
    cell.pkRequiredItem.inputAccessoryView = accessoryView;
    cell.pkRequiredItem.delegate = self;
    cell.pkRequiredItem.tag = CATEGORY_TEXTFIELD_PICKER_TAG;
    
    cell.pkStatusItem.inputView = pickerStatus;
    cell.pkStatusItem.inputAccessoryView = accessoryView;
    cell.pkStatusItem.delegate = self;
    cell.pkStatusItem.tag = STATUS_TEXTFIELD_PICKER_TAG;
    
    
    cell.tfInfor.tag = INFOR_TEXTFIELD_INPUT_TAG;
    cell.tfLyTrinh.tag = LYTRINH_TEXTFIELD_INPUT_TAG;
    [cell.tfInfor addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    [cell.tfLyTrinh addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    

    if(indexPath.row == dataList.count - 1)
        [cell.btnAdd setHidden:NO];
    else
        [cell.btnAdd setHidden:YES];
    
    DataTypeItemModel *itemModel = [dataList objectAtIndex:indexPath.row];
    cell.pkRequiredItem.text = itemModel.DataTypeName ? itemModel.DataTypeName : @"";
    cell.pkStatusItem.text = itemModel.DanhGia ? itemModel.DanhGia : @"";
    cell.tfInfor.text = itemModel.MoTaTinhTrang ? itemModel.MoTaTinhTrang : @"";
    cell.tfLyTrinh.text = itemModel.LyTrinh ? itemModel.LyTrinh : @"";
    
    cell.indexPath = indexPath;
    cell.delegate = self;
    return cell;

}

//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
//{
//    // Add inset to the collection view if there are not enough cells to fill the width.
//    CGFloat cellSpacing = ((UICollectionViewFlowLayout *) collectionViewLayout).minimumLineSpacing;
//    CGFloat cellWidth = ((UICollectionViewFlowLayout *) collectionViewLayout).itemSize.width;
//    NSInteger cellCount = [collectionView numberOfItemsInSection:section];
//    CGFloat inset = (collectionView.bounds.size.width - (cellCount * (cellWidth + cellSpacing))) * 0.5;
//    inset = MAX(inset, 0.0);
//    return UIEdgeInsetsMake(0.0, inset, 0.0, 0.0);
//}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(self.view.frame.size.width, 230);
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    float currentPage = _cvInput.contentOffset.x / _cvInput.frame.size.width;
    currentEdit = ceil(currentPage);
    NSLog(@"Values:%d",currentEdit);
}

#pragma InputCell delegate
- (void)addMoreInput{
    if(![self checkValidateInput:[dataList lastObject] atIndex:((int) dataList.count - 1)])
        return;
    
    DataTypeItemModel *moreDataTypeItem = [[DataTypeItemModel alloc] init];
    moreDataTypeItem.DataID = [Utilities generateUUID];
    [dataList addObject:moreDataTypeItem];
    [_cvInput reloadData];
    
    NSMutableArray *firstImgArr = [[NSMutableArray alloc] init];
    NSMutableDictionary *imgDict = [[NSMutableDictionary alloc] init];
    [imgDict setValue:moreDataTypeItem.DataID  forKey:@"UUID"];
    [imgDict setValue:firstImgArr forKey:@"imageData"];
    [imageList addObject:imgDict];
    
    [self.view layoutIfNeeded];
    [_cvInput scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:dataList.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    currentEdit = currentEdit + 1;
}

-(void) addImageAt:(NSIndexPath *)indexPath withView:(UIView *) view{
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    InputImageForCell *inputImage = [storyboard instantiateViewControllerWithIdentifier:@"InputImageForCell"];
//    popOver = [[WYPopoverController alloc] initWithContentViewController:inputImage];
//    [inputImage setModalPresentationStyle:UIModalPresentationOverCurrentContext];
//    [popOver presentPopoverFromRect:view.bounds
//                             inView:view
//           permittedArrowDirections:WYPopoverArrowDirectionAny
//                           animated:YES
//                            options:WYPopoverAnimationOptionFadeWithScale];
//    [popOver presentPopoverAsDialogAnimated:YES options:WYPopoverAnimationOptionFadeWithScale];
//    [self.navigationController presentViewController:inputImage animated:YES completion:nil];
//    [self.navigationController pushViewController:inputImage animated:YES];
    currentEdit = (int)indexPath.row;
    inputImage.delegate = self;
    inputImage.UUID = [[imageList objectAtIndex:currentEdit] objectForKey:@"UUID"];
    inputImage.data = [[imageList objectAtIndex:currentEdit] objectForKey:@"imageData"];
    [self presentViewController:inputImage animated:YES completion:nil];
}
#pragma mark - textfield delegate

- (void)textDidChange:(UITextField *)sender {
    NSString *targetText = sender.text;
    DataTypeItemModel *model = [dataList objectAtIndex:currentEdit];
    if(sender.tag == LYTRINH_TEXTFIELD_INPUT_TAG){
        model.LyTrinh = targetText;
    }else if(sender.tag == INFOR_TEXTFIELD_INPUT_TAG){
        model.MoTaTinhTrang = targetText;
    }
    [dataList replaceObjectAtIndex:currentEdit withObject:model];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    focusedTextfield = textField;
    if(focusedTextfield) {
        if(focusedTextfield.tag == CATEGORY_TEXTFIELD_PICKER_TAG){
            [pickerCategory selectRow:0 inComponent:0 animated:NO];
        }else if(focusedTextfield.tag == STATUS_TEXTFIELD_PICKER_TAG){
            [pickerStatus selectRow:0 inComponent:0 animated:NO];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField.tag == CATEGORY_TEXTFIELD_PICKER_TAG || textField.tag == STATUS_TEXTFIELD_PICKER_TAG){
        return NO;
    }
    return YES;
}


#pragma mark - keyboardDelegate
- (void)registerForKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if (self.view.frame.origin.y >= 0) {
        
        [UIView animateWithDuration:0.5 animations:^{
            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - 224, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    if (self.view.frame.origin.y < 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + 224, self.view.frame.size.width, self.view.frame.size.height);
        }];
        
    }
}

#pragma mark -  picker
- (void) initPickerAndTable{
    pickerCategory = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, 320, 180)];
    [pickerCategory setDataSource:self];
    [pickerCategory setDelegate:self];
    [pickerCategory setShowsSelectionIndicator:YES];
    [pickerCategory setBackgroundColor:[UIColor whiteColor]];
    
    
    pickerStatus = [[UIPickerView alloc]initWithFrame:CGRectMake(0, 0, 320, 180)];
    [pickerStatus setDataSource:self];
    [pickerStatus setDelegate:self];
    [pickerStatus setShowsSelectionIndicator:YES];
    [pickerStatus setBackgroundColor:[UIColor whiteColor]];
    
    if ( accessoryView == nil ) {
        accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                    target:self
                                                                                    action:@selector(doneButton:)];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelButton)];
        [accessoryView setItems:@[doneButton, cancelButton]];
        [accessoryView setBackgroundColor:[Utilities colorFromHexString:INPUT_COLOR]];
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)doneButton:(id)sender{
    [self.view endEditing:YES];
    DataTypeItemModel *model = [dataList objectAtIndex:currentEdit];
    if(focusedTextfield) {
        if(focusedTextfield.tag == CATEGORY_TEXTFIELD_PICKER_TAG){
            int selectedIndex;
            if([pickerCategory selectedRowInComponent:0])
                selectedIndex = (int)[pickerCategory selectedRowInComponent:0];
            else
                selectedIndex = 0;
            /*
             dont know why picker first item selected return nil??
             */
            focusedTextfield.text = [categoryList objectAtIndex:selectedIndex];
            model.DataType = [Utilities getDataTypeByItemId:(selectedIndex + 1)];
            model.DataTypeName = focusedTextfield.text;
        }else if(focusedTextfield.tag == STATUS_TEXTFIELD_PICKER_TAG){
            focusedTextfield.text = [statusList objectAtIndex:[pickerStatus selectedRowInComponent:0]];
            model.DanhGia = focusedTextfield.text;
        }
    }
    [dataList replaceObjectAtIndex:currentEdit withObject:model];
}

- (void)cancelButton{
    [self.view endEditing:YES];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if(pickerView == pickerCategory){
        return [categoryList count];
    }else {
        return [statusList count];
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(pickerView == pickerCategory){
        return [categoryList objectAtIndex:row];
    }else {
        return [statusList objectAtIndex:row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    [[self view] endEditing:YES];
}

#pragma mark - Location

- (void) initGoogleMap{
    _mapView.myLocationEnabled = YES;
    _mapView.mapType = kGMSTypeNormal;
    _mapView.settings.compassButton = YES;
    _mapView.settings.myLocationButton = YES;
    _mapView.delegate = self;
    
    
    geocoder = [[CLGeocoder alloc] init];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate =  self ;
    if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]){
        [locationManager requestWhenInUseAuthorization];
        [locationManager requestAlwaysAuthorization];
    }
    
    [locationManager startUpdatingLocation];
}
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(!firstLocationUpdate){
        
        NSLog(@"updated location");
        firstLocationUpdate = YES;
        currentLocation = newLocation;
        [_mapView animateToLocation:newLocation.coordinate];
        _mapView.camera = [GMSCameraPosition cameraWithTarget:newLocation.coordinate zoom:14];
        [locationManager stopUpdatingLocation];
        
        [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error == nil && [placemarks count] > 0) {
                placemark = [placemarks lastObject];
                
                // strAdd -> take bydefault value nil
                NSString *strAdd = nil;
                
                if ([placemark.subThoroughfare length] != 0)
                    strAdd = placemark.subThoroughfare;
                
                if ([placemark.thoroughfare length] != 0)
                {
                    // strAdd -> store value of current location
                    if ([strAdd length] != 0)
                        strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark thoroughfare]];
                    else
                    {
                        // strAdd -> store only this value,which is not null
                        strAdd = placemark.thoroughfare;
                    }
                }
                
                if ([placemark.postalCode length] != 0)
                {
                    if ([strAdd length] != 0)
                        strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
                    else
                        strAdd = placemark.postalCode;
                }
                
                if ([placemark.locality length] != 0)
                {
                    if ([strAdd length] != 0)
                        strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark locality]];
                    else
                        strAdd = placemark.locality;
                }
                
                if ([placemark.administrativeArea length] != 0)
                {
                    if ([strAdd length] != 0)
                        strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark administrativeArea]];
                    else
                        strAdd = placemark.administrativeArea;
                }
                
                if ([placemark.country length] != 0)
                {
                    if ([strAdd length] != 0)
                        strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark country]];
                    else
                        strAdd = placemark.country;
                }
                _lbLocation.text = strAdd;
                [_lbLocation sizeToFit];
            } else {
                NSLog(@"find location error: %@", error.debugDescription);
            }
        } ];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didUpdateToLocation: didChangeAuthorizationStatus");
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
        }break;
        default:{
            [locationManager startUpdatingLocation];
        }break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

#pragma mark - image delegate
-(void)doneAddImage:(NSMutableArray *)dataListArr withUUID:(NSString *)UUID{
    NSMutableDictionary *imgDict = [[NSMutableDictionary alloc] init];
    [imgDict setObject:UUID forKey:@"UUID"];
    [imgDict setObject:dataListArr forKey:@"imageData"];
    [imageList replaceObjectAtIndex:currentEdit withObject:imgDict];
}

- (IBAction)saveData:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Warning!"
                                                                   message:@"Click OK to finish, dismiss to cancel action."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              if(!currentLocation){
                                                                  [Utilities showSimpleAlert:@"Hệ thống không định vị được vị trí của bạn, thử ấn vào tìm vị trí trên bản đồ trước!"];
                                                                  return;
                                                              }else{
                                                                  for(int i = 0; i < dataList.count; i++){
                                                                      DataTypeItemModel *model = [dataList objectAtIndex:i];
                                                                      if(![self checkValidateInput:model atIndex:i])
                                                                          return;
                                                                      
                                                                      if(currentLocation) {
                                                                          model.KinhDo = currentLocation.coordinate.latitude;
                                                                          model.ViDo = currentLocation.coordinate.longitude;
                                                                      }
                                                                      
                                                                      for(NSMutableDictionary *imgDict in imageList){
                                                                          NSMutableArray *arrImg = [imgDict objectForKey:@"imageData"];
                                                                          for(NSMutableDictionary *dict in arrImg){
                                                                              if([[imgDict objectForKey:@"UUID"] isEqualToString:model.DataID]){
                                                                                  ImageModel *imageModel = [[ImageModel alloc] init];
                                                                                  imageModel.DataID = [imgDict objectForKey:@"UUID"];
                                                                                  imageModel.ImageName = [dict objectForKey:@"path"];
                                                                                  imageModel.ImageDataByte = @"";
                                                                                  [ImageDb saveImageModel:imageModel];
                                                                              }
                                                                          }
                                                                      }
                                                                      
                                                                      [DataTypeItemDb saveDataTypeItem:model];
                                                                  }
                                                              }
                                                              
                                                              
                                                              
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                          }];
    
    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL) checkValidateInput:(DataTypeItemModel *)itemModel atIndex:(int) index{
    if(!itemModel.DataTypeName){
        [Utilities showSimpleAlert:@"Mục cần nhập không được bỏ trống."];
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        InputViewCell *cell = (InputViewCell *)[_cvInput cellForItemAtIndexPath:currentIndexPath];
        [_cvInput scrollToItemAtIndexPath:currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        [Utilities shakeView:cell.pkRequiredItem withInfinity:NO];
        return NO;
    }
    
    if(!itemModel.DanhGia){
        [Utilities showSimpleAlert:@"Mục tình trạng không được bỏ trống."];
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        InputViewCell *cell = (InputViewCell *)[_cvInput cellForItemAtIndexPath:currentIndexPath];
        [_cvInput scrollToItemAtIndexPath:currentIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        [Utilities shakeView:cell.pkStatusItem withInfinity:NO];
        return NO;
    }
    return YES;
}

@end
