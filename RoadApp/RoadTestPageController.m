//
//  RoadTestPageController.m
//  RoadApp
//
//  Created by admin2 on 12/26/16.
//  Copyright © 2016 admin2. All rights reserved.
//

#import "RoadTestPageController.h"
#import "RoadTestCell.h"
#import "Constant.h"
#import "Utilities.h"

@interface RoadTestPageController (){
    int widthSize, heightSize;
}

@end

@implementation RoadTestPageController

- (void)viewDidLoad{
    [super viewDidLoad];
    widthSize = ([UIScreen mainScreen].bounds.size.width - 10 * 5 ) / 3;
    heightSize = ([UIScreen mainScreen].bounds.size.width - 10 * 5 ) / 3;
}

- (void) changeDisplayItemMode{
    _isList = !_isList;
    widthSize = _isList ? [UIScreen mainScreen].bounds.size.width - 10 * 2  : ([UIScreen mainScreen].bounds.size.width - 10 * 5 ) / 3;
    [_cvItem reloadData];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    RoadTestCell *cell = (RoadTestCell*) [collectionView dequeueReusableCellWithReuseIdentifier:@"RoadTestCell" forIndexPath:indexPath];
    cell.layer.cornerRadius =  5.0f;
    cell.layer.masksToBounds = YES;
    cell.backgroundColor = [Utilities colorFromHexString:GRAY_COLOR];
    cell.tfTitle.text = @"test";
    return cell;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 18;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(widthSize, heightSize);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    RoadTestCell *cell = (RoadTestCell *) [collectionView cellForItemAtIndexPath:indexPath];
    [UIView beginAnimations:@"showImage" context:Nil];
    CGRect cellFrame = cell.frame;
    CGRect imgFram = cell.frame;
    [UIView setAnimationDuration:0.8];
    [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:cell
                             cache:YES];
    cellFrame.size = CGSizeMake(200, 200);
    cellFrame.origin.y = 10;
    cellFrame.origin.x = 45;
    cell.frame = cellFrame;
    imgFram.size = CGSizeMake(200, 200);
    cell.frame = imgFram;
    [collectionView bringSubviewToFront:cell];
    [UIView commitAnimations];
}

@end