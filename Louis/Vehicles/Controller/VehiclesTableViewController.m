//
//  VehicleTableViewController.m
//  Louis
//
//  Created by Giang Christian on 25/09/2015.
//  Copyright © 2015 Louis. All rights reserved.
//

#import "VehiclesTableViewController.h"
#import "Common.h"
#import "DataManager+User_Vehicles.h"
#import "Vehicle.h"

#define NB_SECTIONS 1
#define NB_MIN_VEHICLE 1
#define NB_MAX_VEHICLE 5


@interface VehiclesTableViewController ()
{
    NSArray *userVehicles;
    VehicleSetupTableViewController *vehicleSetupViewController;
    BigButtonView *footerView;
    UIAlertController *deleteConfirmationAlert;
}
@end



@implementation VehiclesTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:[NSLocalizedString(@"Vehicles-View-Title", nil) uppercaseString]];
    [[self tableView] setBackgroundColor:[UIColor louisBackgroundApp]];
    
    // ===== Menu Configuration ===== //
    [self configureSWRevealViewControllerForViewController:self
                                            withMenuButton:[self menuButton]];
    
    // ===== Back Button ===== //
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BackButtonItem-Title", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButtonItem];
    
    
    // ===== Data ===== //
    userVehicles = [DataManager userVehicles];
    
    
    // ===== Button "Add a new vehicle" ===== //
    footerView = [BigButtonView bigButtonViewTypeAltWithTitle:NSLocalizedString(@"Vehicles-Button-Title", nil) andImage:[UIImage imageNamed:@"add_icon"]];
    [[footerView button] addTarget:self action:@selector(addVehicleButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    [self showAddButtonIfPossible];
    [[self tableView] setTableFooterView:footerView];
    
    // Notification ajout véhicule
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(vehiclesListUpdated:) name:@"vehiclesListUpdated" object:nil];
}



-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [GAI sendScreenViewWithName:@"Cars"];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[[self tableView] cellForRowAtIndexPath:[[self tableView] indexPathForSelectedRow]] setSelected:NO animated:YES];
}



- (void)showAddButtonIfPossible
{
    [[footerView button] setHidden:!([userVehicles count] < NB_MAX_VEHICLE)];
}



//- (void)vehiculeSetupViewController:(VehicleSetupTableViewController *)viewController addedItem
//{
//    
//}

- (void)vehiclesListUpdated:(NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"vehiclesListUpdated"])
    {
        NSDictionary *infos = [notification userInfo];
        NSString *updateType = [infos valueForKey:@"updateType"];
        
        if ([updateType isEqualToString:@"ADD"])
        {
            [[self tableView] beginUpdates];
            [[self tableView] insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:[userVehicles count] inSection:0]]
                                    withRowAnimation:UITableViewRowAnimationRight];
            userVehicles = [DataManager userVehicles];
            [[self tableView] endUpdates];
        }
        else if ([updateType isEqualToString:@"EDIT"])
        {
            userVehicles = [DataManager userVehicles];
            [[self tableView] reloadData];
        }
        else if ([updateType isEqualToString:@"DELETE"])
        {
            NSInteger deletedRowIndex = [[infos valueForKey:@"modifiedRowIndex"] integerValue];
            [[self tableView] beginUpdates];
            [[self tableView] deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:deletedRowIndex inSection:0]]
                                    withRowAnimation:UITableViewRowAnimationLeft];
            userVehicles = [DataManager userVehicles];
            [[self tableView] endUpdates];
        }
    }
    
    [self showAddButtonIfPossible];
}





#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NB_SECTIONS;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [userVehicles count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"vehicleCell"];

    if ([userVehicles count] > 0)
    {
         Vehicle *vehicleForRow = [userVehicles objectAtIndex:indexPath.row];
        [[cell textLabel] setTextColor:[UIColor louisTitleAndTextColor]];
        [[cell textLabel] setText:[NSString stringWithFormat:@"%@ %@ - %@", [vehicleForRow brand], [vehicleForRow model], [vehicleForRow color]]];
        [[cell detailTextLabel] setTextColor:[UIColor louisLabelColor]];
        [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@",[vehicleForRow numberPlate]]];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
    return cell;
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([userVehicles count] > 1);
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        deleteConfirmationAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Vehicle-Delete-Alert-Title", nil) message:NSLocalizedString(@"Vehicle-Delete-Alert-Message", nil) preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *actionNO = [UIAlertAction actionWithTitle:NSLocalizedString(@"Vehicle-Delete-Alert-Action-No", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
        {
            [tableView setEditing:NO animated:YES];
        }];
    
        UIAlertAction *actionYES = [UIAlertAction actionWithTitle:NSLocalizedString(@"Vehicle-Delete-Alert-Action-Yes", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
        {
            
            
            [DataManager deleteVehicle:[userVehicles objectAtIndex:indexPath.row] withCompletionBlock:
             ^(User *user, NSHTTPURLResponse *httpResponse, NSError *error)
             {
                 if (httpResponse.statusCode != 200)
                 {
                     [HTTPResponseHandler handleHTTPResponse:httpResponse
                                                 withMessage:@""
                                               forController:self
                                              withCompletion:^
                      {
                          nil;
                      }];
                 }
                 else
                 {
                     dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                        [[self tableView] beginUpdates];
                                        [[self tableView] deleteRowsAtIndexPaths:@[indexPath]
                                                                withRowAnimation:UITableViewRowAnimationLeft];
                                        
                                        NSMutableArray *userVehiclesMutable = [userVehicles mutableCopy];
                                        [userVehiclesMutable removeObjectAtIndex:indexPath.row];
                                        userVehicles = [userVehiclesMutable copy];
                                        
                                        [[self tableView] endUpdates];
//                                        [[NSNotificationCenter defaultCenter] postNotificationName:@"vehiclesListUpdated" object:nil userInfo:@{@"updateType":@"DELETE", @"modifiedRowIndex":[NSString stringWithFormat:@"%ld", (long)indexPath.row]}];
                                    });
                 }
                 
             }];
        }];
        
        [deleteConfirmationAlert addAction:actionNO];
        [deleteConfirmationAlert addAction:actionYES];
        
        [self presentViewController:deleteConfirmationAlert animated:YES completion:
         ^{
             [GAI sendScreenViewWithName:@"Delete Car"];
        }];
        deleteConfirmationAlert = nil;
    }
}



-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}



- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] initWithFrame:CGRectZero];
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showSetupViewControllerWithVehicleIndexPath:indexPath];
}



- (void)addVehicleButtonTouched:(UIButton *)sender
{
    [self showSetupViewControllerWithVehicleIndexPath:nil];
}



- (void)showSetupViewControllerWithVehicleIndexPath:(NSIndexPath *)vehicleToEditIndexPath
{
    if (vehicleSetupViewController == nil)
    {
        vehicleSetupViewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"VehicleSetupViewController"];
        [vehicleSetupViewController setDelegate:self];
    }
    
    if (vehicleToEditIndexPath == nil) // Add
    {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vehicleSetupViewController];
        [vehicleSetupViewController setVehicleInEdition:nil];
        [self presentViewController:navController animated:YES completion:^{}];
    }
    else // Edit
    {
        [vehicleSetupViewController setShouldShowDeleteButton:([userVehicles count] > 1)];
        [vehicleSetupViewController setVehicleInEdition:[userVehicles objectAtIndex:vehicleToEditIndexPath.row]];
        [vehicleSetupViewController setVehicleInEditionIndexPath:vehicleToEditIndexPath];
        [[self navigationController] pushViewController:vehicleSetupViewController animated:YES];
    }
}


// Override to support rearranging the table view.
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//    if ( (fromIndexPath.section != toIndexPath.section) && toIndexPath.section == 0)
//    {
//        [tableView beginUpdates];
//        
//        NSIndexPath *previousMainVehicleIndex;
//        
//        if (toIndexPath.row > 0)
//        {
//            previousMainVehicleIndex = [NSIndexPath indexPathForItem:0 inSection:0];
//        }
//        else
//        {
//            previousMainVehicleIndex = [NSIndexPath indexPathForItem:1 inSection:0];
//        }
//        
//        [tableView moveRowAtIndexPath:previousMainVehicleIndex toIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//        [tableView endUpdates];
//    }
//
//    if (toIndexPath == [NSIndexPath indexPathForItem:0 inSection:0] ||
//        toIndexPath == [NSIndexPath indexPathForItem:1 inSection:0])
//    {
//        // On prend le row de l'indexPath +1 car on prend en compte le firstObject qui est dans une autre section
//        NSUInteger indexToMove = fromIndexPath.row+1;
//        
//        NSObject *itemToMove = self.creditCards[indexToMove];
//        NSMutableArray *mutable = [self.creditCards mutableCopy];
//        [mutable removeObjectAtIndex:indexToMove];
//        
//        [mutable insertObject:itemToMove atIndex:0];
//        self.creditCards = [mutable copy];
//        
//        [self.tableView reloadData];
//    }
//}





/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end