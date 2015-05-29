//
//  SmartPopNavigationController.m
//  NativeiOSBooker
//
//  Created by Danila Parkhomenko on 23/09/14.
//  Copyright (c) 2014 Booker Software. All rights reserved.
//

#import "SmartPopNavigationController.h"

typedef void(^PopCompletionBlock)();

@interface SmartPopNavigationController () <UINavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *completionBlocks;
@property (nonatomic, weak) id<UINavigationControllerDelegate>escalatedDelegate;

@end

@implementation SmartPopNavigationController {
    BOOL completionAwareCall;
}

- (SmartPopNavigationController *) deepestSmartPopNavigationController
{
    for (UIViewController *vc = self.parentViewController; vc; vc = vc.parentViewController) {
        if (vc.navigationController && [vc.navigationController isKindOfClass:[SmartPopNavigationController class]]) {
            return [((SmartPopNavigationController *)vc.navigationController) deepestSmartPopNavigationController];
        }
    }
    return self;
}

- (NSArray *) superPopToRootViewControllerAnimated:(BOOL) animated
{
    return [super popToRootViewControllerAnimated:animated];
}

- (NSArray *) superPopViewControllerAnimated:(BOOL) animated
{
    id res = [super popViewControllerAnimated:animated];
    if (res) {
        return @[res];
    }
    return nil;
}

- (NSArray *) popViewControllerAnimated:(BOOL) animated completion:(void (^)()) completion tillRoot:(BOOL) tillRoot
{
    if (self.delegate) {
        if (![self.delegate isEqual:self]) {
            self.escalatedDelegate = self.delegate;
            self.delegate = self;
        }
    } else {
        self.delegate = self;
    }
    NSDictionary *info;
    if (completion) {
        info = @{@"completion": completion, @"animated": @(animated), @"root": @(tillRoot), @"target": self};
    } else {
        info = @{@"animated": @(animated), @"root": @(tillRoot), @"target": self};
    }
    SmartPopNavigationController *deepest = [self deepestSmartPopNavigationController];
    if (deepest.completionBlocks && (deepest.completionBlocks.count > 0)) {
        [deepest.completionBlocks addObject:info];
        return nil;
    } else {
        if (self.viewControllers.count == 1) {
            if (completion)
                completion();
            return nil;
        }
        deepest.completionBlocks = [NSMutableArray arrayWithObject:info];
        if (tillRoot) {
            return [super popToRootViewControllerAnimated:animated];
        }
        return [self superPopViewControllerAnimated:animated];
    }
}

- (UIViewController *) popViewControllerAnimated:(BOOL)animated
{
    return [[self popViewControllerAnimated:animated completion:nil tillRoot:NO] firstObject];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
    return [self popViewControllerAnimated:animated completion:nil tillRoot:YES];
}

#pragma mark - UINavigationControllerDelegate methods

- (void) navigationController:(UINavigationController *) navigationController didShowViewController:(UIViewController *) viewController animated:(BOOL) animated
{
    SmartPopNavigationController *deepest = [self deepestSmartPopNavigationController];
    NSDictionary *info = [deepest.completionBlocks firstObject];
    PopCompletionBlock completion = info[@"completion"];
    if (completion) {
        completion();
    }
    if (self.escalatedDelegate && [self.escalatedDelegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.escalatedDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
    if (info) {
        [deepest.completionBlocks removeObjectAtIndex:0];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (deepest.completionBlocks.count > 0) {
            NSDictionary *info = [deepest.completionBlocks firstObject]; // next object in the queue
            SmartPopNavigationController *target = info[@"target"];
            if (target.viewControllers.count == 1) { // next VC have popped already to the last VC
                PopCompletionBlock completion = info[@"completion"];
                if (completion) {
                    completion();
                }
                [deepest.completionBlocks removeObjectAtIndex:0];
                for (NSInteger i = 0; i < deepest.completionBlocks.count;) {
                    info = deepest.completionBlocks[i];
                    if ([info[@"target"] isEqual:target]) {
                        completion = info[@"completion"];
                        if (completion) {
                            completion();
                        }
                        [deepest.completionBlocks removeObjectAtIndex:i];
                    } else
                        i++;
                }
            } else {
                BOOL animated = [info[@"animated"] boolValue];
                if ([info[@"root"] boolValue]) {
                    [target superPopToRootViewControllerAnimated:animated];
                } else {
                    [target superPopViewControllerAnimated:animated];
                }
            }
        }
    });
}

- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.escalatedDelegate && [self.escalatedDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)]) {
        [self.escalatedDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }
}

//- (NSUInteger)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
//{}
//
//- (UIInterfaceOrientation)navigationControllerPreferredInterfaceOrientationForPresentation:(UINavigationController *)navigationController
//{}
//
//- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
//                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController
//{}
//
//- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
//                                   animationControllerForOperation:(UINavigationControllerOperation)operation
//                                                fromViewController:(UIViewController *)fromVC
//                                                  toViewController:(UIViewController *)toVC
//{}

@end
