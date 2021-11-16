// Copyright © 2019 Subito.it. All rights reserved.

#import "SBTAddCardButtonFormField.h"
#import "BTDropInLocalization_Internal.h"
#import "BTUIKAppearance.h"

@interface UIImage (Color)

+ (UIImage *)sbt_resizableImageWithColor:(UIColor *)color cornerRadius:(CGFloat)radius;

@end

@implementation UIImage (Color)

+ (UIImage *)sbt_resizableImageWithColor:(UIColor *)color cornerRadius:(CGFloat)radius {
    CGSize size = CGSizeMake((radius * 2.0) + 1.0, (radius * 2.0) + 1.0);
    CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
    
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGContextRef contextRef = context.CGContext;
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        CGContextAddPath(contextRef, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
        CGContextFillPath(contextRef);
    }];
    
    UIEdgeInsets capInsets = UIEdgeInsetsMake(radius, radius, radius, radius);
    return [image resizableImageWithCapInsets:capInsets];
}

@end

@interface SBTAddCardButtonFormField ()

@property (nonatomic, strong) UIButton *addButton;

@end

@implementation SBTAddCardButtonFormField

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImage *normalImage = [UIImage sbt_resizableImageWithColor:BTUIKAppearance.sharedInstance.tintColor cornerRadius:4.0];
        UIImage *disabledImage = [UIImage sbt_resizableImageWithColor:BTUIKAppearance.sharedInstance.disabledColor cornerRadius:4.0];
        UIImage *highlightedImage = [UIImage sbt_resizableImageWithColor:BTUIKAppearance.sharedInstance.highlightedTintColor cornerRadius:4.0];
        
        _addButton = [UIButton new];
        _addButton.translatesAutoresizingMaskIntoConstraints = NO;
        _addButton.titleLabel.font = [BTUIKAppearance.sharedInstance.headlineFont fontWithSize:UIFont.labelFontSize];
        [_addButton setBackgroundImage:normalImage forState:UIControlStateNormal];
        [_addButton setBackgroundImage:disabledImage forState:UIControlStateDisabled];
        [_addButton setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
        [_addButton setTitle:BTDropInLocalizedString(ADD_CARD_ACTION) forState:UIControlStateNormal];
        [_addButton addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_addButton];
        
        NSLayoutConstraint *heightConstraint = [_addButton.heightAnchor constraintEqualToConstant:44.0];
        heightConstraint.priority = UILayoutPriorityDefaultHigh;
        
        [NSLayoutConstraint activateConstraints:@[
            heightConstraint,
            [_addButton.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_addButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_addButton.leadingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.leadingAnchor],
            [_addButton.trailingAnchor constraintEqualToAnchor:self.layoutMarginsGuide.trailingAnchor]
        ]];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    [self.addButton setEnabled:enabled];
}

- (void)tapped {
    [self.delegate addCardFieldTapped:self];
}

@end

