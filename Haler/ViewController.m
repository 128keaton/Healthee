//
//  ViewController.m
//  Haler
//
//  Created by Keaton Burleson on 6/16/14.
//  Copyright (c) 2014 BitTank. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
            

@end

@implementation ViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update the user interface based on the current user's health information.
    [self updateUsage];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    weightf.delegate = self;
    puffs.delegate = self;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveTheWorld {
    NSNumberFormatter *formatter = [self numberFormatter];
    NSNumber *usage = [formatter numberFromString:puffs.text];
    
 
    
    if (usage) {
        info.text =  [NSString stringWithFormat:@"I have used my inhaler %@ times today", puffs.text];
        HKQuantityType *healthType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierInhalerUsage];
        HKQuantity *usageQuantity = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:[usage doubleValue]];
        HKQuantitySample *usageFinal = [HKQuantitySample quantitySampleWithType:healthType quantity:usageQuantity startDate:[NSDate date] endDate:[NSDate date]];
        
        [self.healthStore saveObject:usageFinal withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"An error occured saving the height sample %@. In your app, try to handle this gracefully. The error was: %@.", usageFinal, error);
                abort();
            }
            
        }];
    }
}

- (void)saveWeightIntoHealthStore {
    NSNumberFormatter *formatter = [self numberFormatter];
    NSNumber *weight = [formatter numberFromString:weightf.text];
    
    if (!weight && [weightf.text length]) {
        NSLog(@"The weight entered is not numeric. In your app, try to handle this gracefully.");
        abort();
    }
    
    if (weight) {
        weightstats.text =  [NSString stringWithFormat:@"I weigh %@ pounds today.", weightf.text];

        // Save the user's weight into HealthKit.
        HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
        HKQuantity *weightQuantity = [HKQuantity quantityWithUnit:[HKUnit poundUnit] doubleValue:[weight doubleValue]];
        HKQuantitySample *weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:[NSDate date] endDate:[NSDate date]];
        
        [self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"An error occured saving the weight sample %@. In your app, try to handle this gracefully. The error was: %@.", weightSample, error);
                abort();
                
            }
            
        }];
    }
}



- (void)updateUsersWeight {
    // Fetch the user's default weight unit in pounds.
    NSMassFormatter *massFormatter = [[NSMassFormatter alloc] init];
    massFormatter.unitStyle = NSFormattingUnitStyleLong;
    

    
    // Query to get the user's latest weight, if it exists.
    HKQuantityType *weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    [self fetchMostRecentDataOfQuantityType:weightType withCompletion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (error) {
            NSLog(@"An error occured fetching the user's weight information. In your app, try to handle this gracefully. The error was: %@.", error);
            abort();
        }
        
        // Determine the weight in the required unit.
        double usersWeight = 0.0;
        
        if (mostRecentQuantity) {
            HKUnit *weightUnit = [HKUnit poundUnit];
            usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
               weightstats.text = [NSString stringWithFormat:@"I weigh %@ pounds today.",[NSNumberFormatter localizedStringFromNumber:@(usersWeight) numberStyle:NSNumberFormatterNoStyle]];
            });
        }
    }];
}



- (void)updateUsage {
    // Fetch the user's default weight unit in pounds.
  
    
    
    // Query to get the user's latest weight, if it exists.
    HKQuantityType *usageType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierInhalerUsage];
    [self fetchMostRecentDataOfQuantityType:usageType withCompletion:^(HKQuantity *mostRecentQuantity, NSError *error) {
        if (error) {
            NSLog(@"An error occured fetching the user's weight information. In your app, try to handle this gracefully. The error was: %@.", error);
            abort();
        }
        
        // Determine the weight in the required unit.
        double usageCount = 0.0;
        
        if (mostRecentQuantity) {
            HKUnit *usageUnit = [HKUnit countUnit];
            usageCount = [mostRecentQuantity doubleValueForUnit:usageUnit];
            
            // Update the user interface.
            dispatch_async(dispatch_get_main_queue(), ^{
               puffs.text = [NSNumberFormatter localizedStringFromNumber:@(usageCount) numberStyle:NSNumberFormatterNoStyle];
                info.text =  [NSString stringWithFormat:@"I have used my inhaler %@ times today", puffs.text];
            });
        }
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == puffs) {
          [self saveTheWorld];
    }else if (textField == weightf){
        [self saveWeightIntoHealthStore];
        NSLog(@"Update weight");
    }
    
    
    
    return YES;
}

// Get the single most recent quantity sample from health store.
- (void)fetchMostRecentDataOfQuantityType:(HKQuantityType *)quantityType withCompletion:(void (^)(HKQuantity *mostRecentQuantity, NSError *error))completion {
    NSSortDescriptor *timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    // Since we are interested in retrieving the user's latest sample, we sort the samples in descending order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil limit:1 sortDescriptors:@[timeSortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (completion && error) {
            completion(nil, error);
            return;
        }
        
        // If quantity isn't in the database, return nil in the completion block.
        HKQuantitySample *quantitySample = results.firstObject;
        HKQuantity *quantity = quantitySample.quantity;
        
        if (completion) completion(quantity, error);
    }];
    
    [self.healthStore executeQuery:query];
}



- (NSNumberFormatter *)numberFormatter {
    static NSNumberFormatter *numberFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        numberFormatter = [[NSNumberFormatter alloc] init];
    });
    
    return numberFormatter;
}


@end
