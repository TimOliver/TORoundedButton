//
//  ViewController.m
//  TORoundedButtonExample
//
//  Created by Tim Oliver on 21/4/19.
//  Copyright © 2019 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TORoundedButton.h"
#import "TableViewCell.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSString *title = nil;
    TORoundedButton *button = cell.button;

    button.tappedTintColor = nil;
    button.tappedButtonScale = 0.0f;

    switch (indexPath.row) {
        case 0:
            title = @"Default";
            break;
        case 1:
            title = @"Background Fade";
            button.tappedTintColor = [UIColor colorWithRed:0.0f green:0.41f blue:0.85f alpha:1.0f];
            break;
        case 2:
            title = @"Scale Inset";
            button.tappedButtonScale = 0.95f;
            break;
        case 3:
            title = @"All Effects";
            button.tappedButtonScale = 0.95f;
            button.tappedTintColor = [UIColor colorWithRed:0.0f green:0.41f blue:0.85f alpha:1.0f];
            break;
    }
    cell.titleLabel.text = title;


    return cell;
}

@end
