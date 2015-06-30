//
//  SmartPopNavigationController.h
//  NativeiOSBooker
//
//  Created by Danila Parkhomenko on 23/09/14.
//  Copyright (c) 2014 Booker Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SmartPopNavigationController : UINavigationController

- (NSArray *) popViewControllerAnimated:(BOOL) animated completion:(void (^)()) completion tillRoot:(BOOL) tillRoot; // array of controllers in case of popping to root, or one controller array if just single pop
- (UIViewController *) popViewControllerAnimated:(BOOL) animated;
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (SmartPopNavigationController *) deepestSmartPopNavigationController;

@end
