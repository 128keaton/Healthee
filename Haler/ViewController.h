//
//  ViewController.h
//  Haler
//
//  Created by Keaton Burleson on 6/16/14.
//  Copyright (c) 2014 BitTank. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
@interface ViewController : UITableViewController <UITextFieldDelegate>{
    
    IBOutlet UITextField  *puffs;
    IBOutlet UILabel *info;
    IBOutlet UITextField *type;
    IBOutlet UITextField *weightf;
    IBOutlet UILabel *weightstats;
    
}
@property (nonatomic) HKHealthStore *healthStore;



@end

