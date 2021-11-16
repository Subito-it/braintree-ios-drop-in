// Copyright © 2019 Subito.it. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SBTAddCardButtonFormField;

@protocol SBTAddCardButtonFormFieldDelegate <NSObject>

- (void)addCardFieldTapped:(SBTAddCardButtonFormField *)field;

@end

@interface SBTAddCardButtonFormField : UIView

@property (nonatomic, weak) id<SBTAddCardButtonFormFieldDelegate> delegate;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
