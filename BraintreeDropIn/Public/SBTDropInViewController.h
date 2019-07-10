// Copyright © 2019 Subito.it. All rights reserved.

#import <UIKit/UIKit.h>

#import "BTDropInController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SBTDropInViewController : UIViewController

- (nullable instancetype)initWithAuthorization:(NSString *)authorization request:(BTDropInRequest *)request handler:(BTDropInControllerHandler) handler;

@end

NS_ASSUME_NONNULL_END
